package com.growthrecord.shiyu

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.growthrecord.shiyu.core.bridgeProbe

// 调试专用组件，直接经 UniFFI 调用 Rust，不需要启动 Flutter 引擎。
class M0ProbeWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (widgetId in ids) {
            val view = RemoteViews(context.packageName, R.layout.m0_probe_widget)
            val text = try {
                bridgeProbe(41u)
            } catch (error: Throwable) {
                "Rust probe failed: ${error.javaClass.simpleName}"
            }
            view.setTextViewText(R.id.probe_text, text)
            manager.updateAppWidget(widgetId, view)
        }
    }
}
