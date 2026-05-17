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

import android.app.AppOpsManager
import android.content.Context
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
import com.example.pushlock.data.repo.AppStatRepo
import com.example.pushlock.data.repo.LockedAppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val DEEP_LINK_CHANNEL = "com.example.pushlock/navigation"
    private val CHANNEL = "com.example.pushlock/app_lock"
    private lateinit var lockedAppRepo: LockedAppRepo
    private lateinit var appStatRepo: AppStatRepo
    private var pendingCameraIntent: Intent? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // handleIntent(intent)
        pendingCameraIntent = intent
        // Initialize Room database 
        val database = PushLockDatabase.getDatabase(this)
        lockedAppRepo = LockedAppRepo(database.lockedAppDao())
        appStatRepo = AppStatRepo(database.appStatDao())

        // Add test locked apps to database (for testing only)
        TestHelper.addTestLockedApps(this)

        // Don't automatically request permissions - let Flutter handle it through permissions page
        // Only start service if all permissions are already granted
        if (hasAllRequiredPermissions()) {
            startAppLockService()
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Check if permissions were granted and start service if needed
        if (hasAllRequiredPermissions()) {
            startAppLockService()
        }
    }
    
    private fun hasAllRequiredPermissions(): Boolean {
        val hasUsage = UsageAccessHelper.hasUsageAccess(this)
        val hasOverlay = Settings.canDrawOverlays(this)
        return hasUsage && hasOverlay
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

                "app_stat_for_day" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Arguments must be a map", null)
                            return@setMethodCallHandler
                        }

                        val packageName = args["packageName"] as? String
                        val date = args["date"] as? String

                        if (packageName == null || date == null) {
                            result.error("MISSING_ARGS", "Missing packageName or date", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val appStat = withContext(Dispatchers.IO) {
                                    appStatRepo.appStatForDay(packageName, date)
                                }

                                if (appStat != null) {
                                    result.success(
                                        mapOf(
                                            "packageName" to appStat.packageName,
                                            "appName" to appStat.appName,
                                            "dailyUsageTime" to appStat.dailyUsageTime.toString(),
                                            "date" to appStat.date
                                        )
                                    )
                                } else {
                                    result.success(null)
                                }
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "apps_stat_for_day" -> {
                    try {
                        val date = call.arguments as? String
                        if (date == null) {
                            result.error("INVALID_ARGS", "Date is required", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val appStats = withContext(Dispatchers.IO) {
                                    appStatRepo.appsStatForDay(date)
                                }

                                val statsList = appStats.map { stat ->
                                    mapOf(
                                        "packageName" to stat.packageName,
                                        "appName" to stat.appName,
                                        "dailyUsageTime" to stat.dailyUsageTime.toString(),
                                        "date" to stat.date
                                    )
                                }

                                result.success(statsList)
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "total_usage_for_day" -> {
                    try {
                        val date = call.arguments as? String
                        if (date == null) {
                            result.error("INVALID_ARGS", "Date is required", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val totalUsage = withContext(Dispatchers.IO) {
                                    appStatRepo.getTotalUsageForDay(date)
                                }

                                result.success(totalUsage ?: 0L)
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "app_stat_between_dates" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Arguments must be a map", null)
                            return@setMethodCallHandler
                        }

                        val startDate = args["startDate"] as? String
                        val endDate = args["endDate"] as? String
                        val packageName = args["packageName"] as? String

                        if (startDate == null || endDate == null || packageName == null) {
                            result.error("MISSING_ARGS", "Missing startDate, endDate, or packageName", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val appStats = withContext(Dispatchers.IO) {
                                    appStatRepo.getAppStatBetweenDates(startDate, endDate, packageName)
                                }

                                val statsList = appStats.map { stat ->
                                    mapOf(
                                        "packageName" to stat.packageName,
                                        "appName" to stat.appName,
                                        "dailyUsageTime" to stat.dailyUsageTime.toString(),
                                        "date" to stat.date
                                    )
                                }

                                result.success(statsList)
                            } catch (e: Exception) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "delete_old_stat" -> {
                    try {
                        val beforeDate = call.arguments as? String
                        if (beforeDate == null) {
                            result.error("INVALID_ARGS", "Date is required", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                withContext(Dispatchers.IO) {
                                    appStatRepo.deleteOldStat(beforeDate)
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

                "canDrawOverLay" -> {
                    val canDraw = Settings.canDrawOverlays(applicationContext)
                    result.success(canDraw)
                }

                "hasUsageAccess" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val mode = appOps.checkOpNoThrow(
                        AppOpsManager.OPSTR_GET_USAGE_STATS,
                        android.os.Process.myUid(),
                        packageName
                    )

                    val granted = mode == AppOpsManager.MODE_ALLOWED
                    result.success(granted)
                }

                "requestOverlayPermission" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "requestUsagePermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "requestBatteryOptimization" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = Uri.parse("package:$packageName")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "hasBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                        val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                        result.success(isIgnoring)
                    } else {
                        result.success(true) // Not needed on older versions
                    }
                }

                "startAppLockService" -> {
                    try {
                        startAppLockService()
                        result.success(true)
                    } catch (e: Exception) {
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
                // result.notImplemented()
                if (call.method == "flutterReady") {
                        pendingCameraIntent?.let {
                        handleIntent(it)
                        pendingCameraIntent = null
                    }
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Important: update the intent
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let {
            // Check if we should open camera page
            val openCamera = it.getBooleanExtra("openCamera", false)
            val packageName = it.getStringExtra("packageName")
            val appName = it.getStringExtra("appName")
            
            if (openCamera && packageName != null) {
                // Navigate to camera page via Flutter
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, DEEP_LINK_CHANNEL).invokeMethod(
                        "openCamera",
                        mapOf(
                            "packageName" to packageName,
                            "appName" to (appName ?: "")
                        )
                    )
                }
                return
            }
            
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

