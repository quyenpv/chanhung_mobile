package com.chanhung.erp

import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Khởi động lại Foreground Service mà không mở giao diện —
 * để GPS / thông báo nền còn sống khi vuốt tắt app.
 */
object KeepAliveHelper {
    fun ensureBackgroundService(context: Context) {
        try {
            val serviceClass = Class.forName(
                "id.flutter.flutter_background_service.BackgroundService"
            )
            val intent = Intent(context, serviceClass)
            startService(context, intent)
        } catch (_: Throwable) {
        }
    }

    fun startMicService(context: Context) {
        try {
            startService(context, Intent(context, ChanHungMicService::class.java))
        } catch (_: Throwable) {
        }
    }

    fun stopMicService(context: Context) {
        try {
            context.stopService(Intent(context, ChanHungMicService::class.java))
        } catch (_: Throwable) {
        }
    }

    fun hasLoginToken(context: Context): Boolean {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val token = prefs.getString("flutter.access_token", null)
        return !token.isNullOrBlank() && !token.equals("null", ignoreCase = true)
    }

    fun hasAudioWanted(context: Context): Boolean {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.staff_audio_fg_wanted", false)
    }

    fun setUiActivityAlive(context: Context, alive: Boolean) {
        try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("flutter.staff_ui_activity_alive", alive)
                .apply()
        } catch (_: Throwable) {
        }
    }

    private fun startService(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            @Suppress("DEPRECATION")
            context.startService(intent)
        }
    }
}
