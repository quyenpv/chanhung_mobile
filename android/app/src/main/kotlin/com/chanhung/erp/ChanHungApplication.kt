package com.chanhung.erp

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper

/**
 * Chỉ tự mở lại app khi đang có lệnh nghe khẩn cấp.
 * Không mở lại khi người dùng vuốt tắt / bấm Home — việc đó làm app crash.
 */
class ChanHungApplication : Application() {
    private var startedCount = 0
    private val handler = Handler(Looper.getMainLooper())
    private val relaunch = Runnable {
        if (startedCount <= 0 && hasPendingEmergencyAudio()) {
            try {
                AppWakeHelper.bringToForeground(this)
            } catch (_: Throwable) {
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

            override fun onActivityStarted(activity: Activity) {
                startedCount++
                handler.removeCallbacks(relaunch)
            }

            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}

            override fun onActivityStopped(activity: Activity) {
                startedCount = (startedCount - 1).coerceAtLeast(0)
            }

            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

            override fun onActivityDestroyed(activity: Activity) {
                if (!activity.isFinishing) return
                if (startedCount <= 0 && hasPendingEmergencyAudio()) {
                    handler.removeCallbacks(relaunch)
                    handler.postDelayed(relaunch, 400)
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
