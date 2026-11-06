package com.growthrecord.shiyu.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.growthrecord.shiyu.R

/** 选择当前实例的倒计时组合，保存后刷新系统桌面。 */
class WidgetConfigurationActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
        setResult(RESULT_CANCELED, result)
        val provider = AppWidgetManager.getInstance(this).getAppWidgetInfo(id)?.provider
        if (provider != ComponentName(this, RetirementWidget::class.java)) {
            finish()
            return
        }
        val locale = runCatching { WidgetInputs.read(this).locale }.getOrNull()
        val text = WidgetMetrics(this, locale, null).text
        val accent = Color.rgb(141, 75, 49)
        val body = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }
        body.addView(TextView(this).apply {
            textSize = 24f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.rgb(49, 38, 34))
            this.text = text.getString(R.string.widget_choose_metric)
        })
        body.addView(TextView(this).apply {
            textSize = 14f
            setTextColor(Color.rgb(109, 91, 81))
            this.text = text.getString(R.string.widget_choose_metric_limit)
        })
        val options = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        val current = WidgetSelection.read(this, id)
        val buttons = WidgetMetric.entries.associateWith { metric ->
            CheckBox(this).apply {
                this.id = metric.ordinal + 1
                this.text = text.getString(metric.label)
                minHeight = dp(48)
                buttonTintList = ColorStateList.valueOf(accent)
                isChecked = metric in current.metrics
                options.addView(this)
            }
        }
        body.addView(options)
        val save = Button(this).apply {
            this.text = text.getString(R.string.widget_save_metric)
            setOnClickListener {
                val selected = buttons.filterValues { it.isChecked }.keys.toList()
                if (WidgetSelection.write(this@WidgetConfigurationActivity, id, selected)) {
                    WidgetUpdates.refresh(this@WidgetConfigurationActivity)
                    setResult(RESULT_OK, result)
                    finish()
                }
            }
        }
        fun updateSelection() {
            val count = buttons.values.count { it.isChecked }
            save.isEnabled = count > 0
            for (button in buttons.values) {
                button.isEnabled = button.isChecked || count < WidgetSelection.limit
            }
        }
        buttons.values.forEach { it.setOnCheckedChangeListener { _, _ -> updateSelection() } }
        updateSelection()
        body.addView(save)
        body.addView(Button(this).apply {
            this.text = text.getString(android.R.string.cancel)
            setOnClickListener { finish() }
        })
        setContentView(ScrollView(this).apply {
            setBackgroundColor(Color.WHITE)
            addView(body)
            setOnApplyWindowInsetsListener { view, insets ->
                @Suppress("DEPRECATION")
                view.setPadding(0, insets.systemWindowInsetTop, 0, insets.systemWindowInsetBottom)
                insets
            }
        })
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    companion object {
        const val editAction = "com.growthrecord.shiyu.widget.EDIT"
    }
}
