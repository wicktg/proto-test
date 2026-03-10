package com.proto.proto.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import com.proto.proto.services.ProtoAccessibilityService
import com.proto.proto.services.ProtoForegroundService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SessionBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    private val db = SessionDatabase(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSession" -> {
                val durationMinutes = call.argument<Int>("durationMinutes") ?: 25
                val allowlist = call.argument<List<String>>("allowlist") ?: emptyList()
                val keywords = call.argument<List<String>>("keywords") ?: emptyList()

                ProtoAccessibilityService.configure(allowlist, keywords)
                ProtoAccessibilityService.startSession()

                val intent = Intent(context, ProtoForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                result.success(null)
            }

            "stopSession" -> {
                ProtoAccessibilityService.stopSession()
                context.stopService(Intent(context, ProtoForegroundService::class.java))
                result.success(null)
            }

            "saveSession" -> {
                val startTime = call.argument<Long>("startTime") ?: 0L
                val endTime = call.argument<Long>("endTime") ?: 0L
                val durationMinutes = call.argument<Int>("durationMinutes") ?: 0
                val blockedCount = call.argument<Int>("blockedCount") ?: 0
                db.insert(startTime, endTime, durationMinutes, blockedCount)
                result.success(null)
            }

            "getSessionHistory" -> {
                result.success(db.getAll())
            }

            "checkPermissions" -> {
                result.success(
                    mapOf(
                        "accessibility" to isAccessibilityEnabled(),
                        "overlay" to Settings.canDrawOverlays(context),
                        "notification" to true
                    )
                )
            }

            "openAccessibilitySettings" -> {
                context.startActivity(
                    Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                )
                result.success(null)
            }

            "openOverlaySettings" -> {
                context.startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${context.packageName}")
                    ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                )
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        return am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.resolveInfo.serviceInfo.packageName == context.packageName }
    }
}
