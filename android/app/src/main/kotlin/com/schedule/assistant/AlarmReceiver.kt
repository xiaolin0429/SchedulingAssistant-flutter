package com.schedule.assistant

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmReceiver : BroadcastReceiver() {
    private val TAG = "AlarmReceiver"
    private val CHANNEL_ID = "alarm_channel_id"
    private val CHANNEL_NAME = "闹钟提醒"
    private val CHANNEL_DESCRIPTION = "用于显示闹钟提醒通知"

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "闹钟触发")
        
        val id = intent.getIntExtra("id", 0)
        val title = intent.getStringExtra("title") ?: "闹钟"
        val body = intent.getStringExtra("body") ?: "闹钟时间到了"
        
        // 创建通知通道（Android 8.0+需要）
        createNotificationChannel(context)
        
        // 震动
        vibrate(context)
        
        // 播放闹钟声音
        val alarmSound = getRingtoneUri(context)
        
        // 创建打开应用的PendingIntent
        val openAppIntent = createOpenAppIntent(context, id)
        
        // 构建并展示通知
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(alarmSound)
            .setVibrate(longArrayOf(0, 500, 500, 500, 500, 500))
            .setAutoCancel(true)
            .setContentIntent(openAppIntent)
            .setFullScreenIntent(openAppIntent, true) // 全屏意图，在锁屏上显示
            .build()
        
        // 显示通知
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
            Log.d(TAG, "闹钟通知已显示: ID=$id, 标题=$title")
        } catch (e: SecurityException) {
            Log.e(TAG, "无法显示通知: ${e.message}")
        }
    }
    
    // 创建打开应用的Intent
    private fun createOpenAppIntent(context: Context, alarmId: Int): PendingIntent {
        // 创建一个Intent打开MainActivity
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("from_alarm", true)
            putExtra("alarm_id", alarmId)
        }
        
        // 返回PendingIntent
        return PendingIntent.getActivity(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
    
    // 创建通知通道
    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 500, 500, 500, 500)
                
                // 设置声音
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
                setSound(getRingtoneUri(context), audioAttributes)
            }
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    // 获取闹钟铃声URI
    private fun getRingtoneUri(context: Context): Uri {
        // 尝试获取自定义闹钟声音
        val soundResource = context.resources.getIdentifier("alarm_sound", "raw", context.packageName)
        if (soundResource != 0) {
            return Uri.parse("android.resource://${context.packageName}/$soundResource")
        }
        
        // 如果没有自定义声音，使用系统默认闹钟声音
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
    }
    
    // 设备震动
    private fun vibrate(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            val vibrator = vibratorManager.defaultVibrator
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 500, 500, 500, 500, 500), -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 500, 500, 500, 500, 500), -1)
            }
        } else {
            val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 500, 500, 500, 500, 500), -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 500, 500, 500, 500, 500), -1)
            }
        }
    }
} 