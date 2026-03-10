package com.proto.proto

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.proto.proto.bridge.EventBridge
import com.proto.proto.bridge.SessionBridge

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "proto/session"
        ).setMethodCallHandler(SessionBridge(this))

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "proto/events"
        ).setStreamHandler(EventBridge)
    }
}
