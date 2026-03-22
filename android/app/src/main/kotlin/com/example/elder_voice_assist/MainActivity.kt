package com.example.elder_voice_assist

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import com.example.elder_voice_assist.VoiceForegroundService

class MainActivity: FlutterActivity() {

    private val CHANNEL = "voice_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val intent = Intent(this@MainActivity, VoiceForegroundService::class.java)
                    startService(intent)
                }

                override fun onCancel(arguments: Any?) {
                    val intent = Intent(this@MainActivity, VoiceForegroundService::class.java)
                    stopService(intent)
                }
            })
    }
}