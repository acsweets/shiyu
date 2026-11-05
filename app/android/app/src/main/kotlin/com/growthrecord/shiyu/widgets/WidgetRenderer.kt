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

/** 两种组件共用猫猫、整卡底色和数字排版。 */
internal class WidgetRenderer(
    private val context: Context,
    private val metrics: WidgetMetrics,
    private val appearance: WidgetAppearance,
) {
    fun countdown(id: Int, wide: Boolean, elapsed: Long?): RemoteViews {
        val action = Intent(context, WidgetConfigurationActivity::class.java)
            .setAction(WidgetConfigurationActivity.editAction)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
        val views = base(action, id, elapsed)
        if (wide) {
            showPrimary(views, null)
            WidgetMetric.entries.map(metrics::countdown).chunked(2).forEach {
                views.addView(R.id.widget_extra, row(it[0], it[1]))
            }
        } else {
            showPrimary(views, metrics.countdown(WidgetSelection.read(context, id)))
        }
        return views
    }

    fun salary(wide: Boolean, elapsed: Long?): RemoteViews {
        val views = base(Intent(context, MainActivity::class.java), 0, elapsed)
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

    private fun base(action: Intent, id: Int, elapsed: Long?): RemoteViews =
        RemoteViews(context.packageName, R.layout.retirement_widget).apply {
            val open = PendingIntent.getActivity(
                context, id, action, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, open)
            setInt(R.id.widget_card, "setBackgroundResource", appearance.palette.background)
            removeAllViews(R.id.widget_extra)
            setViewVisibility(R.id.widget_updated, if (elapsed == null) View.GONE else View.VISIBLE)
            if (elapsed != null) {
                setTextColor(R.id.widget_updated, appearance.palette.ink)
                setChronometer(R.id.widget_updated, elapsed, metrics.text.getString(R.string.widget_updated), true)
            }
        }

    private fun showPrimary(views: RemoteViews, line: WidgetLine?) {
        if (line == null) {
            views.setViewVisibility(R.id.widget_heading, View.GONE)
            views.setViewVisibility(R.id.widget_value, View.GONE)
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
        views.setViewVisibility(heading, if (alwaysLabel || appearance.titleVisible) View.VISIBLE else View.GONE)
        views.setViewVisibility(value, View.VISIBLE)
        views.setTextViewTextSize(heading, TypedValue.COMPLEX_UNIT_SP, size)
        views.setTextColor(heading, appearance.palette.ink)
        views.setTextColor(value, appearance.palette.ink)
        views.setTextViewText(heading, line.title)
        views.setTextViewText(value, line.value)
        views.setContentDescription(value, "${line.title} ${line.value}")
    }
}
