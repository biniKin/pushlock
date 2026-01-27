package com.example.pushlock

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.pushlock.data.local.PushLockDatabase
import com.example.pushlock.data.repo.LockedAppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


class AppLockService : Service() {

    private var detector: ForegroundAppDetector? = null
    private var overlayUi: OverlayUi? = null
    private val handler = Handler(Looper.getMainLooper())

    // Timeout tracking variables
    private var lockedAppRepo: LockedAppRepo? = null
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
            // Removed hardcoded Instagram lock - use UI to add locked apps
            // LockRepository.lockApp(this, "com.instagram.android")
            Log.d("APP_LOCK", "LockedAppRepo initialized")
            println("APP_LOCK: LockedAppRepo initialized")
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
                    
                    // Check if new app is locked
                    if (foregroundApp != null) {
                        serviceScope.launch {
                            val currentRepo = lockedAppRepo
                            if (currentRepo == null) {
                                Log.e("APP_LOCK", "LockedAppRepo is null")
                                println("APP_LOCK ERROR: LockedAppRepo is null")
                                return@launch
                            }
                            
                            val lockedApp = currentRepo.getLockedApp(foregroundApp)
                            
                            if (lockedApp != null) {
                                println("APP_LOCK: Found locked app: $foregroundApp")
                                // Check if app is already locked (overlay showing)
                                if (storage.isLocked(foregroundApp)) {
                                    Log.d("APP_LOCK", "App $foregroundApp is locked, showing overlay")
                                    println("APP_LOCK: App $foregroundApp is ALREADY LOCKED, showing overlay")
                                    overlayUi?.showOverlay()
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
                                        overlayUi?.showOverlay()
                                        Log.d("APP_LOCK", "Time's up for $foregroundApp, showing overlay")
                                        println("========== APP_LOCK: TIME'S UP! Showing overlay ==========")
                                    } else {
                                        // Start tracking time
                                        appLastOpenTime[foregroundApp] = System.currentTimeMillis()
                                        storage.saveLastTimestamp(foregroundApp, System.currentTimeMillis())
                                        println("APP_LOCK: Started tracking time for $foregroundApp")
                                    }
                                }
                            } else {
                                println("APP_LOCK: App $foregroundApp is NOT locked")
                                // Not locked, remove overlay if showing
                                overlayUi?.removeOverlay()
                            }
                        }
                    } else {
                        // No app in foreground
                        overlayUi?.removeOverlay()
                    }
                    
                    // Update last app
                    lastForegroundApp = foregroundApp
                } else {
                    // Same app, check if we need to update accumulated time
                    foregroundApp?.let { app ->
                        serviceScope.launch {
                            val currentRepo = lockedAppRepo
                            val currentStorage = timerStorage
                            if (currentRepo == null || currentStorage == null) return@launch
                            
                            val lockedApp = currentRepo.getLockedApp(app)
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
                                        overlayUi?.showOverlay()
                                        appLastOpenTime.remove(app)
                                        Log.d("APP_LOCK", "Timeout reached for $app, showing overlay")
                                        println("========== APP_LOCK: TIMEOUT REACHED! Total: ${totalAccumulated}s, showing overlay ==========")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Poll every 500ms for better accuracy
                handler.postDelayed(this, 500)
            }
        })
    }
    
    private fun saveAccumulatedTime(packageName: String) {
        val storage = timerStorage ?: return
        val lastOpenTime = appLastOpenTime[packageName] ?: return
        
        // Don't accumulate if already locked
        if (storage.isLocked(packageName)) {
            appLastOpenTime.remove(packageName)
            println("APP_LOCK: Not saving time for $packageName - already locked")
            return
        }
        
        val elapsedSeconds = ((System.currentTimeMillis() - lastOpenTime) / 1000).toInt()
        val previousAccumulated = storage.getAccumulatedSeconds(packageName)
        val newAccumulated = previousAccumulated + elapsedSeconds
        
        storage.saveAccumulatedSeconds(packageName, newAccumulated)
        appLastOpenTime.remove(packageName)
        
        Log.d("APP_LOCK", "Saved accumulated time for $packageName: ${newAccumulated}s (added ${elapsedSeconds}s)")
        println("========== APP_LOCK: Saved accumulated time ==========")
        println("APP_LOCK: Package: $packageName")
        println("APP_LOCK: Previous: ${previousAccumulated}s")
        println("APP_LOCK: Elapsed: ${elapsedSeconds}s")
        println("APP_LOCK: New Total: ${newAccumulated}s")
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
