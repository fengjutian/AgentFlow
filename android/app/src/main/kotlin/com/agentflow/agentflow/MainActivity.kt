package com.agentflow.agentflow

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter engine and attaches the Kotlin runtime bridge.
 *
 * [RuntimeManager] serves the `agentflow/runtime` MethodChannel that the Dart
 * `BridgeRuntime` talks to, giving the agent on-device shell and filesystem
 * access without the Agent Core knowing anything about Android.
 */
class MainActivity : FlutterActivity() {

    private var runtimeManager: RuntimeManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        runtimeManager = RuntimeManager(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        ).also { it.attach() }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        runtimeManager?.detach()
        runtimeManager = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
