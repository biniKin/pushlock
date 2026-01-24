# Timeout Feature Implementation Plan

## Overview
This document explains where to add code for the timeout feature that delays showing the lock overlay.

---

## Files to Modify

### 1. **AppLockService.kt** ✅ (Already commented)

**Location:** `android/app/src/main/kotlin/com/example/pushlock/AppLockService.kt`

**What to add:**

#### A. At the top (imports):
```kotlin
import com.example.pushlock.data.local.LockedAppDatabase
import com.example.pushlock.data.repo.LockedAppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
```

#### B. Class-level variables (after existing variables):
```kotlin
private lateinit var lockedAppRepo: LockedAppRepo
private val serviceScope = CoroutineScope(Dispatchers.Main)

// Track when each app was opened
private val appOpenTimestamps = mutableMapOf<String, Long>()

// Track timeout handlers for each app
private val timeoutHandlers = mutableMapOf<String, Handler>()
private val timeoutRunnables = mutableMapOf<String, Runnable>()

// Track last foreground app to detect switches
private var lastForegroundApp: String? = null
```

#### C. In onCreate() method (after overlayUi initialization):
```kotlin
val database = LockedAppDatabase.getDatabase(this)
lockedAppRepo = LockedAppRepo(database.lockedAppDao())
```

#### D. Replace the entire startMonitoring() logic:
```kotlin
private fun startMonitoring() {
    handler.post(object : Runnable {
        override fun run() {
            val foregroundApp = detector.getForegroundApp()
            
            // STEP 1: Detect app change
            if (foregroundApp != lastForegroundApp) {
                Log.d("APP_LOCK", "App changed: $lastForegroundApp -> $foregroundApp")
                
                // Cancel timer for old app
                lastForegroundApp?.let { cancelTimeoutTimer(it) }
                
                // STEP 2: Check if new app is locked
                if (foregroundApp != null) {
                    serviceScope.launch {
                        val lockedApp = lockedAppRepo.getLockedApp(foregroundApp)
                        
                        if (lockedApp != null) {
                            // STEP 3: Get timeout value
                            val timeoutSeconds = lockedApp.timeoutSecond
                            Log.d("APP_LOCK", "Locked app detected: $foregroundApp, timeout: ${timeoutSeconds}s")
                            
                            // STEP 4: Start timer
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
                
                // STEP 6: Update last app
                lastForegroundApp = foregroundApp
            }
            
            // Poll every 500ms
            handler.postDelayed(this, 500)
        }
    })
}
```

#### E. Add new methods (at the end of class):
```kotlin
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
        
        // Clean up
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

override fun onDestroy() {
    super.onDestroy()
    cancelAllTimers()
    handler.removeCallbacksAndMessages(null)
    overlayUi.removeOverlay()
}
```

---

## How It Works

### Flow Diagram:
```
Service polls every 500ms
    ↓
Check: What app is in foreground?
    ↓
Did app change? (compare with lastForegroundApp)
    ↓ YES
Cancel timer for old app
    ↓
Query Room DB: Is new app locked?
    ↓ YES
Get timeoutSecond value (e.g., 10 seconds)
    ↓
Start Handler.postDelayed(10000ms)
    ↓
Store Handler in map: {"com.instagram.android" → Handler}
    ↓
[User uses Instagram for 10 seconds]
    ↓
Handler executes after 10 seconds
    ↓
Show overlay
    ↓
Clean up maps
```

### Edge Cases Handled:

1. **User switches apps before timeout:**
   - Timer is cancelled immediately
   - No overlay shown
   - New app gets its own timer if locked

2. **User returns to same app:**
   - Treated as new session
   - Timer starts fresh

3. **Service stops:**
   - All timers cancelled in onDestroy()
   - No memory leaks

---

## Testing Steps

1. **Add a locked app to database:**
   ```kotlin
   // In MainActivity or test code
   val app = LockedAppEntity(
       packageName = "com.instagram.android",
       appName = "Instagram",
       timeoutSecond = 5,  // 5 seconds for testing
       isStrict = false
   )
   lockedAppRepo.addApp(app)
   ```

2. **Open Instagram:**
   - Should NOT show overlay immediately
   - Wait 5 seconds
   - Overlay should appear

3. **Switch away before timeout:**
   - Open Instagram
   - After 2 seconds, press home
   - Overlay should NOT appear

4. **Check logs:**
   ```
   APP_LOCK: App changed: null -> com.instagram.android
   APP_LOCK: Locked app detected: com.instagram.android, timeout: 5s
   APP_LOCK: Started timer for com.instagram.android with 5s timeout
   [5 seconds later]
   APP_LOCK: Timeout reached for com.instagram.android
   ```

---

## Variables Explained

| Variable | Type | Purpose |
|----------|------|---------|
| `appOpenTimestamps` | `Map<String, Long>` | Stores when each app was opened (for debugging) |
| `timeoutHandlers` | `Map<String, Handler>` | Stores Handler for each app's timer |
| `timeoutRunnables` | `Map<String, Runnable>` | Stores Runnable for each app's timer |
| `lastForegroundApp` | `String?` | Tracks previous foreground app to detect changes |
| `lockedAppRepo` | `LockedAppRepo` | Repository to query Room database |
| `serviceScope` | `CoroutineScope` | Coroutine scope for async database queries |

---

## Important Notes

1. **Polling interval:** 500ms is a good balance between accuracy and battery
2. **Timer accuracy:** ±500ms due to polling delay (acceptable)
3. **Memory management:** Always cancel timers when app switches
4. **Database queries:** Use coroutines to avoid blocking main thread
5. **Cleanup:** onDestroy() ensures no memory leaks

---

## Next Steps

1. Uncomment all TODO sections in AppLockService.kt
2. Test with a short timeout (5 seconds) first
3. Add logging to verify timer behavior
4. Test edge cases (app switching, service restart)
5. Adjust polling interval if needed (can go down to 300ms)

---

## Optional Enhancements

1. **Show countdown:** Display remaining time in overlay
2. **Pause timer:** When user unlocks, pause instead of cancel
3. **Different timeouts:** Per-app timeout customization
4. **Strict mode:** If isStrict=true, show overlay immediately (no timeout)
