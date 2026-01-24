package com.example.pushlock

import android.app.*
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.pushlock.data.local.LockedAppDatabase
import com.example.pushlock.data.repo.LockedAppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


class AppLockService : Service() {

    private lateinit var detector: ForegroundAppDetector
    private lateinit var overlayUi: OverlayUi
    private val handler = Handler(Looper.getMainLooper())

    // Timeout tracking variables
    private lateinit var lockedAppRepo: LockedAppRepo
    private val serviceScope = CoroutineScope(Dispatchers.Main)
    
    // Map to track: packageName -> timestamp when app was opened
    private val appOpenTimestamps = mutableMapOf<String, Long>()
    
    // Map to track: packageName -> Handler for the timeout
    private val timeoutHandlers = mutableMapOf<String, Handler>()
    
    // Map to track: packageName -> Runnable for the timeout
    private val timeoutRunnables = mutableMapOf<String, Runnable>()
    
    // Track the last detected foreground app to detect app switches
    private var lastForegroundApp: String? = null

    override fun onCreate() {
        super.onCreate()
        LockRepository.lockApp(this, "com.instagram.android")
        
        detector = ForegroundAppDetector(this)
        overlayUi = OverlayUi(this)
        
        // Initialize Room database and repository
        val database = LockedAppDatabase.getDatabase(this)
        lockedAppRepo = LockedAppRepo(database.lockedAppDao())
        
        startForegroundService()
        startMonitoring()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startMonitoring() {
        handler.post(object : Runnable {
            override fun run() {
                val foregroundApp = detector.getForegroundApp()
                
                // Check if app changed (compare with lastForegroundApp)
                if (foregroundApp != lastForegroundApp) {
                    Log.d("APP_LOCK", "App changed: $lastForegroundApp -> $foregroundApp")
                    
                    // Cancel timer for old app
                    lastForegroundApp?.let { cancelTimeoutTimer(it) }
                    
                    // Check if new app is locked
                    if (foregroundApp != null) {
                        serviceScope.launch {
                            val lockedApp = lockedAppRepo.getLockedApp(foregroundApp)
                            
                            if (lockedApp != null) {
                                // Get timeout value
                                val timeoutSeconds = lockedApp.timeoutSecond
                                Log.d("APP_LOCK", "Locked app detected: $foregroundApp, timeout: ${timeoutSeconds}s")
                                
                                // Start timer
                                startTimeoutTimer(foregroundApp, timeoutSeconds)
                            } else {
                                // Not locked, remove overlay if showing
                                overlayUi.removeOverlay()
                            }
                        }
                    } else {
                        // No app in foreground
                        overlayUi.removeOverlay()
                    }
                    
                    // Update last app
                    lastForegroundApp = foregroundApp
                }
                
                // Poll every 500ms for better accuracy
                handler.postDelayed(this, 500)
            }
        })
    }

    private fun startTimeoutTimer(packageName: String, timeoutSeconds: Int) {
        // Cancel existing timer if any
        cancelTimeoutTimer(packageName)
        
        // Record when app was opened
        appOpenTimestamps[packageName] = System.currentTimeMillis()
        
        // Create new handler and runnable
        val timeoutHandler = Handler(Looper.getMainLooper())
        val timeoutRunnable = Runnable {
            Log.d("APP_LOCK", "Timeout reached for $packageName")
            overlayUi.showOverlay()
            
            // Remove from tracking maps
            appOpenTimestamps.remove(packageName)
            timeoutHandlers.remove(packageName)
            timeoutRunnables.remove(packageName)
        }
        
        // Start the timer
        timeoutHandler.postDelayed(timeoutRunnable, timeoutSeconds * 1000L)
        
        // Store in maps
        timeoutHandlers[packageName] = timeoutHandler
        timeoutRunnables[packageName] = timeoutRunnable
        
        Log.d("APP_LOCK", "Started timer for $packageName with ${timeoutSeconds}s timeout")
    }

    private fun cancelTimeoutTimer(packageName: String) {
        timeoutHandlers[packageName]?.let { handler ->
            timeoutRunnables[packageName]?.let { runnable ->
                handler.removeCallbacks(runnable)
                Log.d("APP_LOCK", "Cancelled timer for $packageName")
            }
        }
        
        // Clean up
        appOpenTimestamps.remove(packageName)
        timeoutHandlers.remove(packageName)
        timeoutRunnables.remove(packageName)
    }

    private fun cancelAllTimers() {
        timeoutHandlers.keys.toList().forEach { packageName ->
            cancelTimeoutTimer(packageName)
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
    
    override fun onDestroy() {
        super.onDestroy()
        cancelAllTimers()
        handler.removeCallbacksAndMessages(null)
        overlayUi.removeOverlay()
    }
}
