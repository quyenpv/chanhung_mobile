package com.chanhung.erp

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper

/**
 * Vuốt tắt app: khởi động lại Foreground Service (thông báo nền), không mở UI.
 * Chỉ mở lại UI khi đang có lệnh nghe khẩn cấp.
 */
class ChanHungApplication : Application() {
    private var startedCount = 0
    private val handler = Handler(Looper.getMainLooper())
    private val relaunchUi = Runnable {
        if (startedCount <= 0 && hasPendingEmergencyAudio()) {
            try {
                AppWakeHelper.bringToForeground(this)
            } catch (_: Throwable) {
            }
        }
    }
    private val relaunchService = Runnable {
        if (KeepAliveHelper.hasLoginToken(this)) {
            KeepAliveHelper.ensureBackgroundService(this)
        }
    }

    override fun onCreate() {
        super.onCreate()
        registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

            override fun onActivityStarted(activity: Activity) {
                startedCount++
                handler.removeCallbacks(relaunchUi)
            }

            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}

            override fun onActivityStopped(activity: Activity) {
                startedCount = (startedCount - 1).coerceAtLeast(0)
            }

            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

            override fun onActivityDestroyed(activity: Activity) {
                if (startedCount > 0) return
                handler.removeCallbacks(relaunchService)
                handler.postDelayed(relaunchService, 400)
                if (activity.isFinishing && hasPendingEmergencyAudio()) {
                    handler.removeCallbacks(relaunchUi)
                    handler.postDelayed(relaunchUi, 600)
                }
            }
        })
    }

    private fun hasPendingEmergencyAudio(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val pending = prefs.getString("flutter.pending_emergency_audio_cmd_v1", null)
        return !pending.isNullOrBlank() && pending.contains("start")
    }
}
