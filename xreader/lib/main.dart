import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/enhanced_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化增强数据库服务
  try {
    await EnhancedDatabaseService.initialize();
    print('✅ 增强数据库服务初始化成功');
  } catch (e) {
    print('❌ 数据库服务初始化失败: $e');
    // 即使数据库初始化失败，也继续启动应用
  }
  
  runApp(
    const ProviderScope(
      child: XReaderApp(),
    ),
  );
}
