package com.growthrecord.shiyu.widgets

import android.content.Context
import com.growthrecord.shiyu.core.computeSnapshot
import com.growthrecord.shiyu.core.defaultSettings
import com.growthrecord.shiyu.core.validateSettings
import org.json.JSONObject
import java.security.MessageDigest

/** 组件按主设置的地区选择日历，并在损坏回退时强制遮蔽金额。 */
internal class WidgetInputs private constructor(
    private val settings: JSONObject,
    private val calendar: String,
    val recovery: Boolean,
) {
    val locale: String? get() = settings.optJSONObject("display")?.optString("locale")?.ifEmpty { null }

    fun snapshot(now: Long): String {
        val raw = settings.toString()
        val result = computeSnapshot(raw, calendar, now)
        return if (calendar == "{}" || JSONObject(result).optBoolean("ok")) {
            result
        } else {
            computeSnapshot(raw, "{}", now)
        }
    }

    companion object {
        fun read(context: Context): WidgetInputs {
            val primary = runCatching { checked(WidgetSettings.read(context)) }.getOrNull()
            val settings = primary ?: runCatching {
                checked(WidgetSettings.readLastGood(context))
            }.getOrNull() ?: JSONObject(defaultSettings())
            if (primary == null) settings.put("hide_amount", true)
            val calendar = WidgetSettings.readCalendar(context, settings.optString("region"))
            return WidgetInputs(settings, calendar ?: "{}", recovery = primary == null)
        }

        private fun checked(raw: String?): JSONObject? {
            if (raw == null) return null
            val candidate = JSONObject(raw)
            if (candidate.optInt("schema_version", -1) == 0) {
                candidate.put("schema_version", 1)
            }
            val reply = JSONObject(validateSettings(candidate.toString()))
            return reply.optJSONObject("settings").takeIf { reply.optBoolean("ok") }
        }
    }
}

internal data class WidgetCalendar(val region: String, val version: Long, val calendar: String) {
    companion object {
        val regions = setOf("CN", "US", "JP", "KR", "HK", "TW")

        fun parse(raw: String): WidgetCalendar {
            val data = JSONObject(raw)
            val region = data.getString("region")
            val version = data.getLong("version")
            val calendar = data.getString("calendar")
            val core = JSONObject(calendar)
            check(data.getInt("schema_version") == 1 && region in regions && version > 0L)
            check(core.getInt("schema_version") == 1 && core.getString("region") == region)
            val hash = MessageDigest.getInstance("SHA-256").digest(calendar.toByteArray(Charsets.UTF_8))
                .joinToString("") { "%02x".format(it.toInt() and 0xff) }
            check(hash == data.getString("sha256"))
            return WidgetCalendar(region, version, calendar)
        }
    }
}
