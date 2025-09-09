import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 屏幕适配辅助工具类
class ScreenUtilHelper {
  ScreenUtilHelper._();
  
  /// 获取响应式的字体大小
  static double getResponsiveFontSize(double baseSize) {
    final screenHeight = 1.sh;
    if (screenHeight < 700) {
      return (baseSize * 0.9).sp;
    } else if (screenHeight > 900) {
      return (baseSize * 1.1).sp;
    }
    return baseSize.sp;
  }
  
  /// 获取响应式的图标大小
  static double getResponsiveIconSize(double baseSize) {
    final screenHeight = 1.sh;
    if (screenHeight < 700) {
      return (baseSize * 0.8).w;
    } else if (screenHeight > 900) {
      return (baseSize * 1.2).w;
    }
    return baseSize.w;
  }
  
  /// 获取响应式的间距
  static double getResponsiveSpacing(double baseSpacing) {
    final screenHeight = 1.sh;
    if (screenHeight < 700) {
      return (baseSpacing * 0.7).h;
    } else if (screenHeight > 900) {
      return (baseSpacing * 1.3).h;
    }
    return baseSpacing.h;
  }
  
  /// 获取响应式的按钮高度
  static double getResponsiveButtonHeight() {
    final screenHeight = 1.sh;
    if (screenHeight < 700) {
      return 40.h;
    } else if (screenHeight > 900) {
      return 56.h;
    }
    return 48.h;
  }
  
  /// 获取底部导航栏高度
  static double getBottomNavHeight({bool showLabels = true}) {
    final screenHeight = 1.sh;
    double baseHeight = showLabels ? 70.h : 50.h;
    
    if (screenHeight < 700) {
      return baseHeight * 0.8;
    } else if (screenHeight > 900) {
      return baseHeight * 1.2;
    }
    return baseHeight;
  }
  
  /// 判断是否为小屏幕设备
  static bool isSmallScreen() {
    return 1.sh < 700;
  }
  
  /// 判断是否为大屏幕设备
  static bool isLargeScreen() {
    return 1.sh > 900;
  }
  
  /// 获取安全的内容区域内边距
  static EdgeInsets getSafeContentPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmall = isSmallScreen();
    
    return EdgeInsets.only(
      left: isSmall ? 12.w : 16.w,
      right: isSmall ? 12.w : 16.w,
      top: mediaQuery.padding.top + (isSmall ? 8.h : 12.h),
      bottom: mediaQuery.padding.bottom + (isSmall ? 8.h : 12.h),
    );
  }
  
  /// 获取对话框的最大宽度
  static double getDialogMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return screenWidth * 0.95;
    } else if (screenWidth > 600) {
      return 500.w;
    }
    return screenWidth * 0.9;
  }
  
  /// 获取列表项的高度
  static double getListItemHeight() {
    final screenHeight = 1.sh;
    if (screenHeight < 700) {
      return 56.h;
    } else if (screenHeight > 900) {
      return 72.h;
    }
    return 64.h;
  }
}