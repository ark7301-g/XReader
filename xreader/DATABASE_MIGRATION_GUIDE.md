# 📚 XReader 数据库迁移指南

## 概述

本指南详细说明了从JSON文件存储迁移到高效SQLite数据库的完整过程。新的数据存储方案提供了显著的性能提升和功能改进。

## 🔄 迁移计划

### 迁移前后对比

| 特性 | 旧方案 (JSON) | 新方案 (SQLite + 缓存) |
|------|---------------|------------------------|
| **存储方式** | JSON文件 | SQLite数据库 + 分层缓存 |
| **查询性能** | O(n) 全文扫描 | O(log n) 索引查询 |
| **并发支持** | 单线程 | 多线程安全 |
| **事务支持** | ❌ | ✅ ACID事务 |
| **数据完整性** | ❌ | ✅ 外键约束 |
| **缓存机制** | ❌ | ✅ 内存+磁盘双层缓存 |
| **EPUB解析** | 基础信息 | 完整内容+分页+章节 |
| **书签笔记** | 禁用 | ✅ 完整支持 |
| **阅读统计** | 基础 | ✅ 详细分析 |

## 🚀 部署步骤

### 1. 依赖更新

在 `pubspec.yaml` 中：

```yaml
dependencies:
  # 数据库
  sqflite: ^2.3.0
  sqlite3_flutter_libs: ^0.5.15
  
  # 缓存
  cached_memory_image: ^0.2.5
  
  # 序列化
  equatable: ^2.0.5
```

### 2. 数据库初始化

主程序中已更新：

```dart
// lib/main.dart
import 'core/database/enhanced_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化增强数据库服务
  await EnhancedDatabaseService.initialize();
  
  runApp(const ProviderScope(child: XReaderApp()));
}
```

### 3. 自动数据迁移

系统会自动检测并迁移现有JSON数据：

```dart
// 迁移过程会自动执行以下步骤：
// 1. 检测旧JSON文件
// 2. 创建新数据库结构
// 3. 迁移现有书籍数据
// 4. 验证数据完整性
// 5. 备份旧数据
```

## 📊 数据库架构

### 核心表结构

```sql
-- 书籍主表
CREATE TABLE books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_path TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  author TEXT,
  -- ... 更多字段
);

-- 章节表
CREATE TABLE chapters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  start_page INTEGER NOT NULL,
  end_page INTEGER NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books (id)
);

-- 内容表（分页存储）
CREATE TABLE book_contents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  page_number INTEGER NOT NULL,
  content TEXT NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books (id)
);
```

### 缓存架构

```
内存缓存 (100MB)
├── 热点书籍信息
├── 最近阅读页面
└── 章节列表

SQLite缓存
├── 页面内容缓存
├── 搜索结果缓存
└── 统计数据缓存
```

## 🔧 性能优化

### 1. 索引策略

```sql
-- 自动创建的关键索引
CREATE INDEX idx_books_file_path ON books(file_path);
CREATE INDEX idx_books_last_read_date ON books(last_read_date);
CREATE INDEX idx_chapters_book_id ON chapters(book_id);
CREATE INDEX idx_book_contents_book_id ON book_contents(book_id);
```

### 2. 缓存配置

```dart
// 内存缓存限制
CacheManager.setMemoryLimits(
  maxItems: 200,        // 最大200个项目
  maxSize: 100 * 1024 * 1024,  // 100MB
);

// 缓存过期策略
- 页面内容: 24小时
- 章节列表: 7天
- 书籍列表: 1小时
- 搜索结果: 30分钟
```

### 3. 数据库优化

```dart
// 自动执行的优化
PRAGMA journal_mode = WAL;       // 写前日志
PRAGMA synchronous = NORMAL;     // 平衡安全性和性能
PRAGMA cache_size = -2000;       // 2MB缓存
PRAGMA mmap_size = 268435456;    // 256MB内存映射
```

## 📈 预期性能提升

### 查询性能

