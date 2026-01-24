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
import android.widget.Button

class OverlayUi(private val context: Context) {
    private var overlayView: View? = null

    fun showOverlay() {
        if (overlayView != null) return // already showing

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        overlayView = LayoutInflater.from(context).inflate(R.layout.overlay_lock, null)
        wm.addView(overlayView, layoutParams)

        

        overlayView?.findViewById<Button>(R.id.btn_unlock)?.setOnClickListener {
            // Create intent to open the app with unlock page
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                data = Uri.parse("pushlock://unlock")
                putExtra("route", "/unlock")
            }   
            context.startActivity(intent)

            removeOverlay() // remove overlay after opening app
        }
    }

    fun removeOverlay() {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        overlayView?.let { wm.removeView(it) }
        overlayView = null
    }
}
