package com.growthrecord.shiyu.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.growthrecord.shiyu.MainActivity
import com.growthrecord.shiyu.R
import com.growthrecord.shiyu.core.computeSnapshot
import com.growthrecord.shiyu.core.defaultSettings
import org.json.JSONObject
import java.text.DateFormat
import java.text.NumberFormat
import java.util.Date

// 组件直接调用 UniFFI，不创建 Flutter 引擎；仅实现本节点退休倒计时切片。
class RetirementWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, render(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in listOf(REFRESH, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_BOOT_COMPLETED)) {
            refresh(context)
        }
    }

    companion object {
        // 仅由本应用创建的 PendingIntent 或系统广播触发，不开放外部控制。
        const val REFRESH = "com.growthrecord.shiyu.REFRESH_WIDGET"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, RetirementWidget::class.java))
            for (id in ids) manager.updateAppWidget(id, render(context))
        }

        private fun render(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.retirement_widget)
            val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root, open)
            val reload = PendingIntent.getBroadcast(context, 1, Intent(context, RetirementWidget::class.java).setAction(REFRESH), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_refresh, reload)
            try {
                val json = WidgetSettings.read(context) ?: defaultSettings()
                val reply = JSONObject(computeSnapshot(json, "{}", System.currentTimeMillis()))
                check(reply.getBoolean("ok"))
                val snapshot = reply.getJSONObject("snapshot")
                val retirement = snapshot.getJSONObject("retirement")
                val value = when (retirement.getString("status")) {
                    "active" -> context.getString(R.string.widget_days, NumberFormat.getIntegerInstance().format(retirement.getLong("remaining_days")))
                    "retired" -> context.getString(R.string.widget_retired)
                    else -> context.getString(R.string.widget_setup)
                }
                views.setTextViewText(R.id.widget_value, value)
                views.setTextViewText(R.id.widget_zone, snapshot.getString("time_zone"))
                views.setTextViewText(R.id.widget_updated, context.getString(R.string.widget_updated, DateFormat.getTimeInstance(DateFormat.SHORT).format(Date())))
            } catch (_: Throwable) {
                views.setTextViewText(R.id.widget_value, context.getString(R.string.widget_error))
                views.setTextViewText(R.id.widget_updated, "")
            }
            return views
        }
    }
}
