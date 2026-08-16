package com.chanhung.erp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Khởi động lại app + foreground service sau khi máy boot hoặc app được cập nhật.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val token = prefs.getString("flutter.access_token", null)
        if (token.isNullOrBlank() || token.equals("null", ignoreCase = true)) {
            return
        }

        try {
            AppWakeHelper.bringToForeground(context)
        } catch (_: Throwable) {
        }
    }
}
