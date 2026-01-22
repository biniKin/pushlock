package com.example.pushlock

import android.content.Context

object LockRepository {

    private const val PREF_NAME = "locked_apps"
    private const val KEY_LOCKED_APPS = "apps"

    fun getLockedApps(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_LOCKED_APPS, emptySet()) ?: emptySet()
    }

    fun lockApp(context: Context, packageName: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val apps = getLockedApps(context).toMutableSet()
        apps.add(packageName)
        prefs.edit().putStringSet(KEY_LOCKED_APPS, apps).apply()
    }

    fun unlockApp(context: Context, packageName: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val apps = getLockedApps(context).toMutableSet()
        apps.remove(packageName)
        prefs.edit().putStringSet(KEY_LOCKED_APPS, apps).apply()
    }

    fun isLocked(context: Context, packageName: String): Boolean {
        return getLockedApps(context).contains(packageName)
    }

    
}
