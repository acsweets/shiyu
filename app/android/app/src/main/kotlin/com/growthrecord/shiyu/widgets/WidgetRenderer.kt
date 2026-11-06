package com.growthrecord.shiyu.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.growthrecord.shiyu.MainActivity
import com.growthrecord.shiyu.R
import kotlin.math.roundToInt

/** 两种组件共用猫猫、整卡底色和数字排版。 */
internal class WidgetRenderer(
    private val context: Context,
    private val metrics: WidgetMetrics,
    private val appearance: WidgetAppearance,
    private val wallNow: Long,
    private val elapsedNow: Long,
) {
    fun countdown(id: Int, wide: Boolean): RemoteViews {
        val action = Intent(context, WidgetConfigurationActivity::class.java)
            .setAction(WidgetConfigurationActivity.editAction)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
        val views = base(action, id)
        val selected = WidgetSelection.read(context, id).displayed(wide)
        if (selected.size == 1) {
            showPrimary(views, metrics.countdown(selected.single()))
        } else {
            showPrimary(views, null)
            val columns = if (wide || selected.size > 2) 2 else 1
            selected.map(metrics::countdown).chunked(columns).forEach {
                views.addView(R.id.widget_extra, row(it.first(), it.getOrNull(1)))
            }
        }
        return views
    }

    fun salary(wide: Boolean): RemoteViews {
        val views = base(Intent(context, MainActivity::class.java), 0, compactSalary = !wide)
        val refresh = Intent(context, RetirementWidget::class.java)
            .setAction(WidgetUpdates.action)
            .addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
        views.setViewVisibility(R.id.widget_refresh, View.VISIBLE)
        views.setTextColor(R.id.widget_refresh_icon, appearance.palette.ink)
        views.setContentDescription(R.id.widget_refresh, metrics.text.getString(R.string.widget_refresh_earnings))
        views.setOnClickPendingIntent(
            R.id.widget_refresh,
            PendingIntent.getBroadcast(context, 1, refresh, PendingIntent.FLAG_IMMUTABLE),
        )
        showPrimary(views, null)
        val today = metrics.earnings(false)
        val month = metrics.earnings(true)
        if (wide) {
            views.addView(R.id.widget_extra, row(today, month, alwaysLabel = true))
        } else {
            views.addView(R.id.widget_extra, row(today, alwaysLabel = true))
            views.addView(R.id.widget_extra, row(month, alwaysLabel = true))
        }
        return views
    }

    private fun base(action: Intent, id: Int, compactSalary: Boolean = false): RemoteViews =
        RemoteViews(context.packageName, R.layout.retirement_widget).apply {
            val open = PendingIntent.getActivity(
                context, id, action, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, open)
            setViewVisibility(R.id.widget_refresh, View.GONE)
            // 紧凑薪资卡给按钮和两行金额让出高度，猫猫仍贴住卡片上沿。
            val top = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, if (compactSalary) 32f else 46f, context.resources.displayMetrics,
            ).roundToInt()
            setViewPadding(R.id.widget_card_position, 0, top, 0, 0)
            setViewVisibility(R.id.widget_cat_sticker, if (compactSalary) View.GONE else View.VISIBLE)
            setViewVisibility(R.id.widget_cat_compact, if (compactSalary) View.VISIBLE else View.GONE)
            setInt(R.id.widget_card, "setBackgroundResource", appearance.palette.background)
            removeAllViews(R.id.widget_extra)
        }

    private fun showPrimary(views: RemoteViews, line: WidgetLine?) {
        if (line == null) {
            views.setViewVisibility(R.id.widget_heading, View.GONE)
            views.setViewVisibility(R.id.widget_value, View.GONE)
            views.setChronometer(R.id.widget_value, elapsedNow, null, false)
        } else {
            setLine(views, R.id.widget_heading, R.id.widget_value, line, appearance.titleSize)
        }
    }

    private fun row(first: WidgetLine, second: WidgetLine? = null, alwaysLabel: Boolean = false): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_metric_row).also {
            val titleSize = appearance.titleSize.coerceAtMost(14f)
            setLine(it, R.id.widget_first_title, R.id.widget_first_value, first, titleSize, alwaysLabel)
            if (second == null) {
                it.setViewVisibility(R.id.widget_second_cell, View.GONE)
            } else {
                setLine(it, R.id.widget_second_title, R.id.widget_second_value, second, titleSize, alwaysLabel)
            }
        }

    private fun setLine(
        views: RemoteViews, heading: Int, value: Int, line: WidgetLine, size: Float, alwaysLabel: Boolean = false,
    ) {
        val showTitle = line.titleVisible && (alwaysLabel || appearance.titleVisible)
        views.setViewVisibility(heading, if (showTitle) View.VISIBLE else View.GONE)
        views.setViewVisibility(value, View.VISIBLE)
        views.setTextViewTextSize(heading, TypedValue.COMPLEX_UNIT_SP, size)
        views.setTextColor(heading, appearance.palette.ink)
        views.setTextColor(value, appearance.palette.ink)
        views.setTextViewText(heading, line.title)
        val target = line.targetMillis
        if (target != null && target > wallNow) {
            // 启动器按秒绘制，应用进程只在业务状态或目标变化时刷新。
            val remaining = target - wallNow
            // 给日数切换预留系统调度时间，并避免长秒数降低计时精度。
            val days = (remaining - rolloverBuffer).coerceAtLeast(0) / dayMillis
            val base = elapsedNow + remaining - days * dayMillis
            views.setChronometerCountDown(value, true)
            views.setChronometer(value, base, metrics.countdownFormat(days), true)
            views.setContentDescription(value, null)
        } else {
            views.setChronometer(value, elapsedNow, null, false)
            views.setTextViewText(value, line.value)
            views.setContentDescription(value, "${line.title} ${line.value}")
        }
    }

    private companion object {
        const val dayMillis = 86_400_000L
        const val rolloverBuffer = 7_200_000L
    }
}
