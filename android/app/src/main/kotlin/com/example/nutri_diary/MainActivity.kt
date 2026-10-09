package com.example.nutri_diary

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shiyokushi/downloads")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveBackup") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    result.error("unsupported_android", "Android 10 or later is required to save into Downloads.", null)
                    return@setMethodCallHandler
                }
                val name = call.argument<String>("fileName") ?: "ShyokuShi_backup.ntbackup"
                val sourcePath = call.argument<String>("sourcePath")
                if (sourcePath == null) {
                    result.error("missing_data", "Backup source was missing.", null)
                    return@setMethodCallHandler
                }
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                    put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/ShyokuShi")
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
                val resolver = applicationContext.contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                if (uri == null) {
                    result.error("save_failed", "Could not create the backup file in Downloads/ShyokuShi.", null)
                    return@setMethodCallHandler
                }
                try {
                    java.io.File(sourcePath).inputStream().use { input ->
                        resolver.openOutputStream(uri)?.use { output -> input.copyTo(output) }
                            ?: throw IllegalStateException("Could not open the backup file.")
                    }
                    val ready = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
                    resolver.update(uri, ready, null, null)
                    result.success(uri.toString())
                } catch (error: Exception) {
                    resolver.delete(uri, null, null)
                    result.error("save_failed", error.message, null)
                }
            }
    }
}
