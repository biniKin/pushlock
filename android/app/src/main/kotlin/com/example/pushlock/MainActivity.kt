// package com.example.pushlock

// import io.flutter.embedding.android.FlutterActivity

// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.EventChannel
// import android.content.Intent
// import android.os.Build
// import android.os.Bundle


// class MainActivity : FlutterActivity() {
//     // override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//     //     super.configureFlutterEngine(flutterEngine)

//     //     EventChannel(
//     //         flutterEngine.dartExecutor.binaryMessenger,
//     //         "foreground_app_stream"
//     //     ).setStreamHandler(object : EventChannel.StreamHandler {

//     //         override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//     //             ForegroundAppChannel.startListening(events!!)
//     //         }

//     //         override fun onCancel(arguments: Any?) {
//     //             ForegroundAppChannel.stopListening()
//     //         }
//     //     })
//     // }

//     override fun onCreate(savedInstanceState: Bundle?) {
//         super.onCreate(savedInstanceState)

//         val intent = Intent(this, AppLockService::class.java)

//         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//             startForegroundService(intent)
//         } else {
//             startService(intent)
//         }
//     }


// }


package com.example.pushlock

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.pushlock.data.local.PushLockDatabase
import com.example.pushlock.data.local.LockedAppEntity
import com.example.pushlock.data.repo.LockedAppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val DEEP_LINK_CHANNEL = "com.example.pushlock/navigation"
    private val CHANNEL = "com.example.pushlock/app_lock"
    private lateinit var lockedAppRepo: LockedAppRepo

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize Room database
        val database = PushLockDatabase.getDatabase(this)
        lockedAppRepo = LockedAppRepo(database.lockedAppDao())

        // Add test locked apps to database (for testing only)
        TestHelper.addTestLockedApps(this)

        // Check and request permissions in order
        checkAndRequestPermissions()
    }
    
    override fun onResume() {
        super.onResume()
        // Check permissions again when returning to the app
        checkAndRequestPermissions()
    }
    
    private fun checkAndRequestPermissions() {
        // Check permissions in priority order
        if (!UsageAccessHelper.hasUsageAccess(this)) {
            UsageAccessHelper.requestUsageAccess(this)
            return
        }
        
        if (!Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
            return
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                requestBatteryOptimizationExemption()
                return
            }
        }
        
        // All permissions granted, start the service
        startAppLockService()
    }

    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            val packageName = packageName
            
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            
            when(call.method) {
                "addLockedApp" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Arguments must be a map", null)
                            return@setMethodCallHandler
                        }

                        val packageName = args["packageName"] as? String
                        val appName = args["appName"] as? String
                        val timeout = args["timeoutSeconds"] as? Int
                        val isStrict = args["isStrict"] as? Boolean

                        if (packageName == null || appName == null || timeout == null || isStrict == null) {
                            result.error("MISSING_ARGS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                withContext(Dispatchers.IO) {
                                    lockedAppRepo.addApp(
                                        LockedAppEntity(
                                            packageName = packageName,
                                            appName = appName,
                                            timeoutSecond = timeout,
                                            isStrict = isStrict
                                        )
                                    )
                                }
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "removeLockedApp" -> {
                    try {
                        val packageName = call.arguments as? String
                        if (packageName == null) {
                            result.error("INVALID_ARGS", "Package name is required", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                withContext(Dispatchers.IO) {
                                    lockedAppRepo.removeAppByPackageName(packageName)
                                }
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "getLockedApps" -> {
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val apps = withContext(Dispatchers.IO) {
                                lockedAppRepo.fetchLockedApps()
                            }
                            
                            // Convert to list of maps for Flutter
                            val appsList = apps.map { app ->
                                mapOf(
                                    "packageName" to app.packageName,
                                    "appName" to app.appName,
                                    "timeoutSecond" to app.timeoutSecond,
                                    "isStrict" to app.isStrict
                                )
                            }
                            
                            result.success(appsList)
                        } catch (e: Exception) {
                            result.error("DB_ERROR", e.message, null)
                        }
                    }
                }

                "updateLockedApp" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Arguments must be a map", null)
                            return@setMethodCallHandler
                        }

                        val packageName = args["packageName"] as? String
                        val appName = args["appName"] as? String
                        val timeout = args["timeoutSeconds"] as? Int
                        val isStrict = args["isStrict"] as? Boolean

                        if (packageName == null || appName == null || timeout == null || isStrict == null) {
                            result.error("MISSING_ARGS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                withContext(Dispatchers.IO) {
                                    lockedAppRepo.updateApp(
                                        LockedAppEntity(
                                            packageName = packageName,
                                            appName = appName,
                                            timeoutSecond = timeout,
                                            isStrict = isStrict
                                        )
                                    )
                                }
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "isAppLocked" -> {
                    try {
                        val packageName = call.arguments as? String
                        if (packageName == null) {
                            result.error("INVALID_ARGS", "Package name is required", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val isLocked = withContext(Dispatchers.IO) {
                                    lockedAppRepo.isAppLocked(packageName)
                                }
                                result.success(isLocked)
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "unlockApp" -> {
                    try {
                        val packageName = call.arguments as? String
                        android.util.Log.d("APP_LOCK", "MainActivity: unlockApp called with: $packageName")
                        println("========== MAIN_ACTIVITY: unlockApp called with: $packageName ==========")
                        
                        if (packageName == null) {
                            android.util.Log.e("APP_LOCK", "MainActivity: Package name is null")
                            result.error("INVALID_ARGS", "Package name is required", null)
                            return@setMethodCallHandler
                        }

                        // Send explicit broadcast to AppLockService to unlock the app
                        val intent = Intent("com.example.pushlock.UNLOCK_APP")
                        intent.setPackage(this.packageName) // Make it explicit to our app
                        intent.putExtra("packageName", packageName)
                        sendBroadcast(intent)
                        
                        android.util.Log.d("APP_LOCK", "MainActivity: Explicit broadcast sent for $packageName")
                        println("========== MAIN_ACTIVITY: Explicit broadcast sent for $packageName ==========")
                        
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("APP_LOCK", "MainActivity: Error unlocking app: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // Deep link channel for navigation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
            .setMethodCallHandler { call, result ->
                result.notImplemented()
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let {
            // Check if this is a deep link to unlock page
            val route = it.getStringExtra("route")
            val data = it.data
            
            if (route == "/unlock" || data?.toString()?.contains("unlock") == true) {
                // Navigate to unlock page via Flutter
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, DEEP_LINK_CHANNEL).invokeMethod("navigateToUnlock", null)
                }
            }
        }
    }

    private fun startAppLockService() {
        val intent = Intent(this, AppLockService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}

