package com.growthrecord.shiyu.widgets

import android.content.Context
import android.content.res.Configuration
import com.growthrecord.shiyu.R
import org.json.JSONObject
import java.text.NumberFormat
import java.util.Locale

internal enum class WidgetMetric(val field: String, val label: Int) {
    WORK("work", R.string.widget_work),
    HOLIDAY("holiday", R.string.widget_holiday),
    PAYDAY("payday", R.string.widget_payday),
    RETIREMENT("retirement", R.string.widget_heading);

    companion object {
        fun read(name: String?): WidgetMetric = entries.firstOrNull { it.field == name } ?: RETIREMENT
    }
}

internal data class WidgetLine(val title: String, val value: String)

/** 只格式化 Rust 产生的秒数和十进制字符串。 */
internal class WidgetMetrics(context: Context, locale: String?, private val snapshot: JSONObject?) {
    val text: Context = if (locale == null) context else context.createConfigurationContext(
        Configuration(context.resources.configuration).apply { setLocale(Locale.forLanguageTag(locale)) },
    )

    fun countdown(metric: WidgetMetric): WidgetLine {
        val item = snapshot?.optJSONObject(metric.field)
        val seconds = item?.optLong("remaining_seconds")?.coerceAtLeast(0) ?: 0L
        val label = when (item?.optString("target_kind")) {
            "work_start" -> R.string.widget_work_start
            "work_end" -> R.string.widget_work_end
            "lunch_end" -> R.string.widget_lunch_end
            else -> if (item?.optString("status") == "on_holiday") R.string.widget_holiday_end else metric.label
        }
        val value = when (item?.optString("status")) {
            "retired" -> text.getString(R.string.widget_retired)
            "today" -> text.getString(R.string.widget_payday_today)
            "unconfigured" -> text.getString(R.string.widget_not_configured)
            null -> text.getString(R.string.widget_error)
            else -> if (item?.isNull("target_millis") != false) text.getString(R.string.widget_unavailable)
                else duration(seconds)
        }
        return WidgetLine(text.getString(label), value)
    }

    fun earnings(month: Boolean): WidgetLine {
        val salary = snapshot?.optJSONObject("salary")
        val field = if (month) "month_earned" else "today_earned"
        val label = if (month) R.string.widget_month_earned else R.string.widget_today_earned
        val value = when {
            salary == null -> text.getString(R.string.widget_error)
            salary.optBoolean("hidden") -> "****"
            salary.isNull(field) -> text.getString(R.string.widget_not_configured)
            else -> "${salary.getString(field)} ${salary.optString("currency")}".trim()
        }
        return WidgetLine(text.getString(label), value)
    }

    private fun duration(seconds: Long): String {
        val clock = String.format(Locale.ROOT, "%02d:%02d:%02d",
            seconds / 3_600 % 24, seconds / 60 % 60, seconds % 60)
        if (seconds < 86_400) return clock
        val days = NumberFormat.getIntegerInstance(text.resources.configuration.locales[0])
            .format(seconds / 86_400)
        return text.getString(R.string.widget_duration, days, clock)
    }
}
