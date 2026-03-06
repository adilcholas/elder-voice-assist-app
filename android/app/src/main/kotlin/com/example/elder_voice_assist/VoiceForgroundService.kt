package com.example.app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import io.flutter.plugin.common.EventChannel

class VoiceForegroundService : Service() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    fun detectHelpKeyword() {
        eventSink?.success("emergency_detected")
    }
}