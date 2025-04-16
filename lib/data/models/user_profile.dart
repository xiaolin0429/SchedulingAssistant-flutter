import 'dart:convert';

/// 用户资料模型
class UserProfile {
  final String? nickname;
  final String? bio;
  final String? email;
  final String? phone;
  final String? avatarPath;

  const UserProfile({
    this.nickname,
    this.bio,
    this.email,
    this.phone,
    this.avatarPath,
  });

  // 创建一个空的资料对象
  factory UserProfile.empty() {
    return const UserProfile();
  }

  // 从JSON Map创建对象
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nickname: json['nickname'] as String?,
      bio: json['bio'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarPath: json['avatarPath'] as String?,
    );
  }

  // 序列化为JSON Map
  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'bio': bio,
      'email': email,
      'phone': phone,
      'avatarPath': avatarPath,
    };
  }

  // 从字符串创建对象
  factory UserProfile.fromString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserProfile.fromJson(json);
  }

  // 序列化为字符串
  @override
  String toString() {
    return jsonEncode(toJson());
  }

  // 复制并更新对象
  UserProfile copyWith({
    String? nickname,
    String? bio,
    String? email,
    String? phone,
    String? avatarPath,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
