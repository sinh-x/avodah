package com.sinh_x.avodah_viewer

import java.io.BufferedReader
import java.net.URI
import org.json.JSONObject

/** Bounded reference-only wire protocol; no URLs or inbox text are actionable. */
object NotificationStreamProtocol {
    sealed class Frame {
        data class Checkpoint(val cursor: Long) : Frame()
        data class Notification(val cursor: Long, val id: String) : Frame()
    }
    class AuthorizationRequired : Exception()

    fun validateOrigin(raw: String): String {
        require(raw.length <= 2048)
        val uri = URI(raw)
        require(uri.scheme == "https" && !uri.host.isNullOrBlank())
        require(uri.rawUserInfo == null && uri.rawQuery == null && uri.rawFragment == null)
        return raw.trimEnd('/')
    }

    fun readLine(reader: BufferedReader): String? {
        val line = StringBuilder()
        while (true) {
            val char = reader.read()
            if (char == -1) return if (line.isEmpty()) null else line.toString()
            if (char == '\n'.code) return line.toString().trimEnd('\r')
            require(line.length < 4096) { "Oversized event" }
            line.append(char.toChar())
        }
    }

    fun parse(line: String, currentCursor: Long): Frame? {
        require(line.length <= 4096)
        if (line.isEmpty() || line.startsWith(":")) return null
        require(line.startsWith("data: "))
        val event = JSONObject(line.substring(6))
        if (event.optString("type") == "error") throw AuthorizationRequired()
        val type = event.getString("type")
        require(type == "checkpoint" || type == "notification")
        val expectedKeys = if (type == "checkpoint") setOf("type", "cursor") else setOf("type", "cursor", "id")
        require(event.keys().asSequence().toSet() == expectedKeys)
        val rawCursor = event.get("cursor")
        require(rawCursor is Number && Regex("[0-9]+").matches(rawCursor.toString()))
        val cursor = rawCursor.toString().toLong()
        if (type == "checkpoint") {
            require(cursor >= currentCursor) { "Server history moved backwards" }
            return Frame.Checkpoint(cursor)
        }
        val id = event.getString("id")
        require(Regex("[a-zA-Z0-9_-]{1,100}").matches(id))
        require(cursor > 0)
        return if (cursor <= currentCursor) null else Frame.Notification(cursor, id)
    }
}
