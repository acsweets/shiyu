package com.growthrecord.shiyu.widgets

import android.content.Context
import android.util.AtomicFile
import java.io.File
import java.io.FileNotFoundException

// 应用与原生组件共享同一私有文件，原子写入不会暴露半份 JSON。
object WidgetSettings {
    private fun file(context: Context, name: String): AtomicFile {
        val directory = File(context.filesDir, "shiyu")
        check(directory.exists() || directory.mkdirs())
        return AtomicFile(File(directory, name))
    }

    fun read(context: Context): String? = read(context, "settings.json")

    fun write(context: Context, json: String) {
        write(context, "settings.json", json)
        runCatching { write(context, "settings.last-good.json", json) }
    }

    fun readLastGood(context: Context): String? = read(context, "settings.last-good.json")

    fun readCalendar(context: Context, region: String): String? = calendar(context, region)?.calendar

    fun writeCalendar(context: Context, raw: String): Boolean {
        val next = WidgetCalendar.parse(raw)
        val name = "calendar-${next.region}.json"
        if ((calendar(context, next.region)?.version ?: 0L) >= next.version) return false
        write(context, name, raw)
        runCatching { write(context, "$name.bak", raw) }
        return true
    }

    private fun calendar(context: Context, region: String): WidgetCalendar? {
        if (region !in WidgetCalendar.regions) return null
        val name = "calendar-$region.json"
        return readCalendarFile(context, name, region) ?: readCalendarFile(context, "$name.bak", region)
    }

    private fun readCalendarFile(context: Context, name: String, region: String): WidgetCalendar? =
        runCatching { read(context, name)?.let(WidgetCalendar::parse)?.takeIf { it.region == region } }.getOrNull()

    // 外观单独保存，避免把显示选项写进 Rust 设置契约。
    fun readAppearance(context: Context): String? = read(context, "widget_appearance.json")

    fun writeAppearance(context: Context, json: String) =
        write(context, "widget_appearance.json", json)

    private fun read(context: Context, name: String): String? {
        val data = file(context, name)
        val stream = try { data.openRead() } catch (_: FileNotFoundException) { return null }
        return stream.use {
            check(it.channel.size() <= 131072)
            it.bufferedReader().readText()
        }
    }

    private fun write(context: Context, name: String, json: String) {
        check(json.toByteArray(Charsets.UTF_8).size <= 131072)
        val data = file(context, name)
        val stream = data.startWrite()
        try {
            stream.write(json.toByteArray(Charsets.UTF_8))
            data.finishWrite(stream)
        } catch (error: Throwable) {
            data.failWrite(stream)
            throw error
        }
    }
}
