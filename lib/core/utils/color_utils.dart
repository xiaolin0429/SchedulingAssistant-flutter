import 'package:flutter/material.dart';

/// 颜色扩展工具
/// 
/// 提供了一系列颜色处理的扩展方法，用于安全地处理颜色的透明度等属性。
/// 这些方法主要用于解决 Flutter 中已弃用的颜色处理方法的问题，
/// 同时提供更精确和安全的颜色操作。
extension ColorExtensions on Color {
  // ignore: deprecated_member_use
  /// 使用 [withValues] 替代已弃用的 [withOpacity] 方法，避免精度损失
  /// 
  /// [opacity] 透明度值，范围 0.0 到 1.0
  /// 
  /// 示例:
  /// ```dart
  /// final color = Colors.blue.withSafeOpacity(0.5);
  /// ```
  /// 
  /// 这个方法主要用于:
  /// - UI 中需要半透明效果的场景
  /// - 主题色的透明度调整
  /// - 视觉层次的区分
  Color withSafeOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0, 'opacity 必须在 0.0 到 1.0 之间');
    return withValues(
      red: r.toDouble(),
      green: g.toDouble(),
      blue: b.toDouble(),
      alpha: (opacity * 255).roundToDouble(),
    );
  }
} 