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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.net.Uri

class MainActivity : FlutterActivity() {
    private val DEEP_LINK_CHANNEL = "com.example.pushlock/navigation"
    private val CHANNEL = "com.example.pushlock/app_lock"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Add test locked apps to database (for testing only)
        TestHelper.addTestLockedApps(this)

        if (!UsageAccessHelper.hasUsageAccess(this)) {
            UsageAccessHelper.requestUsageAccess(this)
        } else {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            } else {
                startAppLockService()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            // Handle method calls from Flutter if needed
            // result.notImplemented()


            when(call.method) {
                "addLockedApp" -> {
                    val data = call.arguments

                    val packageName = data["packageName"] as String
                    val appName = data["appName"] as String
                    val timeout = data["timeoutSeconds"] as Int
                    val isStrict = data["isStrict"] as Boolean
            
            
                    result.success(true)
                }

                "removeLockedApp" -> {
                    val packageName = call.arguments as String
                    
                    result.success(true)
                }

                "getLockedApp" -> {}

                "isAppLocked" -> {
                    val packageName = call.arguments as String
                }

                "navigation" -> {}
            }
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

