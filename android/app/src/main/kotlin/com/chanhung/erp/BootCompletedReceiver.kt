package com.chanhung.erp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Sau khi máy boot / cập nhật app: chạy lại Foreground Service nếu đã đăng nhập.
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

        if (!KeepAliveHelper.hasLoginToken(context)) {
            return
        }

        KeepAliveHelper.ensureBackgroundService(context)

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val pending = prefs.getString("flutter.pending_emergency_audio_cmd_v1", null)
        if (!pending.isNullOrBlank() && pending.contains("start")) {
            try {
                AppWakeHelper.bringToForeground(context)
            } catch (_: Throwable) {
            }
        }
    }
}
