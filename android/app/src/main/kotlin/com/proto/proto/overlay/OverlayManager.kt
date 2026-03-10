package com.proto.proto.overlay

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout

class OverlayManager(private val context: Context) {
    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val overlays = mutableListOf<View>()

    fun addDimOverlay(bounds: Rect) {
        if (!Settings.canDrawOverlays(context)) return
        if (bounds.isEmpty) return

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            bounds.width(), bounds.height(),
            bounds.left, bounds.top,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        val overlay = FrameLayout(context).apply {
            setBackgroundColor(0xCC0A0A0A.toInt())
        }

        try {
            windowManager.addView(overlay, params)
            overlays.add(overlay)
        } catch (_: Exception) {}
    }

    fun clearOverlays() {
        overlays.forEach {
            try { windowManager.removeView(it) } catch (_: Exception) {}
        }
        overlays.clear()
    }
}
