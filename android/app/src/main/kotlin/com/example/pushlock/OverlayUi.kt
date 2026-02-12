package com.example.pushlock

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.Button
import android.widget.TextView

import android.provider.Settings 
import android.view.KeyEvent 
import android.view.ContextThemeWrapper



class OverlayUi(private val context: Context) {
    private var wm: WindowManager? = null
    private var overlayView: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var isLaunching = false

    fun showOverlay(packageName: String, appName: String) {

        // Prevent duplicate overlays
        if (overlayView != null) {
            overlayView?.findViewById<TextView>(R.id.txt_message)?.text =
                "You should do push ups to unlock $appName."
            return
        }

        // Check overlay permission (M+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(context)) {
                Log.e("OVERLAY_UI", "Overlay permission not granted")
                return
            }
        }

        wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        val themeWrapper = ContextThemeWrapper(context, R.style.AppTheme)
        val inflater = LayoutInflater.from(themeWrapper)
        val view = inflater.inflate(R.layout.overlay_lock, null)

        view.findViewById<TextView>(R.id.txt_message)?.text =
            "You should do push ups to unlock $appName."

        view.findViewById<Button>(R.id.btn_start_pushups)?.setOnClickListener {

            if (isLaunching) return@setOnClickListener
            isLaunching = true

            try {
                removeOverlay()

                val intent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("openCamera", true)
                    putExtra("packageName", packageName)
                    putExtra("appName", appName)
                }

                context.startActivity(intent)

            } catch (e: Exception) {
                Log.e("OVERLAY_UI", "Error launching MainActivity: ${e.message}")
                isLaunching = false
            }
        }

        // Window type
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        // FULL BLOCKING FLAGS (no touch leaks)
        val flags =
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            flags,
            PixelFormat.TRANSLUCENT
        )

        try {
            wm?.addView(view, layoutParams)

            // Immersive full screen
            view.systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY

            // Re-apply immersive if system UI appears
            view.setOnSystemUiVisibilityChangeListener {
                view.systemUiVisibility =
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            }

            // Capture back button
            view.isFocusableInTouchMode = true
            view.requestFocus()

            view.setOnKeyListener { _, keyCode, event ->
                if (keyCode == KeyEvent.KEYCODE_BACK &&
                    event.action == KeyEvent.ACTION_UP
                ) {
                    Log.d("OVERLAY_UI", "Back button blocked")
                    true
                } else {
                    false
                }
            }

            overlayView = view
            params = layoutParams

            Log.d("OVERLAY_UI", "Overlay successfully added")

        } catch (e: Exception) {
            Log.e("OVERLAY_UI", "Failed to add overlay: ${e.message}")
            e.printStackTrace()
        }
    }

    fun removeOverlay() {

        try {
            val v = overlayView
            if (v != null && wm != null) {
                try {
                    wm?.removeView(v)
                } catch (e: IllegalArgumentException) {
                    Log.w("OVERLAY_UI", "Overlay already removed")
                }
            }
        } catch (e: Exception) {
            Log.e("OVERLAY_UI", "Error removing overlay: ${e.message}")
        } finally {
            overlayView = null
            params = null
            isLaunching = false
        }
    }

}
