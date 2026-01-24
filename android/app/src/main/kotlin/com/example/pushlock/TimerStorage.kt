package com.example.pushlock

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

class TimerStorage(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("app_lock_timers", Context.MODE_PRIVATE)
    
    init {
        println("!!!!!!!!!! TimerStorage CREATED !!!!!!!!!!")
        Log.d("APP_LOCK", "TimerStorage CREATED")
    }
    
    companion object {
        private const val PREFIX_ACCUMULATED = "accumulated_"
        private const val PREFIX_LOCKED = "locked_"
        private const val PREFIX_LAST_TIMESTAMP = "timestamp_"
    }
    
    // Get accumulated seconds for an app
    fun getAccumulatedSeconds(packageName: String): Int {
        val value = prefs.getInt(PREFIX_ACCUMULATED + packageName, 0)
        println("TimerStorage: getAccumulatedSeconds($packageName) = $value")
        return value
    }
    
    // Save accumulated seconds for an app
    fun saveAccumulatedSeconds(packageName: String, seconds: Int) {
        prefs.edit().putInt(PREFIX_ACCUMULATED + packageName, seconds).apply()
        println("TimerStorage: saveAccumulatedSeconds($packageName, $seconds)")
    }
    
    // Check if app is currently locked (overlay showing)
    fun isLocked(packageName: String): Boolean {
        val value = prefs.getBoolean(PREFIX_LOCKED + packageName, false)
        println("TimerStorage: isLocked($packageName) = $value")
        return value
    }
    
    // Set app locked state
    fun setLocked(packageName: String, locked: Boolean) {
        prefs.edit().putBoolean(PREFIX_LOCKED + packageName, locked).apply()
        println("TimerStorage: setLocked($packageName, $locked)")
    }
    
    // Get last timestamp when app was opened
    fun getLastTimestamp(packageName: String): Long {
        return prefs.getLong(PREFIX_LAST_TIMESTAMP + packageName, 0L)
    }
    
    // Save timestamp when app was opened
    fun saveLastTimestamp(packageName: String, timestamp: Long) {
        prefs.edit().putLong(PREFIX_LAST_TIMESTAMP + packageName, timestamp).apply()
    }
    
    // Reset timer for an app (called after unlock)
    fun resetTimer(packageName: String) {
        prefs.edit()
            .putInt(PREFIX_ACCUMULATED + packageName, 0)
            .putBoolean(PREFIX_LOCKED + packageName, false)
            .putLong(PREFIX_LAST_TIMESTAMP + packageName, 0L)
            .apply()
    }
    
    // Clear all data for an app
    fun clearApp(packageName: String) {
        prefs.edit()
            .remove(PREFIX_ACCUMULATED + packageName)
            .remove(PREFIX_LOCKED + packageName)
            .remove(PREFIX_LAST_TIMESTAMP + packageName)
            .apply()
    }
}
