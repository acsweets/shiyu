package com.growthrecord.shiyu.widgets

import android.content.Context

/** 主指标按系统分配的组件 ID 保存，删除和备份恢复时同步更新。 */
internal object WidgetSelection {
    private fun preferences(context: Context) =
        context.getSharedPreferences("widget_selection", Context.MODE_PRIVATE)

    fun read(context: Context, id: Int): WidgetMetric =
        WidgetMetric.read(preferences(context).getString(id.toString(), null))

    fun write(context: Context, id: Int, metric: WidgetMetric): Boolean =
        preferences(context).edit().putString(id.toString(), metric.field).commit()

    fun remove(context: Context, ids: IntArray) {
        val edit = preferences(context).edit()
        for (id in ids) edit.remove(id.toString())
        edit.apply()
    }

    fun restore(context: Context, oldIds: IntArray, newIds: IntArray) {
        val previous = oldIds.map { read(context, it) }
        val edit = preferences(context).edit()
        for (id in oldIds) edit.remove(id.toString())
        for ((index, id) in newIds.withIndex()) {
            if (index < previous.size) edit.putString(id.toString(), previous[index].field)
        }
        edit.apply()
    }
}
