package com.growthrecord.shiyu.widgets

import android.content.Context
import android.util.AtomicFile
import java.io.File
import java.io.FileNotFoundException

// 应用与原生组件共享同一私有文件，原子写入不会暴露半份 JSON。
object WidgetSettings {
    private fun file(context: Context): AtomicFile {
        val directory = File(context.filesDir, "shiyu")
        check(directory.exists() || directory.mkdirs())
        return AtomicFile(File(directory, "settings.json"))
    }

    fun read(context: Context): String? {
        val data = file(context)
        val stream = try { data.openRead() } catch (_: FileNotFoundException) { return null }
        return stream.use {
            check(it.channel.size() <= 131072)
            it.bufferedReader().readText()
        }
    }

    fun write(context: Context, json: String) {
        check(json.toByteArray(Charsets.UTF_8).size <= 131072)
        val data = file(context)
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
