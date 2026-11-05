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

    fun write(context: Context, json: String) = write(context, "settings.json", json)

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
