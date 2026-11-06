package com.growthrecord.shiyu.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews
import org.json.JSONObject

/** 有组件时才请求系统下次刷新，两类组件共用一次快照和一个非唤醒闹钟。 */
internal object WidgetUpdates {
    const val action = "com.growthrecord.shiyu.widget.REFRESH"

    fun refresh(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val countdowns = manager.getAppWidgetIds(ComponentName(context, RetirementWidget::class.java))
        val salaries = manager.getAppWidgetIds(ComponentName(context, SalaryWidget::class.java))
        if (countdowns.isEmpty() && salaries.isEmpty()) {
            schedule(context, null)
            return
        }
        val now = System.currentTimeMillis()
        val elapsed = SystemClock.elapsedRealtime()
        val input = runCatching { WidgetInputs.read(context) }.getOrNull()
        val snapshot = runCatching {
            val reply = input?.let { JSONObject(it.snapshot(now)) }
            reply?.optJSONObject("snapshot").takeIf { reply?.optBoolean("ok") == true }
        }.getOrNull()
        val metrics = WidgetMetrics(context, input?.locale, snapshot)
        val renderer = WidgetRenderer(context, metrics, WidgetAppearance.read(context), now, elapsed)
        for (id in countdowns) {
            val options = manager.getAppWidgetOptions(id)
            val small = renderer.countdown(id, false)
            val large = renderer.countdown(id, true)
            manager.updateAppWidget(id, responsive(options, small, large, 290, 128))
        }
        for (id in salaries) {
            val options = manager.getAppWidgetOptions(id)
            val small = renderer.salary(false)
            val large = renderer.salary(true)
            manager.updateAppWidget(id, responsive(options, small, large, 260, 105))
        }
        val interval = if (salaries.isNotEmpty()) 60_000L else 900_000L
        val boundary = snapshot?.optLong("next_change_at_millis", now + interval) ?: now + interval
        schedule(context, (boundary - now).coerceIn(1_000L, interval))
    }

    private fun responsive(
        options: Bundle, small: RemoteViews, large: RemoteViews, width: Int, height: Int,
    ): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(mapOf(SizeF(100f, 90f) to small, SizeF(width.toFloat(), height.toFloat()) to large))
        }
        val portrait = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) >= width &&
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) >= height
        val landscape = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH) >= width &&
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) >= height
        return RemoteViews(if (landscape) large else small, if (portrait) large else small)
    }

    private fun schedule(context: Context, delay: Long?) {
        val alarm = context.getSystemService(AlarmManager::class.java)
        val intent = PendingIntent.getBroadcast(
            context, 0, Intent(context, RetirementWidget::class.java).setAction(action),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        if (delay == null) {
            alarm.cancel(intent)
        } else {
            alarm.set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + delay, intent)
        }
    }
}
