package com.growthrecord.shiyu.widgets

import android.content.Context

/** 未编辑过的组件沿用原有宽窄布局，保存后固定使用所选组合。 */
internal data class WidgetMetricGroup(val metrics: List<WidgetMetric>, val automatic: Boolean) {
    fun displayed(wide: Boolean): List<WidgetMetric> {
        if (!automatic || !wide) return metrics
        val last = if (metrics.first() == WidgetMetric.LIFE) WidgetMetric.LIFE else WidgetMetric.RETIREMENT
        return listOf(WidgetMetric.WORK, WidgetMetric.HOLIDAY, WidgetMetric.PAYDAY, last)
    }
}

/** 组合按系统分配的组件 ID 保存，删除和备份恢复时同步更新。 */
internal object WidgetSelection {
    const val limit = 4
    private const val prefix = "group:"

    private fun preferences(context: Context) =
        context.getSharedPreferences("widget_selection", Context.MODE_PRIVATE)

    fun read(context: Context, id: Int): WidgetMetricGroup {
        val value = preferences(context).getString(id.toString(), null)
        if (value?.startsWith(prefix) == true) {
            val fields = value.removePrefix(prefix).split(",").toSet()
            val metrics = WidgetMetric.entries.filter { it.field in fields }.take(limit)
            if (metrics.isNotEmpty()) return WidgetMetricGroup(metrics, automatic = false)
        }
        return WidgetMetricGroup(listOf(WidgetMetric.read(value)), automatic = true)
    }

    fun write(context: Context, id: Int, metrics: List<WidgetMetric>): Boolean {
        if (metrics.size !in 1..limit || metrics.distinct().size != metrics.size) return false
        val value = metrics.joinToString(separator = ",", prefix = prefix) { it.field }
        return preferences(context).edit().putString(id.toString(), value).commit()
    }

    fun remove(context: Context, ids: IntArray) {
        val edit = preferences(context).edit()
        for (id in ids) edit.remove(id.toString())
        edit.apply()
    }

    fun restore(context: Context, oldIds: IntArray, newIds: IntArray) {
        val prefs = preferences(context)
        val previous = oldIds.map { prefs.getString(it.toString(), null) }
        val edit = prefs.edit()
        for (id in oldIds) edit.remove(id.toString())
        for ((index, id) in newIds.withIndex()) {
            edit.putString(id.toString(), previous.getOrNull(index))
        }
        edit.apply()
    }
}
