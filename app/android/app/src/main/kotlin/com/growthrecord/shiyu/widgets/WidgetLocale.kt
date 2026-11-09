package com.growthrecord.shiyu.widgets

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/** 用应用设置选择卡片及配置页的资源，不修改手机或桌面启动器语言。 */
internal object WidgetLocale {
    private val supported = setOf("zh", "zh-Hant", "en", "ja", "ko", "es", "de", "fr")

    fun resources(context: Context, preferred: String?): Context {
        val configuration = context.resources.configuration
        val tag = preferred?.takeIf(supported::contains) ?: systemTag(configuration)
        val locale = Locale.forLanguageTag(if (tag == "zh") "zh-Hans" else tag)
        return context.createConfigurationContext(Configuration(configuration).apply { setLocale(locale) })
    }

    private fun systemTag(configuration: Configuration): String {
        val locales = configuration.locales
        for (index in 0 until locales.size()) {
            val locale = locales[index]
            if (locale.language == "zh") {
                return if (locale.script == "Hant" ||
                    (locale.script.isEmpty() && locale.country in setOf("TW", "HK", "MO"))
                ) "zh-Hant" else "zh"
            }
            if (locale.language in supported) return locale.language
        }
        // 与 ShiyuApp 的首个受支持语言一致。
        return "zh"
    }
}
