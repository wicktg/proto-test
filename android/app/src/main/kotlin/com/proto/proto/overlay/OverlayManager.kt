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

    /** How many overlays are currently visible. Used by the service to skip
     *  redundant clear+re-add cycles when the blocked set hasn't changed. */
    var currentCount: Int = 0
        private set

    /**
     * Replace current overlays with a new set of bounds.
     *
     * Called instead of clear() + addDimOverlay() in a loop so that the
     * service can compare [newBounds].size against [currentCount] before
     * calling this — avoiding the clear-and-rewrite on every debounce tick
     * when the same content is still on screen (eliminates visible flicker).
     */
    fun updateOverlays(newBounds: List<Rect>) {
        clearOverlays()
        for (bounds in newBounds) {
            addDimOverlay(bounds)
        }
    }

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
            currentCount = overlays.size
        } catch (_: Exception) {
            // WindowManager.BadTokenException or BadParcelableException:
            // service context is gone or overlay permission was revoked mid-session.
        }
    }

    fun clearOverlays() {
        overlays.forEach {
            try { windowManager.removeView(it) } catch (_: Exception) {}
        }
        overlays.clear()
        currentCount = 0
    }
}
