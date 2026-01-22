package com.example.pushlock

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class AppLockAccessibilityService : AccessibilityService() {

    // This method is called every time something changes on screen
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // We only care when the foreground app changes
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {

            // This is the app that just came to the screen
            val packageName = event.packageName?.toString() ?: return

            // Send this package name to Flutter
            ForegroundAppChannel.send(packageName)
        }
    }

    // Required override (can be empty)
    override fun onInterrupt() {}
}
