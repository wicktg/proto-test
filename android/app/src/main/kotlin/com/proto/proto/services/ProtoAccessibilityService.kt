package com.proto.proto.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.graphics.Rect
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.proto.proto.bridge.EventBridge
import com.proto.proto.classifier.ContentType
import com.proto.proto.classifier.VideoClassifier
import com.proto.proto.overlay.OverlayManager

class ProtoAccessibilityService : AccessibilityService() {

    private val classifier = VideoClassifier()
    private lateinit var overlayManager: OverlayManager
    private var isSessionActive = false
    private var blockedCount = 0

    companion object {
        const val YOUTUBE_PACKAGE = "com.google.android.youtube"
        var instance: ProtoAccessibilityService? = null

        fun configure(allowlist: List<String>, keywords: List<String>) {
            instance?.classifier?.configure(allowlist, keywords)
        }

        fun startSession() {
            instance?.apply {
                isSessionActive = true
                blockedCount = 0
            }
        }

        fun stopSession() {
            instance?.apply {
                isSessionActive = false
                overlayManager.clearOverlays()
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        overlayManager = OverlayManager(this)
        serviceInfo = serviceInfo?.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            packageNames = arrayOf(YOUTUBE_PACKAGE)
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 300
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!isSessionActive) return
        if (event.packageName != YOUTUBE_PACKAGE) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val desc = event.contentDescription?.toString() ?: ""
                val textContent = event.text.joinToString(" ")
                if (classifier.isShorts(desc) || classifier.isShorts(textContent)) {
                    handleShortsDetected()
                }
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                scanFeed(event.source)
            }
        }
    }

    private fun handleShortsDetected() {
        blockedCount++
        EventBridge.sendBlockedCount(blockedCount)
        performGlobalAction(GLOBAL_ACTION_BACK)
    }

    private fun scanFeed(rootNode: AccessibilityNodeInfo?) {
        rootNode ?: return
        overlayManager.clearOverlays()
        collectVideoNodes(rootNode).forEach { node ->
            val title = node.contentDescription?.toString()
                ?: node.text?.toString()
                ?: return@forEach
            if (title.isBlank()) return@forEach

            val channel = findChannelName(node)
            val result = classifier.classify(title, channel)

            if (result.type == ContentType.NON_EDUCATIONAL) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                overlayManager.addDimOverlay(bounds)
                blockedCount++
                EventBridge.sendBlockedCount(blockedCount)
            }
        }
    }

    private fun collectVideoNodes(root: AccessibilityNodeInfo): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        fun traverse(node: AccessibilityNodeInfo) {
            val viewId = node.viewIdResourceName ?: ""
            val desc = node.contentDescription?.toString() ?: ""
            val text = node.text?.toString() ?: ""
            if ((viewId.contains("video_title") ||
                        viewId.contains("thumbnail") ||
                        (desc.length > 20 && !viewId.contains("button"))) &&
                (text.isNotEmpty() || desc.isNotEmpty())
            ) {
                results.add(node)
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { traverse(it) }
            }
        }
        traverse(root)
        return results
    }

    private fun findChannelName(node: AccessibilityNodeInfo): String {
        val parent = node.parent ?: return ""
        for (i in 0 until parent.childCount) {
            val sibling = parent.getChild(i) ?: continue
            val id = sibling.viewIdResourceName ?: ""
            if (id.contains("channel") || id.contains("owner") || id.contains("author")) {
                return sibling.text?.toString() ?: ""
            }
        }
        return ""
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        overlayManager.clearOverlays()
        instance = null
        super.onDestroy()
    }
}
