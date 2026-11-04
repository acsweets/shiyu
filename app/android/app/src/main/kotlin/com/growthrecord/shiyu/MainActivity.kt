package com.growthrecord.shiyu

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.growthrecord.shiyu.core.bridgeProbe
import com.growthrecord.shiyu.widgets.WidgetChannel

class MainActivity : FlutterActivity() {
    // 仅在调试构建中暴露原生 UniFFI 验证，不参与正常业务计算流程。
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
        if (!BuildConfig.DEBUG) return
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shiyu/m0_probe")
            .setMethodCallHandler { call, result ->
                if (call.method == "probe") {
                    try {
                        result.success(bridgeProbe(41u))
                    } catch (error: Throwable) {
                        result.error("native_probe_failed", error.javaClass.simpleName, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
