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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                @Suppress("DEPRECATION")
                context.startService(intent)
            }
        } catch (_: Throwable) {
        }
    }

    fun hasLoginToken(context: Context): Boolean {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val token = prefs.getString("flutter.access_token", null)
        return !token.isNullOrBlank() && !token.equals("null", ignoreCase = true)
    }
}
