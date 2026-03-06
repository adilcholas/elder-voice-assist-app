package com.example.elder_voice_assist

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    private val CHANNEL = "elder_voice/background_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    VoiceForegroundService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    VoiceForegroundService.eventSink = null
                }
            })
    }
}