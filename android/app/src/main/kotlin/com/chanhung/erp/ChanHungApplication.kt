package com.chanhung.erp

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper

/**
 * Vuốt tắt app: giữ Foreground Service + service micro nếu đang nghe realtime.
 * Không tự mở lại UI (gây crash). Micro chuyển sang isolate nền.
 */
class ChanHungApplication : Application() {
    private var startedCount = 0
    private val handler = Handler(Looper.getMainLooper())
    private val relaunchService = Runnable {
        if (!KeepAliveHelper.hasLoginToken(this)) return@Runnable
        KeepAliveHelper.ensureBackgroundService(this)
        if (KeepAliveHelper.hasAudioWanted(this)) {
            KeepAliveHelper.startMicService(this)
        }
    }

    override fun onCreate() {
        super.onCreate()
        if (KeepAliveHelper.hasLoginToken(this)) {
            KeepAliveHelper.ensureBackgroundService(this)
            if (KeepAliveHelper.hasAudioWanted(this)) {
                KeepAliveHelper.startMicService(this)
                KeepAliveHelper.setUiActivityAlive(this, false)
            }
        }
        registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

            override fun onActivityStarted(activity: Activity) {
                startedCount++
                KeepAliveHelper.setUiActivityAlive(this@ChanHungApplication, true)
                handler.removeCallbacks(relaunchService)
            }

            override fun onActivityResumed(activity: Activity) {
                KeepAliveHelper.setUiActivityAlive(this@ChanHungApplication, true)
            }

            override fun onActivityPaused(activity: Activity) {}

            override fun onActivityStopped(activity: Activity) {
                startedCount = (startedCount - 1).coerceAtLeast(0)
            }

            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

            override fun onActivityDestroyed(activity: Activity) {
                if (startedCount > 0) return
                KeepAliveHelper.setUiActivityAlive(this@ChanHungApplication, false)
                handler.removeCallbacks(relaunchService)
                handler.postDelayed(relaunchService, 250)
            }
        })
    }
}
