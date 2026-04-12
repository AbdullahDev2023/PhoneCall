package com.phonecall.app.phone_call_app

import com.phonecall.app.phone_call_app.platform.ActivityProvider
import com.phonecall.app.phone_call_app.platform.PlatformRegistry
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class PhoneCallApplication : FlutterApplication() {
    companion object {
        const val ENGINE_ID = "phone_call_engine"
    }

    override fun onCreate() {
        super.onCreate()
        ActivityProvider.register(this)

        val engine = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(engine)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)

        PlatformRegistry.initialize(this, engine)
    }
}
