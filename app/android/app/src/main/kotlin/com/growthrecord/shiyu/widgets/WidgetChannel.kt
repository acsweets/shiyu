package com.growthrecord.shiyu.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import com.growthrecord.shiyu.core.validateSettings
import com.growthrecord.shiyu.core.computeSnapshot
import com.growthrecord.shiyu.core.defaultSettings
import org.json.JSONObject

object WidgetChannel {
    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "shiyu/widgets").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "readSettings" -> result.success(WidgetSettings.read(context))
                    "writeSettings" -> {
                        val raw = call.arguments as String
                        val checked = JSONObject(validateSettings(raw))
                        check(checked.getBoolean("ok"))
                        WidgetSettings.write(context, checked.getJSONObject("settings").toString())
                        result.success(null)
                    }
                    "readAppearance" -> result.success(WidgetSettings.readAppearance(context))
                    "writeAppearance" -> {
                        val json = JSONObject(call.arguments as String)
                        WidgetSettings.writeAppearance(context, json.toString())
                        RetirementWidget.refresh(context)
                        result.success(null)
                    }
                    "refresh" -> { RetirementWidget.refresh(context); result.success(null) }
                    "pin" -> {
                        val manager = AppWidgetManager.getInstance(context)
                        val pinned = Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported &&
                            manager.requestPinAppWidget(ComponentName(context, RetirementWidget::class.java), null, null)
                        result.success(pinned)
                    }
                    "snapshot" -> {
                        val now = (call.arguments as Number).toLong()
                        result.success(computeSnapshot(WidgetSettings.read(context) ?: defaultSettings(), "{}", now))
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Throwable) {
                result.error("widget_operation_failed", error.javaClass.simpleName, null)
            }
        }
    }
}
