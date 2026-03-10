package com.proto.proto.services

import android.accessibilityservice.AccessibilityService
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

    // Debounce: prevents ANR by skipping feed scans that arrive faster than 500ms
    private var lastScanTime = 0L

    companion object {
        const val YOUTUBE_PACKAGE = "com.google.android.youtube"
        private const val SCAN_DEBOUNCE_MS = 500L

        // BFS depth limit: YouTube's hierarchy can be 60+ levels deep.
        // Unconstrained recursion causes StackOverflowError → service crash → "not working".
        private const val MAX_TRAVERSE_DEPTH = 12

        var instance: ProtoAccessibilityService? = null
            private set

        fun configure(allowlist: List<String>, keywords: List<String>) {
            instance?.classifier?.configure(allowlist, keywords)
        }

        fun startSession() {
            instance?.apply {
                isSessionActive = true
                blockedCount = 0
                overlayManager.clearOverlays()
            }
        }

        fun stopSession() {
            instance?.apply {
                isSessionActive = false
                overlayManager.clearOverlays()
            }
        }

        fun isConnected(): Boolean = instance != null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        overlayManager = OverlayManager(this)
        // All event types, package filter, and flags are declared in
        // accessibility_service_config.xml. Dynamic setServiceInfo() is intentionally
        // omitted — overriding it at runtime caused "not working" on some OEM devices.
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!isSessionActive) return
        if (event.packageName?.toString() != YOUTUBE_PACKAGE) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // Primary: class name contains "Shorts" (stable across YouTube versions)
                val className = event.className?.toString() ?: ""
                if (className.contains("Shorts", ignoreCase = true)) {
                    handleShortsDetected()
                    return
                }
                // Fallback: window text contains "Shorts" indicator
                val textContent = event.text.joinToString(" ")
                if (textContent.isNotEmpty() && classifier.isShorts(textContent)) {
                    handleShortsDetected()
                }
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val now = System.currentTimeMillis()
                if (now - lastScanTime < SCAN_DEBOUNCE_MS) return
                lastScanTime = now
                event.source?.let { scanFeed(it) }
            }
        }
    }

    private fun handleShortsDetected() {
        blockedCount++
        EventBridge.sendBlockedCount(blockedCount)
        performGlobalAction(GLOBAL_ACTION_BACK)
    }

    private fun scanFeed(rootNode: AccessibilityNodeInfo) {
        val videoNodes = collectVideoNodes(rootNode)
        if (videoNodes.isEmpty()) return

        overlayManager.clearOverlays()

        for (node in videoNodes) {
            val title = node.contentDescription?.toString()
                ?: node.text?.toString()
                ?: continue
            if (title.isBlank()) continue

            // Channel name extraction via view IDs is unreliable in production YouTube
            // (IDs are obfuscated). Pass empty string — classifier keyword-matches on title.
            val result = classifier.classify(title, "")

            if (result.type == ContentType.NON_EDUCATIONAL) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                if (!bounds.isEmpty) {
                    overlayManager.addDimOverlay(bounds)
                    blockedCount++
                    EventBridge.sendBlockedCount(blockedCount)
                }
            }
        }
    }

    /**
     * Iterative BFS traversal with depth cap.
     *
     * The previous recursive implementation caused StackOverflowError on YouTube's
     * deep view hierarchy (60+ levels), crashing the service and producing the
     * "not working" state in Android Settings.
     */
    private fun collectVideoNodes(root: AccessibilityNodeInfo): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        // Queue of (node, depth)
        val queue = ArrayDeque<Pair<AccessibilityNodeInfo, Int>>()
        queue.add(root to 0)

        while (queue.isNotEmpty()) {
            val (node, depth) = queue.removeFirst()

            val viewId = node.viewIdResourceName ?: ""
            val desc = node.contentDescription?.toString() ?: ""
            val text = node.text?.toString() ?: ""

            // Heuristic for video cards: meaningful text, not a button/interactive control
            val isButtonLike = node.isClickable && (
                viewId.contains("button", ignoreCase = true) ||
                node.className?.toString()?.contains("Button") == true ||
                node.className?.toString()?.contains("CheckBox") == true
            )
            val hasContent = desc.length > 15 || text.length > 10

            if (hasContent && !isButtonLike) {
                results.add(node)
            }

            if (depth < MAX_TRAVERSE_DEPTH) {
                // Cap children per node to prevent combinatorial explosion on wide trees
                val childLimit = minOf(node.childCount, 20)
                for (i in 0 until childLimit) {
                    node.getChild(i)?.let { queue.add(it to (depth + 1)) }
                }
            }
        }
        return results
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        overlayManager.clearOverlays()
        instance = null
        super.onDestroy()
    }
}
