package com.example.pushlock

import android.app.*
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat


class AppLockService : Service() {

    private lateinit var detector: ForegroundAppDetector
    private lateinit var overlayUi: OverlayUi
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        LockRepository.lockApp(this, "com.instagram.android")
        
        detector = ForegroundAppDetector(this)
        overlayUi = OverlayUi(this)
        startForegroundService()
        startMonitoring()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startMonitoring() {
        handler.post(object : Runnable {
            override fun run() {
                val foregroundApp = detector.getForegroundApp()
                Log.d("APP_LOCK", "Foreground app: $foregroundApp")
                
                // Later: check if app is locked and show overlay
                if (foregroundApp != null) {
                    if (LockRepository.isLocked(this@AppLockService, foregroundApp)) {
                        Log.d("APP_LOCK", "LOCK THIS APP: $foregroundApp")
                        // showOverlay()
                        overlayUi.showOverlay()
                    }else{
                        
                        overlayUi.removeOverlay()
                    
                    }
                } else{
                    overlayUi.removeOverlay()
                }

                handler.postDelayed(this, 1000) // every 1 second
            }
        })
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
}