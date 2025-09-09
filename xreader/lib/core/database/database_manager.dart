import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'database_schema.dart';

/// 数据库管理器
/// 
/// 负责数据库的初始化、连接管理、版本控制和基本操作
class DatabaseManager {
  static Database? _database;
  static String? _databasePath;
  static bool _isInitialized = false;
  
  /// 获取数据库实例
  static Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    
    _database = await _initDatabase();
    return _database!;
  }
  
  /// 初始化数据库
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🗄️ 开始初始化数据库...');
      
      // 在Windows、Linux和macOS桌面平台上初始化FFI
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        print('🖥️ 检测到桌面平台，初始化sqflite_common_ffi...');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('✅ sqflite_common_ffi初始化成功');
      }
      
      await _initDatabase();
      _isInitialized = true;
      
      print('✅ 数据库初始化成功');
      await _printDatabaseInfo();
      
    } catch (e, stackTrace) {
      print('❌ 数据库初始化失败: $e');
      print('🔧 错误堆栈: $stackTrace');
      rethrow;
    }
  }
  
  /// 初始化数据库实例
  static Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(path.join(documentsDir.path, 'xreader_db'));
    
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    
    _databasePath = path.join(dbDir.path, DatabaseSchema.databaseName);
    
    return await openDatabase(
      _databasePath!,
      version: DatabaseSchema.currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
      onConfigure: _onConfigure,
    );
  }
  
  /// 数据库配置
  static Future<void> _onConfigure(Database db) async {
    // 启用外键约束
    await db.rawQuery('PRAGMA foreign_keys = ON');
  }
  
  /// 创建数据库
  static Future<void> _onCreate(Database db, int version) async {
    print('📝 创建数据库表...');
    
    // 创建表
    for (final sql in DatabaseSchema.createTableStatements) {
      await db.execute(sql);
    }
    
    // 创建索引
    for (final sql in DatabaseSchema.createIndexStatements) {
      await db.execute(sql);
    }
    
    // 创建触发器
    for (final sql in DatabaseSchema.createTriggers) {
      await db.execute(sql);
    }
    
    print('✅ 数据库表创建完成');
  }
  
  /// 升级数据库
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 升级数据库从版本 $oldVersion 到 $newVersion');
    
    final upgradeStatements = DatabaseSchema.getUpgradeStatements(oldVersion, newVersion);
    
    for (final sql in upgradeStatements) {
      await db.execute(sql);
    }
    
    print('✅ 数据库升级完成');
  }
  
  /// 打开数据库时执行
  static Future<void> _onOpen(Database db) async {
    try {
      // 设置数据库优化配置
      await _configureDatabasePerformance(db);
      
      // 清理过期缓存
      await _cleanExpiredCache(db);
    } catch (e) {
      print('⚠️ 数据库配置失败: $e');
    }
  }
  
  /// 配置数据库性能设置
  static Future<void> _configureDatabasePerformance(Database db) async {
    try {
      // 启用WAL模式（写前日志）以提高并发性能
      await db.rawQuery('PRAGMA journal_mode = WAL');
      
      // 设置同步模式为NORMAL以平衡性能和安全性
      await db.rawQuery('PRAGMA synchronous = NORMAL');
      
      // 设置缓存大小（页数）
      await db.rawQuery('PRAGMA cache_size = -2000'); // 2MB缓存
      
      // 启用内存映射I/O
      await db.rawQuery('PRAGMA mmap_size = 268435456'); // 256MB
      
      print('✅ 数据库性能配置完成');
    } catch (e) {
      print('⚠️ 数据库性能配置失败: $e');
    }
  }
  
  /// 清理过期缓存
  static Future<void> _cleanExpiredCache(Database db) async {
    try {
      final result = await db.rawDelete(DatabaseSchema.cleanExpiredCache);
      if (result > 0) {
        print('🧹 清理了 $result 条过期缓存');
      }
    } catch (e) {
      print('⚠️ 清理缓存失败: $e');
    }
  }
  
  /// 打印数据库信息
  static Future<void> _printDatabaseInfo() async {
    try {
      final db = await database;
      
      // 获取数据库大小
      final sizeResult = await db.rawQuery(DatabaseSchema.getDatabaseSize);
      final size = sizeResult.first['size'] as int;
      final sizeFormatted = _formatBytes(size);
      
      // 获取表统计
      final statsResult = await db.rawQuery(DatabaseSchema.getTableStats);
      
      print('📊 数据库信息:');
      print('   路径: $_databasePath');
      print('   大小: $sizeFormatted');
      print('   版本: ${DatabaseSchema.currentVersion}');
      print('   表统计:');
      
      for (final row in statsResult) {
        final tableName = row['table_name'] as String;
        final rowCount = row['row_count'] as int;
        print('     $tableName: $rowCount 行');
      }
      
    } catch (e) {
      print('⚠️ 获取数据库信息失败: $e');
    }
  }
  
  /// 格式化字节大小
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 执行事务
  static Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }
  
  /// 批量执行SQL
  static Future<void> batch(void Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    await batch.commit(noResult: true);
  }
  
  /// 执行原始查询
  static Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
  
  /// 执行原始SQL
  static Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
  
  /// 插入数据
  static Future<int> insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm}) async {
    final db = await database;
    return await db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }
  
  /// 查询数据
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }
  
  /// 更新数据
  static Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }
  
  /// 删除数据
  static Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
  
  /// 检查表是否存在
  static Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }
  
  /// 获取表列信息
  static Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    final db = await database;
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }
  
  /// 优化数据库
  static Future<void> optimize() async {
    try {
      print('🔧 开始优化数据库...');
      
      final db = await database;
      
      // 分析表以更新统计信息
      await db.execute('ANALYZE');
      
      // 清理碎片
      await db.execute('VACUUM');
      
      // 清理过期缓存
      await _cleanExpiredCache(db);
      
      print('✅ 数据库优化完成');
      await _printDatabaseInfo();
      
    } catch (e) {
      print('❌ 数据库优化失败: $e');
    }
  }
  
  /// 备份数据库
  static Future<String?> backup(String backupPath) async {
    try {
      if (_databasePath == null) return null;
      
      print('💾 开始备份数据库...');
      
      // 关闭当前连接以确保数据完整性
      await close();
      
      // 复制数据库文件
      final sourceFile = File(_databasePath!);
      final backupFile = File(backupPath);
      
      await sourceFile.copy(backupPath);
      
      // 重新打开数据库
      await database;
      
      final size = await backupFile.length();
      print('✅ 数据库备份完成: ${_formatBytes(size)}');
      
      return backupPath;
      
    } catch (e) {
      print('❌ 数据库备份失败: $e');
      return null;
    }
  }
  
  /// 恢复数据库
  static Future<bool> restore(String backupPath) async {
    try {
      print('🔄 开始恢复数据库...');
      
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        print('❌ 备份文件不存在: $backupPath');
        return false;
      }
      
      // 关闭当前连接
      await close();
      
      // 备份当前数据库（以防恢复失败）
      if (_databasePath != null) {
        final currentFile = File(_databasePath!);
        if (await currentFile.exists()) {
          final tempBackup = '$_databasePath.backup.${DateTime.now().millisecondsSinceEpoch}';
          await currentFile.copy(tempBackup);
        }
      }
      
      // 恢复备份
      await backupFile.copy(_databasePath!);
      
      // 重新打开数据库
      await database;
      
      print('✅ 数据库恢复完成');
      await _printDatabaseInfo();
      
      return true;
      
    } catch (e) {
      print('❌ 数据库恢复失败: $e');
      return false;
    }
  }
  
  /// 清空所有数据
  static Future<void> clearAllData() async {
    try {
      print('🗑️ 开始清空所有数据...');
      
      final db = await database;
      
      // 禁用外键约束
      await db.execute('PRAGMA foreign_keys = OFF');
      
      // 删除所有表的数据
      for (final tableName in DatabaseSchema.backupTables) {
        await db.delete(tableName);
      }
      
      // 重新启用外键约束
      await db.execute('PRAGMA foreign_keys = ON');
      
      // 重置自增序列
      await db.execute('DELETE FROM sqlite_sequence');
      
      // 清理数据库
      await db.execute('VACUUM');
      
      print('✅ 所有数据已清空');
      
    } catch (e) {
      print('❌ 清空数据失败: $e');
      rethrow;
    }
  }
  
  /// 获取数据库统计信息
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await database;
      
      // 获取数据库大小
      final sizeResult = await db.rawQuery(DatabaseSchema.getDatabaseSize);
      final size = sizeResult.first['size'] as int;
      
      // 获取表统计
      final statsResult = await db.rawQuery(DatabaseSchema.getTableStats);
      final tableStats = <String, int>{};
      
      for (final row in statsResult) {
        tableStats[row['table_name'] as String] = row['row_count'] as int;
      }
      
      // 获取缓存统计
      final cacheStatsResult = await db.query(
        DatabaseConstants.cacheMetadataTable,
        columns: ['cache_type', 'COUNT(*) as count', 'SUM(data_size) as total_size'],
        groupBy: 'cache_type',
      );
      
      final cacheStats = <String, Map<String, int>>{};
      for (final row in cacheStatsResult) {
        cacheStats[row['cache_type'] as String] = {
          'count': row['count'] as int,
          'size': row['total_size'] as int? ?? 0,
        };
      }
      
      return {
        'database_size': size,
        'database_path': _databasePath,
        'version': DatabaseSchema.currentVersion,
        'table_stats': tableStats,
        'cache_stats': cacheStats,
        'is_initialized': _isInitialized,
      };
      
    } catch (e) {
      print('❌ 获取数据库统计失败: $e');
      return {};
    }
  }
  
  /// 关闭数据库连接
  static Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
    _isInitialized = false;
  }
  
  /// 检查数据库健康状态
  static Future<bool> checkHealth() async {
    try {
      final db = await database;
      
      // 检查数据库完整性
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      final isIntegrityOk = integrityResult.first['integrity_check'] == 'ok';
      
      if (!isIntegrityOk) {
        print('❌ 数据库完整性检查失败');
        return false;
      }
      
      // 检查外键约束
      final foreignKeyResult = await db.rawQuery('PRAGMA foreign_key_check');
      if (foreignKeyResult.isNotEmpty) {
        print('❌ 外键约束检查失败');
        return false;
      }
      
      print('✅ 数据库健康状态良好');
      return true;
      
    } catch (e) {
      print('❌ 数据库健康检查失败: $e');
      return false;
    }
  }
}

/// 数据库异常
class DatabaseException implements Exception {
  final String message;
  final Exception? originalException;
  
  const DatabaseException(this.message, [this.originalException]);
  
  @override
  String toString() => 'DatabaseException: $message';
}
