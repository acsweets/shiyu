package com.growthrecord.shiyu.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.growthrecord.shiyu.MainActivity
import com.growthrecord.shiyu.R
import org.json.JSONObject
import java.text.NumberFormat
import java.util.Locale

// 组件直接调用 UniFFI，无需运行 Flutter 或保留应用前台进程。
class RetirementWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        if (ids.isNotEmpty()) manager.updateAppWidget(ids, render(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_BOOT_COMPLETED ->
                refresh(context)
        }
    }

    companion object {
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, RetirementWidget::class.java))
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, render(context))
        }

        private fun render(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.retirement_widget)
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            val appearance = WidgetAppearance.read(context)
            views.setInt(R.id.widget_card, "setBackgroundResource", appearance.palette.background)
            views.setViewVisibility(R.id.widget_heading, if (appearance.titleVisible) View.VISIBLE else View.GONE)
            views.setTextViewTextSize(R.id.widget_heading, TypedValue.COMPLEX_UNIT_SP, appearance.titleSize)
            views.setTextColor(R.id.widget_heading, appearance.palette.ink)
            views.setTextColor(R.id.widget_value, appearance.palette.ink)
            views.setTextViewText(R.id.widget_heading, context.getString(R.string.widget_heading))
            views.setTextViewText(R.id.widget_value, countdown(context))
            return views
        }

        private fun countdown(context: Context): String {
            try {
                val reply = JSONObject(WidgetInputs.read(context).snapshot(System.currentTimeMillis()))
                check(reply.getBoolean("ok"))
                val retirement = reply.getJSONObject("snapshot").getJSONObject("retirement")
                return when (retirement.getString("status")) {
                    "active" -> formatDuration(context, retirement.getLong("remaining_seconds"))
                    "retired" -> context.getString(R.string.widget_retired)
                    else -> context.getString(R.string.widget_setup)
                }
            } catch (_: Throwable) {
                return context.getString(R.string.widget_error)
            }
        }

        // 只格式化 Rust 已计算的非负秒数。组件按系统调度更新这份快照。
        private fun formatDuration(context: Context, seconds: Long): String {
            val locale = context.resources.configuration.locales[0]
            val days = NumberFormat.getIntegerInstance(locale).format(seconds / 86_400)
            val clock = String.format(Locale.ROOT, "%02d:%02d:%02d",
                seconds / 3_600 % 24, seconds / 60 % 60, seconds % 60)
            return context.getString(R.string.widget_duration, days, clock)
        }
    }
}
