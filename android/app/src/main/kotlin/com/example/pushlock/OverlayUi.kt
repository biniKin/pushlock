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
        if (flutterView != null) return

        // Create FlutterEngine with overlayMain entry point
        flutterEngine = FlutterEngine(context)
        
        // Execute the overlayMain function from lib/main.dart
        val dartEntrypoint = DartExecutor.DartEntrypoint(
            io.flutter.FlutterInjector.instance().flutterLoader().findAppBundlePath(),
            "overlayMain"
        )
        
        flutterEngine!!.dartExecutor.executeDartEntrypoint(dartEntrypoint)


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

        // Send data AFTER engine is ready
        Handler(Looper.getMainLooper()).post {
            channel!!.invokeMethod(
                "showOverlay",
                mapOf(
                    "packageName" to packageName,
                    "appName" to appName
                )
            )
        }

        flutterView = FlutterView(context).apply {
            attachToFlutterEngine(flutterEngine!!)
        }

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
    }

    fun removeOverlay() {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        flutterView?.let { wm.removeView(it) }
        flutterView = null

        channel?.setMethodCallHandler(null)
        channel = null

        flutterEngine?.destroy()
        flutterEngine = null
    }
}
