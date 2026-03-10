package com.proto.proto.bridge

import io.flutter.plugin.common.EventChannel

object EventBridge : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendBlockedCount(count: Int) {
        eventSink?.success(mapOf("type" to "blockedCount", "count" to count))
    }
}
