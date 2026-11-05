package com.growthrecord.shiyu.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle

/** 保留旧组件的系统标识，已添加的退休组件会自动升级为倒计时组件。 */
class RetirementWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        WidgetUpdates.refresh(context)

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
    ) = WidgetUpdates.refresh(context)

    override fun onDeleted(context: Context, ids: IntArray) {
        WidgetSelection.remove(context, ids)
        WidgetUpdates.refresh(context)
    }

    override fun onRestored(context: Context, oldIds: IntArray, newIds: IntArray) =
        WidgetSelection.restore(context, oldIds, newIds)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED,
            WidgetUpdates.action -> WidgetUpdates.refresh(context)
        }
    }
}

class SalaryWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        WidgetUpdates.refresh(context)

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
    ) = WidgetUpdates.refresh(context)

    override fun onDeleted(context: Context, ids: IntArray) = WidgetUpdates.refresh(context)
}
