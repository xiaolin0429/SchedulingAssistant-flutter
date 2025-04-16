import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';

/// 用户资料服务
class UserProfileService {
  final SharedPreferences _prefs;

  // SharedPreferences中存储用户资料的键名
  static const _keyUserProfile = 'user_profile';

  // 用户资料流控制器，用于通知UI更新
  final _profileController = StreamController<UserProfile>.broadcast();

  UserProfileService(this._prefs);

  // 获取用户资料流
  Stream<UserProfile> get profileStream => _profileController.stream;

  /// 加载用户资料
  Future<UserProfile> loadUserProfile() async {
    try {
      final profileJson = _prefs.getString(_keyUserProfile);
      if (profileJson == null) {
        return UserProfile.empty();
      }
      return UserProfile.fromString(profileJson);
    } catch (e) {
      debugPrint('加载用户资料失败: $e');
      return UserProfile.empty();
    }
  }

  /// 保存用户资料
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final result =
          await _prefs.setString(_keyUserProfile, profile.toString());
      if (result) {
        _profileController.add(profile);
      }
      return result;
    } catch (e) {
      debugPrint('保存用户资料失败: $e');
      return false;
    }
  }

  /// 更新用户资料
  Future<bool> updateUserProfile({
    String? nickname,
    String? bio,
    String? email,
    String? phone,
    String? avatarPath,
  }) async {
    final currentProfile = await loadUserProfile();
    final updatedProfile = currentProfile.copyWith(
      nickname: nickname,
      bio: bio,
      email: email,
      phone: phone,
      avatarPath: avatarPath,
    );
    return saveUserProfile(updatedProfile);
  }

  /// 清除用户资料
  Future<bool> clearUserProfile() async {
    try {
      final result = await _prefs.remove(_keyUserProfile);
      if (result) {
        _profileController.add(UserProfile.empty());
      }
      return result;
    } catch (e) {
      debugPrint('清除用户资料失败: $e');
      return false;
    }
  }

  /// 关闭服务
  void dispose() {
    _profileController.close();
  }
}
