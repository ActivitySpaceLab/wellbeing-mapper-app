package com.github.activityspacelab.wellbeingmapper

import android.app.backup.BackupAgent
import android.content.Context
import android.os.ParcelFileDescriptor
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File
import java.io.FileInputStream
import java.io.IOException

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class HistoryBackupAgentTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    private fun setIncludeHistory(include: Boolean) {
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean(HistoryBackupAgent.INCLUDE_HISTORY_KEY, include)
            .commit()
    }

    /** A restore stream: [first] followed by the bytes of the next file. */
    private fun restoreStream(first: ByteArray, next: ByteArray): ParcelFileDescriptor {
        val file = File(context.cacheDir, "restore-stream").apply { writeBytes(first + next) }
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    @Test
    fun `history stays out of backups unless the participant opted in`() {
        assertFalse(HistoryBackupAgent.isHistoryIncluded(context))

        setIncludeHistory(true)
        assertTrue(HistoryBackupAgent.isHistoryIncluded(context))

        setIncludeHistory(false)
        assertFalse(HistoryBackupAgent.isHistoryIncluded(context))
    }

    @Test
    fun `restore writes the survey database and leaves the stream at the next file`() {
        val database = ByteArray(100_000) { (it % 251).toByte() }
        val nextFile = "next file".toByteArray()
        val agent = Robolectric.buildBackupAgent(HistoryBackupAgent::class.java).create().get()

        val destination = context.getDatabasePath("survey_database.db")

        restoreStream(database, nextFile).use { stream ->
            agent.onRestoreFile(stream, database.size.toLong(), destination, BackupAgent.TYPE_FILE, 0L, 0L)

            assertArrayEquals(database, destination.readBytes())
            // Exactly the database's bytes were consumed: the rest of the
            // backup is still there for the next file.
            assertArrayEquals(nextFile, FileInputStream(stream.fileDescriptor).readBytes())
        }
    }

    @Test
    fun `a truncated restore stream fails instead of leaving a partial database unnoticed`() {
        val destination = File(context.cacheDir, "restored.db")

        restoreStream(ByteArray(10), ByteArray(0)).use { stream ->
            assertThrows(IOException::class.java) {
                HistoryBackupAgent.copyRestoreData(stream, 20L, destination)
            }
        }
    }
}
