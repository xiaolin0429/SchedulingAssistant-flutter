package com.schedule.assistant

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.schedule.assistant/alarm"
    private lateinit var alarmManager: AlarmManager
    // 保存闹钟ID集合，方便取消所有闹钟
    private val alarmIds = mutableSetOf<Int>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // 初始化AlarmManager
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // 设置Method Channel以接收Flutter端的调用
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setExactAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val title = call.argument<String>("title") ?: "闹钟"
                    val body = call.argument<String>("body") ?: "闹钟时间到了"
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    val exact = call.argument<Boolean>("exact") ?: true
                    
                    setExactAlarm(id, title, body, triggerAtMillis, exact)
                    // 将闹钟ID添加到集合中
                    alarmIds.add(id)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelAlarm(id)
                    // 从集合中移除闹钟ID
                    alarmIds.remove(id)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    cancelAllAlarms()
                    result.success(true)
                }
                "checkAlarmPermissions" -> {
                    result.success(checkAlarmPermissions())
                }
                "openAlarmSettings" -> {
                    openAlarmSettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // 设置精确闹钟
    private fun setExactAlarm(id: Int, title: String, body: String, triggerAtMillis: Long, exact: Boolean) {
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 根据Android版本选择合适的闹钟设置方法
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && exact -> {
                // Android 12+ 需要检查是否有设置精确闹钟的权限
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                } else {
                    // 使用非精确的闹钟替代
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && exact -> {
                // Android 6.0+ 允许在电池优化的情况下仍然触发精确闹钟
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT && exact -> {
                // Android 4.4+ 支持精确闹钟
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
            else -> {
                // 低版本Android或不需要精确闹钟
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        }
    }
    
    // 取消闹钟
    private fun cancelAlarm(id: Int) {
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        
        pendingIntent?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }
    
    // 取消所有闹钟
    private fun cancelAllAlarms() {
        // 复制一份闹钟ID集合，因为在循环中会修改原集合
        val idsToCancel = alarmIds.toSet()
        
        // 取消所有已设置的闹钟
        for (id in idsToCancel) {
            cancelAlarm(id)
        }
        
        // 清空闹钟ID集合
        alarmIds.clear()
        
        // 额外尝试取消系统通知
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        notificationManager.cancelAll()
    }
    
    // 检查闹钟权限
    private fun checkAlarmPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return alarmManager.canScheduleExactAlarms()
        }
        return true
    }
    
    // 打开闹钟设置页面
    private fun openAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
            startActivity(intent)
        }
    }
} 