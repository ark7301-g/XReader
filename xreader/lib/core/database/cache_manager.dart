import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';
import 'database_schema.dart';

/// 缓存管理器
/// 
/// 提供分层缓存功能：
/// 1. 内存缓存 - 最快速访问
/// 2. 数据库缓存 - 持久化缓存
/// 3. 智能失效策略
class CacheManager {
  static final Map<String, _CacheItem> _memoryCache = {};
  static final Map<String, DateTime> _accessTimes = {};
  static int _maxMemoryItems = 100;
  static int _maxMemorySize = 50 * 1024 * 1024; // 50MB
  static int _currentMemorySize = 0;
  
  /// 设置内存缓存限制
  static void setMemoryLimits({int? maxItems, int? maxSize}) {
    _maxMemoryItems = maxItems ?? _maxMemoryItems;
    _maxMemorySize = maxSize ?? _maxMemorySize;
    _cleanupMemoryCache();
  }
  
  /// 获取缓存数据
  static Future<T?> get<T>(
    String key, {
    Duration? maxAge,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      // 1. 先检查内存缓存
      final memoryItem = _memoryCache[key];
      if (memoryItem != null) {
        if (maxAge == null || DateTime.now().difference(memoryItem.createdAt) <= maxAge) {
          _updateAccessTime(key);
          
          if (T == String) {
            return memoryItem.data as T;
          } else if (T.toString() == 'List<int>' || T.toString() == 'Uint8List') {
            return memoryItem.data as T;
          } else if (fromJson != null && memoryItem.data is Map<String, dynamic>) {
            return fromJson(memoryItem.data as Map<String, dynamic>);
          } else {
            return memoryItem.data as T;
          }
        } else {
          // 内存缓存过期，移除
          _removeFromMemoryCache(key);
        }
      }
      
      // 2. 检查数据库缓存
      final dbResult = await _getFromDatabase(key, maxAge: maxAge);
      if (dbResult != null) {
        // 将数据库缓存加载到内存
        await _putToMemoryCache(key, dbResult['data'], dbResult['data_size']);
        
        if (T == String) {
          return dbResult['data'] as T;
        } else if (T.toString() == 'List<int>' || T.toString() == 'Uint8List') {
          if (dbResult['data'] is String) {
            final bytes = base64Decode(dbResult['data'] as String);
            return bytes as T;
          }
          return dbResult['data'] as T;
        } else if (fromJson != null) {
          final jsonData = json.decode(dbResult['data'] as String) as Map<String, dynamic>;
          return fromJson(jsonData);
        } else {
          return json.decode(dbResult['data'] as String) as T;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ 缓存获取失败 [$key]: $e');
      
      // 如果是类型转换错误，清除该缓存项
      if (e.toString().contains('is not a subtype')) {
        print('🧹 检测到类型转换错误，清除缓存项: $key');
        await remove(key);
      }
      
      return null;
    }
  }
  
  /// 设置缓存数据
  static Future<void> put<T>(
    String key,
    T data, {
    String cacheType = 'default',
    Duration? expiry,
    Map<String, dynamic> Function(T)? toJson,
  }) async {
    try {
      dynamic processedData;
      int dataSize;
      
      // 处理不同类型的数据
      if (data is String) {
        processedData = data;
        dataSize = data.length;
      } else if (data is List<int> || data is Uint8List) {
        processedData = base64Encode(data as List<int>);
        dataSize = (data as List<int>).length;
      } else if (toJson != null) {
        final jsonData = toJson(data);
        processedData = json.encode(jsonData);
        dataSize = processedData.length;
      } else {
        processedData = json.encode(data);
        dataSize = processedData.length;
      }
      
      // 1. 保存到内存缓存
      await _putToMemoryCache(key, processedData, dataSize);
      
      // 2. 保存到数据库缓存
      await _putToDatabase(key, processedData, cacheType, dataSize, expiry);
      
    } catch (e) {
      print('❌ 缓存设置失败 [$key]: $e');
    }
  }
  
  /// 删除缓存
  static Future<void> remove(String key) async {
    try {
      // 1. 从内存缓存中删除
      _removeFromMemoryCache(key);
      
      // 2. 从数据库缓存中删除
      await DatabaseManager.delete(
        DatabaseConstants.cacheMetadataTable,
        where: 'cache_key = ?',
        whereArgs: [key],
      );
      
    } catch (e) {
      print('❌ 缓存删除失败 [$key]: $e');
    }
  }
  
  /// 按类型清除缓存
  static Future<void> clearByType(String cacheType) async {
    try {
      // 1. 从内存缓存中删除相关项
      final keysToRemove = <String>[];
      for (final entry in _memoryCache.entries) {
        if (entry.value.type == cacheType) {
          keysToRemove.add(entry.key);
        }
      }
      
      for (final key in keysToRemove) {
        _removeFromMemoryCache(key);
      }
      
      // 2. 从数据库缓存中删除
      await DatabaseManager.delete(
        DatabaseConstants.cacheMetadataTable,
        where: 'cache_type = ?',
        whereArgs: [cacheType],
      );
      
      print('🧹 清除了 $cacheType 类型的缓存');
      
    } catch (e) {
      print('❌ 清除缓存失败 [$cacheType]: $e');
    }
  }
  
  /// 清除所有缓存
  static Future<void> clearAll() async {
    try {
      // 1. 清除内存缓存
      _memoryCache.clear();
      _accessTimes.clear();
      _currentMemorySize = 0;
      
      // 2. 清除数据库缓存
      await DatabaseManager.delete(DatabaseConstants.cacheMetadataTable);
      
      print('🧹 清除了所有缓存');
      
    } catch (e) {
      print('❌ 清除所有缓存失败: $e');
    }
  }
  
  /// 清除过期缓存
  static Future<void> clearExpired() async {
    try {
      final now = DateTime.now();
      
      // 1. 清除内存中的过期缓存
      final expiredKeys = <String>[];
      for (final entry in _memoryCache.entries) {
        if (entry.value.expiresAt != null && now.isAfter(entry.value.expiresAt!)) {
          expiredKeys.add(entry.key);
        }
      }
      
      for (final key in expiredKeys) {
        _removeFromMemoryCache(key);
      }
      
      // 2. 清除数据库中的过期缓存
      final deletedCount = await DatabaseManager.rawExecute(
        DatabaseSchema.cleanExpiredCache,
      );
      
      if (deletedCount > 0 || expiredKeys.isNotEmpty) {
        print('🧹 清除了 ${expiredKeys.length + deletedCount} 条过期缓存');
      }
      
    } catch (e) {
      print('❌ 清除过期缓存失败: $e');
    }
  }
  
  /// 获取缓存统计信息
  static Future<Map<String, dynamic>> getStats() async {
    try {
      // 内存缓存统计
      final memoryStats = {
        'items': _memoryCache.length,
        'size_bytes': _currentMemorySize,
        'size_mb': (_currentMemorySize / (1024 * 1024)).toStringAsFixed(2),
        'max_items': _maxMemoryItems,
        'max_size_mb': (_maxMemorySize / (1024 * 1024)).toStringAsFixed(2),
      };
      
      // 数据库缓存统计
      final dbStats = await DatabaseManager.rawQuery('''
        SELECT 
          cache_type,
          COUNT(*) as count,
          SUM(data_size) as total_size,
          AVG(data_size) as avg_size,
          MIN(created_at) as oldest,
          MAX(last_accessed) as most_recent
        FROM ${DatabaseConstants.cacheMetadataTable}
        GROUP BY cache_type
      ''');
      
      final typeStats = <String, Map<String, dynamic>>{};
      int totalDbItems = 0;
      int totalDbSize = 0;
      
      for (final row in dbStats) {
        final type = row['cache_type'] as String;
        final count = row['count'] as int;
        final size = row['total_size'] as int? ?? 0;
        
        totalDbItems += count;
        totalDbSize += size;
        
        typeStats[type] = {
          'count': count,
          'total_size': size,
          'avg_size': row['avg_size'] ?? 0,
          'oldest': DateTime.fromMillisecondsSinceEpoch((row['oldest'] as int? ?? 0) * 1000),
          'most_recent': DateTime.fromMillisecondsSinceEpoch((row['most_recent'] as int? ?? 0) * 1000),
        };
      }
      
      return {
        'memory': memoryStats,
        'database': {
          'total_items': totalDbItems,
          'total_size_bytes': totalDbSize,
          'total_size_mb': (totalDbSize / (1024 * 1024)).toStringAsFixed(2),
          'by_type': typeStats,
        },
        'combined': {
          'total_items': _memoryCache.length + totalDbItems,
          'total_size_bytes': _currentMemorySize + totalDbSize,
          'total_size_mb': ((_currentMemorySize + totalDbSize) / (1024 * 1024)).toStringAsFixed(2),
        },
      };
      
    } catch (e) {
      print('❌ 获取缓存统计失败: $e');
      return {};
    }
  }
  
  /// 预热缓存
  static Future<void> warmup() async {
    try {
      print('🔥 开始预热缓存...');
      
      // 加载最近访问的热点数据到内存
      final recentData = await DatabaseManager.query(
        DatabaseConstants.cacheMetadataTable,
        orderBy: 'last_accessed DESC',
        limit: _maxMemoryItems ~/ 2, // 预热一半的内存缓存空间
      );
      
      int loadedCount = 0;
      for (final row in recentData) {
        final key = row['cache_key'] as String;
        final size = row['data_size'] as int;
        
        if (_currentMemorySize + size <= _maxMemorySize) {
          // 这里可以加载实际数据到内存，暂时只记录元数据
          _accessTimes[key] = DateTime.now();
          loadedCount++;
        } else {
          break;
        }
      }
      
      print('✅ 缓存预热完成，加载了 $loadedCount 个项目');
      
    } catch (e) {
      print('❌ 缓存预热失败: $e');
    }
  }
  
  /// 从数据库获取缓存
  static Future<Map<String, dynamic>?> _getFromDatabase(String key, {Duration? maxAge}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      String where = 'cache_key = ?';
      List<dynamic> whereArgs = [key];
      
      // 添加过期时间检查
      if (maxAge != null) {
        final minTimestamp = now - maxAge.inSeconds;
        where += ' AND created_at >= ?';
        whereArgs.add(minTimestamp);
      }
      
      // 添加未过期检查
      where += ' AND (expires_at IS NULL OR expires_at > ?)';
      whereArgs.add(now);
      
      final results = await DatabaseManager.query(
        DatabaseConstants.cacheMetadataTable,
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        // 更新最后访问时间
        await DatabaseManager.update(
          DatabaseConstants.cacheMetadataTable,
          {'last_accessed': now},
          where: 'cache_key = ?',
          whereArgs: [key],
        );
        
        // 这里应该从实际的存储位置获取数据
        // 为简化，假设数据直接存储在metadata中
        return results.first;
      }
      
      return null;
    } catch (e) {
      print('❌ 从数据库获取缓存失败: $e');
      return null;
    }
  }
  
  /// 保存到数据库缓存
  static Future<void> _putToDatabase(
    String key,
    dynamic data,
    String cacheType,
    int dataSize,
    Duration? expiry,
  ) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int? expiresAt;
      
      if (expiry != null) {
        expiresAt = now + expiry.inSeconds;
      }
      
      await DatabaseManager.insert(
        DatabaseConstants.cacheMetadataTable,
        {
          'cache_key': key,
          'cache_type': cacheType,
          'data': data, // 实际应用中可能需要单独的数据表
          'data_size': dataSize,
          'last_accessed': now,
          'expires_at': expiresAt,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (e) {
      print('❌ 保存到数据库缓存失败: $e');
    }
  }
  
  /// 保存到内存缓存
  static Future<void> _putToMemoryCache(String key, dynamic data, int dataSize) async {
    // 检查是否需要清理内存
    while ((_memoryCache.length >= _maxMemoryItems || 
            _currentMemorySize + dataSize > _maxMemorySize) && 
           _memoryCache.isNotEmpty) {
      _evictLeastRecentlyUsed();
    }
    
    // 移除已存在的项目
    if (_memoryCache.containsKey(key)) {
      _removeFromMemoryCache(key);
    }
    
    // 添加新项目
    _memoryCache[key] = _CacheItem(
      data: data,
      size: dataSize,
      createdAt: DateTime.now(),
      expiresAt: null,
      type: 'memory',
    );
    _accessTimes[key] = DateTime.now();
    _currentMemorySize += dataSize;
  }
  
  /// 从内存缓存移除
  static void _removeFromMemoryCache(String key) {
    final item = _memoryCache.remove(key);
    if (item != null) {
      _currentMemorySize -= item.size;
    }
    _accessTimes.remove(key);
  }
  
  /// 淘汰最少使用的项目
  static void _evictLeastRecentlyUsed() {
    if (_accessTimes.isEmpty) return;
    
    String lruKey = _accessTimes.entries.reduce((a, b) => 
        a.value.isBefore(b.value) ? a : b).key;
    
    _removeFromMemoryCache(lruKey);
  }
  
  /// 更新访问时间
  static void _updateAccessTime(String key) {
    _accessTimes[key] = DateTime.now();
  }
  
  /// 清理内存缓存
  static void _cleanupMemoryCache() {
    while (_memoryCache.length > _maxMemoryItems || 
           _currentMemorySize > _maxMemorySize) {
      if (_memoryCache.isNotEmpty) {
        _evictLeastRecentlyUsed();
      } else {
        break;
      }
    }
  }
}

/// 缓存项
class _CacheItem {
  final dynamic data;
  final int size;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String type;
  
  _CacheItem({
    required this.data,
    required this.size,
    required this.createdAt,
    this.expiresAt,
    required this.type,
  });
}

/// 缓存配置
class CacheConfig {
  // 常见缓存类型的默认过期时间
  static const Map<String, Duration> defaultExpiry = {
    DatabaseConstants.cacheTypePageContent: Duration(hours: 24),
    DatabaseConstants.cacheTypeChapterList: Duration(days: 7),
    DatabaseConstants.cacheTypeBookList: Duration(hours: 1),
    DatabaseConstants.cacheTypeSearchResult: Duration(minutes: 30),
  };
  
  /// 获取缓存过期时间
  static Duration? getExpiryForType(String cacheType) {
    return defaultExpiry[cacheType];
  }
  
  /// 是否应该缓存
  static bool shouldCache(String cacheType, int dataSize) {
    // 超过10MB的数据不缓存在内存中
    if (dataSize > 10 * 1024 * 1024) return false;
    
    // 某些类型的数据总是缓存
    const alwaysCache = [
      DatabaseConstants.cacheTypeChapterList,
      DatabaseConstants.cacheTypeBookList,
    ];
    
    return alwaysCache.contains(cacheType) || dataSize < 1024 * 1024; // 1MB以下
  }
}
