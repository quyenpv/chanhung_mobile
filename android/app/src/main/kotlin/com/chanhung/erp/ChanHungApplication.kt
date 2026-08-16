package com.chanhung.erp

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper

/**
 * Tự mở lại app ngay khi bị tắt (vuốt khỏi recent / process bị kill),
 * không xen vào khi chỉ bấm Home đưa app vào nền.
 */
class ChanHungApplication : Application() {
    private var startedCount = 0
    private val handler = Handler(Looper.getMainLooper())
    private val relaunch = Runnable {
        if (startedCount <= 0 && hasLoginToken()) {
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
                if (startedCount <= 0 && hasLoginToken()) {
                    handler.removeCallbacks(relaunch)
                    handler.postDelayed(relaunch, 150)
                }
            }
        })
    }

    private fun hasLoginToken(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val token = prefs.getString("flutter.access_token", null)
        return !token.isNullOrBlank() && !token.equals("null", ignoreCase = true)
    }
}
