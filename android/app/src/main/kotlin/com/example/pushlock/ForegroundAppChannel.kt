package com.example.pushlock

import io.flutter.plugin.common.EventChannel

object ForegroundAppChannel {

    private var eventSink: EventChannel.EventSink? = null

    fun startListening(sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun stopListening() {
        eventSink = null
    }

    fun send(packageName: String) {
        eventSink?.success(packageName)
    }
}
