package com.example.pushlock

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.Button

import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

import android.os.Handler
import android.os.Looper




class OverlayUi(private val context: Context) {
    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null
    private var channel: MethodChannel? = null

    fun showOverlay(packageName: String, appName: String) {
        if (flutterView != null) {
            Log.d("OVERLAY_UI", "Overlay already showing, updating data")
            // Overlay already exists, just update the data
            channel?.invokeMethod(
                "showOverlay",
                mapOf(
                    "packageName" to packageName,
                    "appName" to appName
                )
            )
            return
        }

        Log.d("OVERLAY_UI", "Creating new overlay for $packageName")

        // Create FlutterEngine with overlayMain entry point
        flutterEngine = FlutterEngine(context)
        
        // Execute the overlayMain function from lib/main.dart
        val dartEntrypoint = DartExecutor.DartEntrypoint(
            io.flutter.FlutterInjector.instance().flutterLoader().findAppBundlePath(),
            "overlayMain"
        )
        
        flutterEngine!!.dartExecutor.executeDartEntrypoint(dartEntrypoint)

        // Create FlutterView and attach to engine
        flutterView = FlutterView(context).apply {
            attachToFlutterEngine(flutterEngine!!)
        }

        // SINGLE MethodChannel
        channel = MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            "overlay_channel"
        )

        //  Listen from Flutter
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "unlock" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        (context as AppLockService).unlockApp(pkg)
                        result.success(true)
                    } else {
                        result.error("ERR", "packageName missing", null)
                    }
                }
                "openMainApp" -> {
                    val pkg = call.argument<String>("packageName")
                    val appName = call.argument<String>("appName")
                    if (pkg != null) {
                        Log.d("OVERLAY_UI", "Opening main app with camera for $pkg")
                        // Remove overlay first
                        removeOverlay()
                        
                        // Open main Flutter app with camera page
                        val intent = Intent(context, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            putExtra("openCamera", true)
                            putExtra("packageName", pkg)
                            putExtra("appName", appName)
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("ERR", "packageName missing", null)
                    }
                }
            }
        }

        // Add view to WindowManager
        val params = WindowManager.LayoutParams(
            MATCH_PARENT,
            MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.addView(flutterView, params)
        
        Log.d("OVERLAY_UI", "Overlay view added to WindowManager")

        // Send data AFTER view is added and engine has had time to initialize
        // Use a longer delay to ensure Flutter is fully ready
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                Log.d("OVERLAY_UI", "Sending data to Flutter: pkg=$packageName, app=$appName")
                channel?.invokeMethod(
                    "showOverlay",
                    mapOf(
                        "packageName" to packageName,
                        "appName" to appName
                    )
                )
            } catch (e: Exception) {
                Log.e("OVERLAY_UI", "Error sending data to Flutter: ${e.message}")
            }
        }, 500) // Increased delay to 500ms
    }

    fun removeOverlay() {
        Log.d("OVERLAY_UI", "Removing overlay")
        
        try {
            // First, detach FlutterView from engine
            flutterView?.let { view ->
                Log.d("OVERLAY_UI", "Detaching FlutterView from engine")
                view.detachFromFlutterEngine()
                
                // Then remove from WindowManager
                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.removeView(view)
                Log.d("OVERLAY_UI", "FlutterView removed from WindowManager")
            }
            flutterView = null

            // Clear method channel
            channel?.setMethodCallHandler(null)
            channel = null
            Log.d("OVERLAY_UI", "Method channel cleared")

            // Finally destroy the engine
            flutterEngine?.let { engine ->
                Log.d("OVERLAY_UI", "Destroying Flutter engine")
                engine.destroy()
            }
            flutterEngine = null
            Log.d("OVERLAY_UI", "Flutter engine destroyed")
        } catch (e: Exception) {
            Log.e("OVERLAY_UI", "Error removing overlay: ${e.message}")
            e.printStackTrace()
        }
    }
}
