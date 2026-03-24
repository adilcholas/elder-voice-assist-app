package com.example.elder_voice_assist

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "voice_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val intent = android.content.Intent(this@MainActivity, VoiceForegroundService::class.java)
                    startService(intent)
                }

                override fun onCancel(arguments: Any?) {
                    val intent = android.content.Intent(this@MainActivity, VoiceForegroundService::class.java)
                    stopService(intent)
                }
            })
    }
}