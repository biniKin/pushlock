package com.example.pushlock

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.pushlock.data.local.AppStatEntity
import com.example.pushlock.data.local.PushLockDatabase
import com.example.pushlock.data.repo.AppStatRepo
import com.example.pushlock.data.repo.LockedAppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*


class AppLockService : Service() {

    private var detector: ForegroundAppDetector? = null
    private var overlayUi: OverlayUi? = null
    private val handler = Handler(Looper.getMainLooper())

    // Timeout tracking variables
    private var lockedAppRepo: LockedAppRepo? = null
    private var appStatRepo: AppStatRepo? = null
    private var timerStorage: TimerStorage? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main)
    
    // Map to track: packageName -> timestamp when app was last opened/resumed
    private val appLastOpenTime = mutableMapOf<String, Long>()
    
    // Track the last detected foreground app to detect app switches
    private var lastForegroundApp: String? = null
    
    // Flag to track if monitoring is already started
    private var isMonitoring = false
    
    // Flag to track if receiver is registered
    private var isReceiverRegistered = false
    
    // Track last backup save time
    private var lastBackupSaveTime = 0L
    private val BACKUP_SAVE_INTERVAL = 30000L // 30 seconds
    
    // SharedPreferences for persisting tracking state
    private val prefs by lazy {
        getSharedPreferences("app_lock_tracking", Context.MODE_PRIVATE)
    }
    
    companion object {
        private const val PREF_LAST_FOREGROUND_APP = "last_foreground_app"
        private const val PREF_LAST_OPEN_TIME = "last_open_time"
    }
    
    // Save current tracking state to SharedPreferences
    private fun saveTrackingState() {
        val currentApp = lastForegroundApp ?: return
        val openTime = appLastOpenTime[currentApp] ?: return
        
        prefs.edit().apply {
            putString(PREF_LAST_FOREGROUND_APP, currentApp)
            putLong(PREF_LAST_OPEN_TIME, openTime)
            apply()
        }
        
        Log.d("APP_LOCK", "Saved tracking state: app=$currentApp, time=$openTime")
        println("========== APP_LOCK: Saved tracking state to SharedPreferences ==========")
    }
    
    // Restore tracking state from SharedPreferences
    private fun restoreTrackingState() {
        val savedApp = prefs.getString(PREF_LAST_FOREGROUND_APP, null)
        val savedTime = prefs.getLong(PREF_LAST_OPEN_TIME, 0L)
        
        if (savedApp != null && savedTime > 0L) {
            // Check if saved app is still in foreground
            val currentForegroundApp = detector?.getForegroundApp()
            
            if (currentForegroundApp == savedApp) {
                // Same app still in foreground, restore tracking
                lastForegroundApp = savedApp
                appLastOpenTime[savedApp] = savedTime
                Log.d("APP_LOCK", "Restored tracking state: app=$savedApp, time=$savedTime")
                println("========== APP_LOCK: Restored tracking state - app still in foreground ==========")
            } else {
                // Different app now, save the time for the old app
                val elapsedSeconds = ((System.currentTimeMillis() - savedTime) / 1000).toInt()
                if (elapsedSeconds > 0) {
                    saveUsageTimeToDatabase(savedApp, elapsedSeconds)
                    Log.d("APP_LOCK", "Saved missed time for $savedApp: ${elapsedSeconds}s")
                    println("========== APP_LOCK: Saved missed time during service restart ==========")
                }
                
                // Start tracking the current foreground app
                if (currentForegroundApp != null) {
                    lastForegroundApp = currentForegroundApp
                    appLastOpenTime[currentForegroundApp] = System.currentTimeMillis()
                    Log.d("APP_LOCK", "Started tracking new foreground app: $currentForegroundApp")
                    println("========== APP_LOCK: Started tracking current foreground app after restart ==========")
                }
            }
            
            // Clear saved state
            prefs.edit().clear().apply()
        } else {
            // No saved state, start tracking current foreground app
            val currentForegroundApp = detector?.getForegroundApp()
            if (currentForegroundApp != null) {
                lastForegroundApp = currentForegroundApp
                appLastOpenTime[currentForegroundApp] = System.currentTimeMillis()
                Log.d("APP_LOCK", "No saved state, started tracking current app: $currentForegroundApp")
                println("========== APP_LOCK: No saved state - started tracking current foreground app ==========")
            }
        }
    }
    
    // Helper method to save usage time to database
    private fun saveUsageTimeToDatabase(packageName: String, elapsedSeconds: Int) {
        val repo = appStatRepo ?: return
        val storage = timerStorage ?: return
        val date = getTodayDate()
        
        // Update accumulated time for locked apps
        if (!storage.isLocked(packageName)) {
            val previousAccumulated = storage.getAccumulatedSeconds(packageName)
            val newAccumulated = previousAccumulated + elapsedSeconds
            storage.saveAccumulatedSeconds(packageName, newAccumulated)
            Log.d("APP_LOCK", "Updated accumulated time for $packageName: ${newAccumulated}s")
        }
        
        // Save to database
        serviceScope.launch(Dispatchers.IO) {
            try {
                val existing = repo.appStatForDay(packageName, date)
                
                if (existing == null) {
                    repo.upsert(
                        AppStatEntity(
                            packageName = packageName,
                            appName = getAppName(packageName),
                            date = date,
                            dailyUsageTime = elapsedSeconds.toLong()
                        )
                    )
                } else {
                    repo.upsert(
                        existing.copy(
                            dailyUsageTime = existing.dailyUsageTime + elapsedSeconds
                        )
                    )
                }
                Log.d("APP_LOCK", "Saved usage time to database: $packageName, ${elapsedSeconds}s")
            } catch (e: Exception) {
                Log.e("APP_LOCK", "Error saving usage time: ${e.message}")
            }
        }
    }
    
    // BroadcastReceiver to handle unlock commands
    private val unlockReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d("APP_LOCK", "Broadcast received: ${intent?.action}")
            println("========== APP_LOCK: Broadcast received: ${intent?.action} ==========")
            
            if (intent?.action == "com.example.pushlock.UNLOCK_APP") {
                val packageName = intent.getStringExtra("packageName")
                Log.d("APP_LOCK", "Unlock request for: $packageName")
                println("========== APP_LOCK: Unlock request for: $packageName ==========")
                
                if (packageName != null) {
                    unlockApp(packageName)
                } else {
                    Log.e("APP_LOCK", "Package name is null in unlock broadcast")
                    println("APP_LOCK ERROR: Package name is null")
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("APP_LOCK", "onCreate called")
        println("========== APP_LOCK: Service onCreate ==========")
        
        // Register broadcast receiver for unlock commands (only once)
        if (!isReceiverRegistered) {
            try {
                val filter = IntentFilter("com.example.pushlock.UNLOCK_APP")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(unlockReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                } else {
                    registerReceiver(unlockReceiver, filter)
                }
                isReceiverRegistered = true
                Log.d("APP_LOCK", "Broadcast receiver registered successfully")
                println("========== APP_LOCK: Broadcast receiver registered ==========")
            } catch (e: Exception) {
                Log.e("APP_LOCK", "Failed to register broadcast receiver: ${e.message}")
                println("APP_LOCK ERROR: Failed to register receiver: ${e.message}")
            }
        } else {
            Log.d("APP_LOCK", "Broadcast receiver already registered")
            println("========== APP_LOCK: Receiver already registered ==========")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("APP_LOCK", "onStartCommand called")
        
        // Start foreground service first (must be done within 5 seconds)
        startForegroundService()
        
        // Initialize if not already initialized
        initializeService()
        
        // Start monitoring if not already monitoring
        if (!isMonitoring) {
            startMonitoring()
            isMonitoring = true
        }
        
        return START_STICKY // Service will be restarted if killed by system
    }

    override fun onTaskRemoved(intent: Intent?) {
        super.onTaskRemoved(intent)
        Log.d("APP_LOCK", "Task removed, restarting service")
        
        // Save tracking state before service is killed
        saveTrackingState()
        
        // Restart the service when app is swiped away
        val restartIntent = Intent(applicationContext, AppLockService::class.java)
        val pendingIntent = PendingIntent.getService(
            applicationContext,
            1,
            restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + 1000,
            pendingIntent
        )
    }

    private fun initializeService() {
        Log.d("APP_LOCK", "Initializing service")
        println("========== APP_LOCK: Initializing service ==========")
        
        var shouldRestoreState = false
        
        // Initialize only if not already initialized
        if (detector == null) {
            detector = ForegroundAppDetector(this)
            Log.d("APP_LOCK", "ForegroundAppDetector initialized")
            println("APP_LOCK: ForegroundAppDetector initialized")
        }
        
        if (overlayUi == null) {
            overlayUi = OverlayUi(this)
            Log.d("APP_LOCK", "OverlayUi initialized")
            println("APP_LOCK: OverlayUi initialized")
        }
        
        if (timerStorage == null) {
            timerStorage = TimerStorage(this)
            Log.d("APP_LOCK", "TimerStorage initialized")
            println("APP_LOCK: TimerStorage initialized")
        }
        
        if (lockedAppRepo == null) {
            val database = PushLockDatabase.getDatabase(this)
            lockedAppRepo = LockedAppRepo(database.lockedAppDao())
            appStatRepo = AppStatRepo(database.appStatDao())
            // Removed hardcoded Instagram lock - use UI to add locked apps
            // LockRepository.lockApp(this, "com.instagram.android")
            Log.d("APP_LOCK", "LockedAppRepo initialized")
            println("APP_LOCK: LockedAppRepo initialized")
            shouldRestoreState = true
        }
        
        // ALWAYS restore tracking state if we have no current tracking
        if (shouldRestoreState || (lastForegroundApp == null && appLastOpenTime.isEmpty())) {
            Log.d("APP_LOCK", "Restoring tracking state (shouldRestore=$shouldRestoreState, lastApp=$lastForegroundApp, mapSize=${appLastOpenTime.size})")
            println("========== APP_LOCK: Attempting to restore tracking state ==========")
            restoreTrackingState()
        }
    }

    private fun startMonitoring() {
        Log.d("APP_LOCK", "Starting monitoring")
        println("========== APP_LOCK: Starting monitoring ==========")
        handler.post(object : Runnable {
            override fun run() {
                // Safety check - ensure detector is initialized
                val currentDetector = detector
                val storage = timerStorage
                if (currentDetector == null || storage == null) {
                    Log.e("APP_LOCK", "Detector or storage is null, skipping monitoring cycle")
                    println("APP_LOCK ERROR: Detector or storage is null")
                    handler.postDelayed(this, 500)
                    return
                }
                
                val foregroundApp = currentDetector.getForegroundApp()
                
                // Check if app changed (compare with lastForegroundApp)
                if (foregroundApp != lastForegroundApp) {
                    Log.d("APP_LOCK", "App changed: $lastForegroundApp -> $foregroundApp")
                    println("========== APP_LOCK: App changed: $lastForegroundApp -> $foregroundApp ==========")
                    
                    // Save accumulated time for old app
                    lastForegroundApp?.let { oldApp ->
                        saveAccumulatedTime(oldApp)
                    }
                    
                    // Start tracking time for the new app (ALL apps, not just locked ones)
                    if (foregroundApp != null) {
                        // Start tracking time for ALL apps
                        appLastOpenTime[foregroundApp] = System.currentTimeMillis()
                        lastForegroundApp = foregroundApp
                        
                        // Save tracking state immediately on app switch
                        saveTrackingState()
                        println("APP_LOCK: Saved state immediately after app switch")
                        
                        println("APP_LOCK: Started tracking time for $foregroundApp")
                        
                        serviceScope.launch {
                            val currentRepo = lockedAppRepo
                            if (currentRepo == null) {
                                Log.e("APP_LOCK", "LockedAppRepo is null")
                                println("APP_LOCK ERROR: LockedAppRepo is null")
                                return@launch
                            }
                            
                            val lockedApp = currentRepo.getLockedApp(foregroundApp)
                            val name = getAppName(foregroundApp)
                            
                            if (lockedApp != null) {
                                println("APP_LOCK: Found locked app: $foregroundApp")
                                // Check if app is already locked (overlay showing)
                                if (storage.isLocked(foregroundApp)) {
                                    Log.d("APP_LOCK", "App $foregroundApp is locked, showing overlay")
                                    println("APP_LOCK: App $foregroundApp is ALREADY LOCKED, showing overlay")
                                    overlayUi?.showOverlay(foregroundApp, name)
                                } else {
                                    // Get accumulated time and timeout
                                    val accumulatedSeconds = storage.getAccumulatedSeconds(foregroundApp)
                                    val timeoutSeconds = lockedApp.timeoutSecond
                                    val remainingSeconds = timeoutSeconds - accumulatedSeconds
                                    
                                    Log.d("APP_LOCK", "Locked app detected: $foregroundApp, accumulated: ${accumulatedSeconds}s, timeout: ${timeoutSeconds}s, remaining: ${remainingSeconds}s")
                                    println("========== APP_LOCK: Locked app detected ==========")
                                    println("APP_LOCK: Package: $foregroundApp")
                                    println("APP_LOCK: Accumulated: ${accumulatedSeconds}s")
                                    println("APP_LOCK: Timeout: ${timeoutSeconds}s")
                                    println("APP_LOCK: Remaining: ${remainingSeconds}s")
                                    
                                    if (remainingSeconds <= 0) {
                                        // Time's up, lock the app
                                        storage.setLocked(foregroundApp, true)
                                        overlayUi?.showOverlay(foregroundApp, name)
                                        Log.d("APP_LOCK", "Time's up for $foregroundApp, showing overlay")
                                        println("========== APP_LOCK: TIME'S UP! Showing overlay ==========")
                                    } else {
                                        // Update timestamp for locked app tracking
                                        storage.saveLastTimestamp(foregroundApp, System.currentTimeMillis())
                                        println("APP_LOCK: Tracking locked app time for $foregroundApp")
                                    }
                                }
                            } else {
                                println("APP_LOCK: App $foregroundApp is NOT locked - tracking usage only")
                                // Not locked, remove overlay if showing
                                overlayUi?.removeOverlay()
                            }
                        }
                    } else {
                        // No app in foreground
                        overlayUi?.removeOverlay()
                        lastForegroundApp = null
                    }
                } else {
                    // Same app, check if we need to update accumulated time
                    foregroundApp?.let { app ->
                        serviceScope.launch {
                            val currentRepo = lockedAppRepo
                            val currentStorage = timerStorage
                            if (currentRepo == null || currentStorage == null) return@launch
                            
                            val lockedApp = currentRepo.getLockedApp(app)
                            val name = getAppName(app)
                            if (lockedApp != null && !currentStorage.isLocked(app)) {
                                // Check if timeout reached
                                val lastOpenTime = appLastOpenTime[app]
                                if (lastOpenTime != null) {
                                    val elapsedSeconds = ((System.currentTimeMillis() - lastOpenTime) / 1000).toInt()
                                    val previousAccumulated = currentStorage.getAccumulatedSeconds(app)
                                    val totalAccumulated = previousAccumulated + elapsedSeconds
                                    val timeoutSeconds = lockedApp.timeoutSecond
                                    
                                    println("APP_LOCK: Checking timeout - elapsed: ${elapsedSeconds}s, previous: ${previousAccumulated}s, total: ${totalAccumulated}s, timeout: ${timeoutSeconds}s")
                                    
                                    if (totalAccumulated >= timeoutSeconds) {
                                        // Time's up
                                        currentStorage.saveAccumulatedSeconds(app, timeoutSeconds)
                                        currentStorage.setLocked(app, true)
                                        overlayUi?.showOverlay(app, name)
                                        appLastOpenTime.remove(app)
                                        Log.d("APP_LOCK", "Timeout reached for $app, showing overlay")
                                        println("========== APP_LOCK: TIMEOUT REACHED! Total: ${totalAccumulated}s, showing overlay ==========")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Periodic backup save (every 30 seconds)
                val currentTime = System.currentTimeMillis()
                if (currentTime - lastBackupSaveTime >= BACKUP_SAVE_INTERVAL) {
                    saveTrackingState()
                    lastBackupSaveTime = currentTime
                }
                
                // Poll every 500ms for better accuracy
                handler.postDelayed(this, 500)
            }
        })
    }
    
    private fun saveAccumulatedTime(packageName: String) {
        val storage = timerStorage ?: return
        val repo = appStatRepo ?: return
        val lastOpenTime = appLastOpenTime[packageName] ?: return
        
        // Calculate elapsed time
        val elapsedSeconds = ((System.currentTimeMillis() - lastOpenTime) / 1000).toInt()
        
        // Skip if no time elapsed
        if (elapsedSeconds <= 0) {
            appLastOpenTime.remove(packageName)
            return
        }
        
        // For locked apps: update accumulated time in TimerStorage
        // Don't accumulate if already locked (overlay showing)
        if (!storage.isLocked(packageName)) {
            val previousAccumulated = storage.getAccumulatedSeconds(packageName)
            val newAccumulated = previousAccumulated + elapsedSeconds
            storage.saveAccumulatedSeconds(packageName, newAccumulated)
            
            Log.d("APP_LOCK", "Updated accumulated time for $packageName: ${newAccumulated}s (added ${elapsedSeconds}s)")
            println("APP_LOCK: Updated accumulated time for $packageName: ${newAccumulated}s")
        }

        // For ALL apps: save usage time to app_stat database
        val date = getTodayDate()
        
        serviceScope.launch(Dispatchers.IO) {
            try {
                val existing = repo.appStatForDay(packageName, date)
                
                if (existing == null) {
                    // Create new entry
                    repo.upsert(
                        AppStatEntity(
                            packageName = packageName,
                            appName = getAppName(packageName),
                            date = date,
                            dailyUsageTime = elapsedSeconds.toLong()
                        )
                    )
                    Log.d("APP_LOCK", "Created new app stat for $packageName: ${elapsedSeconds}s on $date")
                } else {
                    // Update existing entry
                    repo.upsert(
                        existing.copy(
                            dailyUsageTime = existing.dailyUsageTime + elapsedSeconds
                        )
                    )
                    Log.d("APP_LOCK", "Updated app stat for $packageName: +${elapsedSeconds}s (total: ${existing.dailyUsageTime + elapsedSeconds}s) on $date")
                }
                
                println("========== APP_LOCK: Saved usage stat to database ==========")
                println("APP_LOCK: Package: $packageName")
                println("APP_LOCK: Elapsed: ${elapsedSeconds}s")
                println("APP_LOCK: Date: $date")
            } catch (e: Exception) {
                Log.e("APP_LOCK", "Error saving app stat: ${e.message}")
                println("APP_LOCK ERROR: Failed to save stat - ${e.message}")
            }
        }
        
        appLastOpenTime.remove(packageName)
    }
    
    private fun getTodayDate(): String {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return dateFormat.format(Date())
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = applicationContext.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName // Fallback to package name if app name can't be retrieved
        }
    }

    private fun startForegroundService() {
        val channelId = "APP_LOCK_CHANNEL"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "App Lock Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("PushLock is running")
            .setContentText("Monitoring apps for security")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()

        startForeground(1, notification)
    }
    
    // Method to unlock an app (called from Flutter via method channel)
    fun unlockApp(packageName: String) {
        Log.d("APP_LOCK", "Unlocking app: $packageName")
        println("========== APP_LOCK: UNLOCKING APP: $packageName ==========")
        
        val storage = timerStorage
        if (storage == null) {
            Log.e("APP_LOCK", "TimerStorage is null, cannot unlock")
            println("APP_LOCK ERROR: TimerStorage is null")
            return
        }
        
        // Reset timer and unlock state
        storage.resetTimer(packageName)
        appLastOpenTime.remove(packageName)
        
        // Remove overlay
        overlayUi?.removeOverlay()
        
        Log.d("APP_LOCK", "App $packageName unlocked successfully, timer reset")
        println("========== APP_LOCK: App unlocked successfully, timer reset ==========")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d("APP_LOCK", "onDestroy called")
        
        // Save tracking state before service is destroyed
        saveTrackingState()
        
        // Unregister broadcast receiver
        if (isReceiverRegistered) {
            try {
                unregisterReceiver(unlockReceiver)
                isReceiverRegistered = false
                Log.d("APP_LOCK", "Broadcast receiver unregistered")
            } catch (e: Exception) {
                Log.e("APP_LOCK", "Error unregistering receiver: ${e.message}")
            }
        }
        
        // Save accumulated time for current app before destroying
        lastForegroundApp?.let { saveAccumulatedTime(it) }
        
        isMonitoring = false
        handler.removeCallbacksAndMessages(null)
        overlayUi?.removeOverlay()
        
        // Don't set to null - let them be garbage collected
        // This prevents issues if service is restarted quickly
    }
}