| 操作 | 旧方案耗时 | 新方案耗时 | 提升倍数 |
|------|------------|------------|----------|
| 加载书籍列表 | 500ms | 50ms | **10x** |
| 搜索书籍 | 2000ms | 100ms | **20x** |
| 获取章节列表 | 300ms | 20ms | **15x** |
| 加载页面内容 | 200ms | 10ms | **20x** |
| 更新阅读进度 | 400ms | 30ms | **13x** |

### 内存使用

| 场景 | 旧方案内存 | 新方案内存 | 优化 |
|------|------------|------------|------|
| 启动应用 | 50MB | 30MB | **40%** ↓ |
| 浏览书架 | 80MB | 45MB | **44%** ↓ |
| 阅读书籍 | 120MB | 60MB | **50%** ↓ |
| 大量书籍 | 200MB+ | 80MB | **60%** ↓ |

## 🛠️ 迁移验证

### 自动验证检查

```dart
// 系统会自动验证以下项目：
1. 数据库完整性检查
2. 外键约束验证
3. 书籍数量对比
4. 文件路径验证
5. 阅读进度一致性
```

### 手动验证步骤

1. **检查书籍数量**
   ```dart
   final oldCount = /* JSON文件中的书籍数量 */;
   final newCount = await EnhancedDatabaseService.getTotalBooksCount();
   assert(oldCount == newCount);
   ```

2. **验证功能完整性**
   - ✅ 书籍添加/删除
   - ✅ 阅读进度同步
   - ✅ 搜索功能
   - ✅ 书签和笔记（新功能）

3. **性能测试**
   ```dart
   // 加载1000本书的性能测试
   final stopwatch = Stopwatch()..start();
   final books = await EnhancedDatabaseService.getAllBooks();
   print('加载时间: ${stopwatch.elapsedMilliseconds}ms');
   ```

## 🔒 数据安全

### 备份策略

```dart
// 自动备份
1. 迁移前自动备份JSON文件
2. 数据库定期快照
3. 云端同步支持（未来版本）

// 手动备份
final backupPath = await EnhancedDatabaseService.backup('/path/to/backup');
```

### 恢复机制

```dart
// 数据恢复
if (数据库损坏) {
  await EnhancedDatabaseService.restore('/path/to/backup');
}

// 健康检查
final isHealthy = await DatabaseManager.checkHealth();
```

## 🚨 故障排除

### 常见问题

1. **迁移失败**
   ```
   原因: 磁盘空间不足
   解决: 清理至少500MB空间后重试
   ```

2. **性能下降**
   ```
   原因: 缓存未正确初始化
   解决: await EnhancedDatabaseService.optimize();
   ```

3. **数据丢失**
   ```
   原因: 迁移中断
   解决: 从自动备份恢复
   ```

### 日志监控

```dart
// 关键日志信息
✅ 数据库初始化成功
📊 数据库信息: 100本书籍, 2.5MB大小
🧹 清理了15条过期缓存
🔧 数据库优化完成
```

## 🎯 使用建议

### 最佳实践

1. **定期优化**
   ```dart
   // 建议每周执行一次
   await EnhancedDatabaseService.optimize();
   ```

2. **缓存管理**
   ```dart
   // 清理过期缓存
   await CacheManager.clearExpired();
   
   // 监控缓存使用
   final stats = await CacheManager.getStats();
   ```

3. **性能监控**
   ```dart
   // 获取详细统计
   final stats = await EnhancedDatabaseService.getServiceStats();
   ```

### 配置调优

```dart
// 根据设备性能调整
if (设备内存 > 4GB) {
  CacheManager.setMemoryLimits(maxSize: 200 * 1024 * 1024);
} else {
  CacheManager.setMemoryLimits(maxSize: 50 * 1024 * 1024);
}
```

## 📞 支持与反馈

如果在迁移过程中遇到问题：

1. 检查控制台日志获取详细错误信息
2. 确保有足够的磁盘空间（推荐1GB+）
3. 尝试重启应用重新初始化
4. 如问题持续，请提供错误日志以获得支持

---

**迁移完成后，您将享受到显著的性能提升和更强大的功能支持！** 🎉
