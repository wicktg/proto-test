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

    // Debounce: YouTube fires TYPE_WINDOW_CONTENT_CHANGED on every pixel scroll.
    // Without this, scanFeed() runs 10–20 times/second → hundreds of WindowManager
    // binder calls/second → service ANR or WindowManager BadTokenException.
    private var lastScanTime = 0L

    companion object {
        const val YOUTUBE_PACKAGE = "com.google.android.youtube"
        private const val SCAN_DEBOUNCE_MS = 600L

        // Hard cap on simultaneous overlays. Without this, the broad original
        // heuristic (desc.length > 15) matched 30–80 nodes per scan, causing
        // WindowManager to exceed its per-app window limit and crash the service.
        private const val MAX_OVERLAYS = 12

        // BFS depth cap — YouTube's view hierarchy is 60+ levels deep.
        private const val MAX_TRAVERSE_DEPTH = 10

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
        // Config is fully declared in accessibility_service_config.xml.
        // Calling setServiceInfo() here caused "not working" on OEM devices.
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!isSessionActive) return
        if (event.packageName?.toString() != YOUTUBE_PACKAGE) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // Primary Shorts signal: YouTube names the Shorts activity explicitly.
                val className = event.className?.toString() ?: ""
                if (className.contains("Shorts", ignoreCase = true)) {
                    handleShortsDetected()
                    return
                }
                // Fallback: event text includes "Shorts" label
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
        val videoCards = findVideoCards(rootNode)
        if (videoCards.isEmpty()) {
            overlayManager.clearOverlays()
            return
        }

        val nonEduBounds = mutableListOf<Rect>()

        for (node in videoCards) {
            val desc = node.contentDescription?.toString() ?: continue
            if (desc.isBlank()) continue

            val result = classifier.classify(desc, "")
            if (result.type == ContentType.NON_EDUCATIONAL) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                if (!bounds.isEmpty) {
                    nonEduBounds.add(bounds)
                    if (nonEduBounds.size >= MAX_OVERLAYS) break
                }
            }
        }

        // Only update overlays when the blocked count changed — prevents
        // clearing and re-adding identical overlays every 600ms (visible flicker).
        val newCount = nonEduBounds.size
        if (newCount != overlayManager.currentCount) {
            overlayManager.updateOverlays(nonEduBounds)
            val delta = newCount - overlayManager.currentCount
            if (delta > 0) {
                blockedCount += delta
                EventBridge.sendBlockedCount(blockedCount)
            }
        }
    }

    /**
     * Identifies YouTube video card nodes using three precise criteria:
     *
     * 1. Node must be CLICKABLE — video cards are tappable. Navigation
     *    buttons, headers, and section labels are not.
     *
     * 2. Content description must contain YouTube temporal metadata —
     *    "ago" (e.g. "2 years ago") and "view" (e.g. "4.1 million views").
     *    YouTube auto-generates these in the accessibility string for every
     *    video card. They are absent from buttons, headers, and ads without
     *    engagement stats.
     *
     * 3. Content description must be > 40 chars — long enough to contain
     *    a title + channel + stats. Short button labels ("Like", "Share")
     *    are always filtered out.
     *
     * This replaces the previous `desc.length > 15` heuristic which matched
     * 30–80 nodes per scan (section headers, chip filters, banners, ad units),
     * flooding WindowManager and crashing the service.
     */
    private fun findVideoCards(root: AccessibilityNodeInfo): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        val queue = ArrayDeque<Pair<AccessibilityNodeInfo, Int>>()
        queue.add(root to 0)

        while (queue.isNotEmpty() && results.size < MAX_OVERLAYS * 2) {
            val (node, depth) = queue.removeFirst()

            val desc = node.contentDescription?.toString() ?: ""

            if (isYouTubeVideoCard(node, desc)) {
                results.add(node)
                // Don't traverse into a video card's children — the card itself
                // is the target. Traversing children would add duplicate matches
                // for the same video (parent + child both matching).
                continue
            }

            if (depth < MAX_TRAVERSE_DEPTH) {
                val childLimit = minOf(node.childCount, 15)
                for (i in 0 until childLimit) {
                    node.getChild(i)?.let { queue.add(it to (depth + 1)) }
                }
            }
        }
        return results
    }

    private fun isYouTubeVideoCard(node: AccessibilityNodeInfo, desc: String): Boolean {
        // Must be tappable — video cards open a video when tapped
        if (!node.isClickable) return false

        // Short labels are UI controls (Like, Share, Subscribe, More options)
        if (desc.length < 40) return false

        val lowerDesc = desc.lowercase()

        // YouTube accessibility strings for video cards always include temporal
        // metadata ("ago") and view counts ("view"). These do not appear in
        // navigation items, section headers, chip filters, or search inputs.
        val hasTemporalMarker = lowerDesc.contains(" ago") ||
                lowerDesc.contains("hour") ||
                lowerDesc.contains("minute") ||
                lowerDesc.contains("day") ||
                lowerDesc.contains("week") ||
                lowerDesc.contains("month") ||
                lowerDesc.contains("year")

        val hasViewCount = lowerDesc.contains("view")

        return hasTemporalMarker && hasViewCount
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        overlayManager.clearOverlays()
        instance = null
        super.onDestroy()
    }
}
