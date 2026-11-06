package com.growthrecord.shiyu.widgets

import android.content.Context
import android.graphics.Color
import com.growthrecord.shiyu.R
import org.json.JSONObject

// 标题选项与整张卡片的颜色由主应用保存，组件进程独立读取。
internal data class WidgetAppearance(
    val palette: Palette = Palette.MACARON,
    val titleVisible: Boolean = true,
    val titleSize: Float = 16f,
) {
    enum class Palette(val background: Int, val ink: Int) {
        MACARON(R.drawable.retirement_widget_background, Color.rgb(69, 54, 59)),
        MACARON_GLASS(R.drawable.retirement_widget_macaron_glass, Color.rgb(56, 42, 54)),
        COOL(R.drawable.retirement_widget_cool, Color.rgb(240, 245, 255)),
        SUNSET(R.drawable.retirement_widget_sunset, Color.rgb(71, 43, 41)),
    }

    companion object {
        fun read(context: Context): WidgetAppearance {
            return try {
                val raw = WidgetSettings.readAppearance(context) ?: return WidgetAppearance()
                val json = JSONObject(raw)
                val palette = when (json.optString("palette")) {
                    "macaronGlass" -> Palette.MACARON_GLASS
                    "cool" -> Palette.COOL
                    "sunset" -> Palette.SUNSET
                    else -> Palette.MACARON
                }
                val size = json.optDouble("titleSize", 16.0)
                WidgetAppearance(
                    palette,
                    json.optBoolean("titleVisible", true),
                    if (size.isFinite()) size.coerceIn(10.0, 24.0).toFloat() else 16f,
                )
            } catch (_: Exception) {
                WidgetAppearance()
            }
        }
    }
}
