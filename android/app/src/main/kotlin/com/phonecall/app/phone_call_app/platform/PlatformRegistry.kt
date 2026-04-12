package com.phonecall.app.phone_call_app.platform

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine

object PlatformRegistry {
    private var initialized = false

    fun initialize(application: Application, flutterEngine: FlutterEngine) {
        if (initialized) {
            return
        }
        initialized = true

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val callStateApi = CallStateFlutterApi(messenger)
        CallCoordinator.initialize(callStateApi)

        DialerPlatformApi.setUp(messenger, DialerPlatformHandler(application))
        ContactsPlatformApi.setUp(messenger, ContactsPlatformHandler(application))
        RecentsPlatformApi.setUp(messenger, RecentsPlatformHandler(application))
    }
}
