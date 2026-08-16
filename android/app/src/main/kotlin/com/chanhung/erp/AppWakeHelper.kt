package com.chanhung.erp

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object AppWakeHelper {
    @Suppress("DEPRECATION")
    fun bringToForeground(context: Context) {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val flags = PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP
            val wakeLock = powerManager.newWakeLock(flags, "chanhung:emergency_audio_wake")
            wakeLock.acquire(15_000)
        } catch (_: Throwable) {
        }

        val launch = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
            )
            putExtra("wake_reason", "emergency_audio")
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                !canDrawOverlays(context)
            ) {
                return
            }
            context.startActivity(launch)
        } catch (_: Throwable) {
        }
    }

    fun canDrawOverlays(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }
}

class AppWakePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "chanhung/app_wake")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "bringToForeground" -> {
                AppWakeHelper.bringToForeground(context)
                result.success(true)
            }
            "canDrawOverlays" -> result.success(AppWakeHelper.canDrawOverlays(context))
            "startMicService" -> {
                KeepAliveHelper.startMicService(context)
                result.success(true)
            }
            "stopMicService" -> {
                KeepAliveHelper.stopMicService(context)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
