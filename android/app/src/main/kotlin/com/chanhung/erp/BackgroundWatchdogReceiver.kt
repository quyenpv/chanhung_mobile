package com.chanhung.erp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log

class BackgroundWatchdogReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.d("BackgroundWatchdog", "Received broadcast: ${intent?.action}")
        try {
            val serviceIntent = Intent(context, id.flutter.flutter_background_service.BackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e("BackgroundWatchdog", "Failed to start service: ${e.message}")
        }
    }

    companion object {
        fun scheduleRestart(context: Context, delayMs: Long = 1000) {
            try {
                val intent = Intent(context, BackgroundWatchdogReceiver::class.java).apply {
                    action = "chanhung.intent.action.RESTART_SERVICE"
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    991,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        SystemClock.elapsedRealtime() + delayMs,
                        pendingIntent
                    )
                } else {
                    alarmManager.set(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        SystemClock.elapsedRealtime() + delayMs,
                        pendingIntent
                    )
                }
            } catch (e: Exception) {
                Log.e("BackgroundWatchdog", "scheduleRestart failed: ${e.message}")
            }
        }
    }
}
