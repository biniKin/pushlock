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
import android.provider.Settings
import android.net.Uri

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!UsageAccessHelper.hasUsageAccess(this)) {
            UsageAccessHelper.requestUsageAccess(this)
        } else {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)  // will open system settings for the user
            } else {
                startAppLockService()
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

