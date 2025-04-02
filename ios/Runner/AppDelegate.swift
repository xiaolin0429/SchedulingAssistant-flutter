import Flutter
import UIKit
import UserNotifications
import AVFoundation
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  var audioPlayer: AVAudioPlayer?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 配置UNUserNotificationCenter代理
    UNUserNotificationCenter.current().delegate = self
    
    // 注册通知类别
    let alarmAction = UNNotificationAction(
        identifier: "alarm_action",
        title: "停止闹钟",
        options: [.foreground])
    
    let alarmCategory = UNNotificationCategory(
        identifier: "alarm_category",
        actions: [alarmAction],
        intentIdentifiers: [],
        options: [])
    
    UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    
    // 设置音频会话
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print("设置音频会话失败: \(error)")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 处理通知响应
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("收到通知响应: \(userInfo)")
    
    if response.notification.request.content.categoryIdentifier == "alarm_category" {
      // 闹钟通知
      if response.actionIdentifier == "alarm_action" {
        // 停止闹钟声音
        stopAlarmSound()
      }
    }
    
    // 调用Flutter插件的处理方法
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
  
  // 在前台显示通知，特别是关键的闹钟通知
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("将要显示通知: \(userInfo)")
    
    // 检查是否为闹钟通知
    if notification.request.content.categoryIdentifier == "alarm_category" {
      // 根据iOS版本使用兼容的通知选项
      if #available(iOS 14.0, *) {
        // iOS 14及以上版本支持banner和list选项
        completionHandler([.sound, .badge, .banner, .list])
      } else {
        // iOS 13及以下版本使用alert选项
        completionHandler([.sound, .badge, .alert])
      }
      
      // 确保闹钟声音播放
      playAlarmSound()
    } else {
      // 普通通知使用默认处理
      super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }
  }
  
  // 播放闹钟声音
  private func playAlarmSound() {
    // 尝试获取自定义声音文件
    if let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") {
      do {
        audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
        audioPlayer?.numberOfLoops = -1 // 无限循环
        audioPlayer?.play()
        print("正在播放闹钟声音: \(soundURL.path)")
      } catch {
        print("无法播放闹钟声音: \(error)")
        
        // 尝试使用系统声音作为备选
        AudioServicesPlaySystemSound(1005) // 系统闹钟声音ID
      }
    } else {
      print("找不到闹钟声音文件，尝试使用系统声音")
      AudioServicesPlaySystemSound(1005) // 系统闹钟声音ID
    }
  }
  
  // 停止闹钟声音
  private func stopAlarmSound() {
    audioPlayer?.stop()
    audioPlayer = nil
  }
}
