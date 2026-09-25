package com.github.activityspacelab.wellbeingmapper

import android.app.backup.BackupAgent
import android.app.backup.BackupDataInput
import android.app.backup.BackupDataOutput
import android.app.backup.FullBackupDataOutput
import android.content.Context
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

/**
 * Auto Backup agent that includes the participant's history (the survey
 * database) in backups and device-to-device transfers only when they turned
 * "Include my data in phone backups" on in Settings. It is off by default.
 *
 * res/xml/backup_rules.xml and data_extraction_rules.xml always exclude the
 * survey database; the default implementation backs up everything else as
 * before. When the setting is on, [onFullBackup] adds the database files
 * itself, and [onRestoreFile] writes them back on restore, because the
 * default restore skips files that those rules exclude.
 *
 * The setting lives in the Dart shared_preferences store
 * (lib/services/device_backup_service.dart).
 */
class HistoryBackupAgent : BackupAgent() {

    // Key/value backup is not used: the manifest sets fullBackupOnly.
    override fun onBackup(
        oldState: ParcelFileDescriptor?,
        data: BackupDataOutput?,
        newState: ParcelFileDescriptor?,
    ) = Unit

    override fun onRestore(
        data: BackupDataInput?,
        appVersionCode: Int,
        newState: ParcelFileDescriptor?,
    ) = Unit

    override fun onFullBackup(data: FullBackupDataOutput) {
        super.onFullBackup(data)
        if (!isHistoryIncluded(this)) return
        for (name in HISTORY_FILES) {
            val file = getDatabasePath(name)
            if (file.exists()) fullBackupFile(file, data)
        }
    }

    override fun onRestoreFile(
        data: ParcelFileDescriptor,
        size: Long,
        destination: File,
        type: Int,
        mode: Long,
        mtime: Long,
    ) {
        if (type == TYPE_FILE && isHistoryFile(destination)) {
            copyRestoreData(data, size, destination)
            return
        }
        super.onRestoreFile(data, size, destination, type, mode, mtime)
    }

    private fun isHistoryFile(file: File): Boolean {
        val path = file.canonicalPath
        return HISTORY_FILES.any { getDatabasePath(it).canonicalPath == path }
    }

    companion object {
        /** Where the Dart shared_preferences plugin keeps values on Android. */
        private const val PREFS_FILE = "FlutterSharedPreferences"

        /** DeviceBackupService.includeHistoryKey with the plugin's key prefix. */
        const val INCLUDE_HISTORY_KEY = "flutter.include_history_in_device_backups"

        /** The survey database (SurveyDatabase.fileName) and SQLite's journals. */
        val HISTORY_FILES = listOf(
            "survey_database.db",
            "survey_database.db-journal",
            "survey_database.db-wal",
            "survey_database.db-shm",
        )

        fun isHistoryIncluded(context: Context): Boolean =
            context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                .getBoolean(INCLUDE_HISTORY_KEY, false)

        /**
         * Writes the next [size] bytes of the restore stream to [destination].
         * The rest of the backup follows this file in the same stream, so it
         * reads exactly [size] bytes and leaves the stream open (as the
         * framework's own restore does).
         */
        fun copyRestoreData(data: ParcelFileDescriptor, size: Long, destination: File) {
            destination.parentFile?.mkdirs()
            val input = FileInputStream(data.fileDescriptor)
            FileOutputStream(destination).use { output ->
                val buffer = ByteArray(32 * 1024)
                var remaining = size
                while (remaining > 0) {
                    val read = input.read(buffer, 0, minOf(buffer.size.toLong(), remaining).toInt())
                    if (read < 0) throw IOException("Restore data ended early for ${destination.name}")
                    output.write(buffer, 0, read)
                    remaining -= read
                }
            }
        }
    }
}
