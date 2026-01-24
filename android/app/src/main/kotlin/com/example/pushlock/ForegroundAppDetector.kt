package com.example.pushlock;

import android.app.usage.UsageEvents // used to read app usage events like app being in background, foreground...
import android.app.usage.UsageStatsManager // the main manager that let us access uage data, usage event
import android.content.Context
import android.os.Build // Build provides information about the Android OS version running on the device.


class ForegroundAppDetector(private val context: Context) {
    private var lastKnownApp: String? = null

    fun getForegroundApp(): String? {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager;

        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 10

        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()


        var currentApp: String? = null

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)

            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                currentApp = event.packageName
            }
        }

        if(currentApp != null){
            lastKnownApp = currentApp
        }

        return currentApp ?: lastKnownApp
    }
    
}

