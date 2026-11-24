package com.sinh_x.avodah_viewer

import java.io.StringReader
import org.junit.Assert.*
import org.junit.Test

class NotificationStreamProtocolTest {
    @Test fun acceptsOnlyTrustedHttpsOrigin() {
        assertEquals("https://host.example/avodah", NotificationStreamProtocol.validateOrigin("https://host.example/avodah/"))
        for (origin in listOf("http://host.example", "https://user:secret@host.example", "https://host.example/?token=secret", "https://host.example/#other", "file:///tmp/server")) {
            assertThrows(Exception::class.java) { NotificationStreamProtocol.validateOrigin(origin) }
        }
    }
    @Test fun parsesReferenceAndCheckpointWithoutPrivateContent() {
        assertEquals(NotificationStreamProtocol.Frame.Checkpoint(4), NotificationStreamProtocol.parse("data: {\"type\":\"checkpoint\",\"cursor\":4}", 3))
        assertEquals(NotificationStreamProtocol.Frame.Notification(5, "opaque-id"), NotificationStreamProtocol.parse("data: {\"type\":\"notification\",\"cursor\":5,\"id\":\"opaque-id\"}", 4))
        assertNull(NotificationStreamProtocol.parse(": heartbeat", 5))
        assertNull(NotificationStreamProtocol.parse("", 5))
    }
    @Test fun replayDoesNotAnnounceSeenSequenceAgain() {
        assertNull(NotificationStreamProtocol.parse("data: {\"type\":\"notification\",\"cursor\":5,\"id\":\"opaque-id\"}", 5))
        assertThrows(Exception::class.java) { NotificationStreamProtocol.parse("data: {\"type\":\"checkpoint\",\"cursor\":2}", 5) }
    }
    @Test fun rejectsUntrustedTapUrlsAndUnexpectedPayloadFields() {
        for (json in listOf(
            "{\"type\":\"notification\",\"cursor\":5,\"id\":\"https://other.test\"}",
            "{\"type\":\"notification\",\"cursor\":5,\"id\":\"id\",\"body\":\"private\"}",
            "{\"type\":\"notification\",\"cursor\":\"5\",\"id\":\"id\"}",
            "{\"type\":\"notification\",\"cursor\":-1,\"id\":\"id\"}",
            "{\"type\":\"checkpoint\",\"cursor\":1.5}"
        )) assertThrows(Exception::class.java) { NotificationStreamProtocol.parse("data: $json", 0) }
    }
    @Test fun authorizationErrorStopsRatherThanAdvancingCursor() {
        assertThrows(NotificationStreamProtocol.AuthorizationRequired::class.java) {
            NotificationStreamProtocol.parse("data: {\"type\":\"error\",\"reason\":\"authorization-required\"}", 2)
        }
    }
    @Test fun boundsLineMemoryAndHandlesCrlfAndEof() {
        val reader = StringReader(": heartbeat\r\n\n").buffered()
        assertEquals(": heartbeat", NotificationStreamProtocol.readLine(reader))
        assertEquals("", NotificationStreamProtocol.readLine(reader))
        assertNull(NotificationStreamProtocol.readLine(reader))
        assertThrows(Exception::class.java) { NotificationStreamProtocol.readLine(StringReader("x".repeat(4097)).buffered()) }
    }
}
