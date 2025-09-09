import 'database_manager.dart';
import 'database_schema.dart';
import 'cache_manager.dart';
import 'daos/book_dao.dart';
import '../epub/epub_parser.dart';
import '../epub/models/epub_book.dart';
import '../../data/models/book.dart';
import '../../features/reader/providers/reader_state.dart';

/// 增强的数据库服务
/// 
/// 这是新的高效数据库服务，提供以下改进：
/// - 基于SQLite的高性能存储
/// - 分层缓存机制
/// - 支持EPUB解析结果存储
/// - 完整的事务管理
/// - 性能监控和优化
class EnhancedDatabaseService {
  static bool _isInitialized = false;
  static EpubParser? _epubParser;
  
  /// 初始化数据库服务
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🚀 开始初始化增强数据库服务...');
      
      // 1. 初始化数据库管理器
      await DatabaseManager.initialize();
      
      // 2. 初始化缓存管理器
      CacheManager.setMemoryLimits(
        maxItems: 200,
        maxSize: 100 * 1024 * 1024, // 100MB
      );
      
      // 3. 清理可能存在问题的缓存
      await _cleanupProblematicCaches();
      
      // 4. 预热缓存
      await CacheManager.warmup();
      
      // 5. 初始化EPUB解析器
      _epubParser = EpubParser();
      
      // 6. 数据库健康检查
      final isHealthy = await DatabaseManager.checkHealth();
      if (!isHealthy) {
        print('⚠️ 数据库健康检查发现问题，尝试修复...');
        await DatabaseManager.optimize();
      }
      
      _isInitialized = true;
      
      // 打印统计信息
      await _printServiceStats();
      
      print('✅ 增强数据库服务初始化完成');
      
    } catch (e, stackTrace) {
      print('❌ 数据库服务初始化失败: $e');
      print('🔧 错误堆栈: $stackTrace');
      rethrow;
    }
  }
  
  /// 关闭数据库服务
  static Future<void> close() async {
    try {
      await CacheManager.clearAll();
      await DatabaseManager.close();
      _isInitialized = false;
      print('✅ 数据库服务已关闭');
    } catch (e) {
      print('❌ 关闭数据库服务失败: $e');
    }
  }
  
  // ===== 书籍管理 =====
  
  /// 添加书籍（解析EPUB并存储所有内容）
  static Future<int> addBook(Book book) async {
    _ensureInitialized();
    
    try {
      print('📚 开始添加书籍: ${book.title}');
      
      // 检查是否已存在
      final existingBook = await BookDao.getBookByFilePath(book.filePath);
      if (existingBook != null) {
        throw Exception('书籍已存在: ${book.title}');
      }
      
      EpubBookModel? epubBook;
      
      // 如果是EPUB文件，进行解析
      if (book.fileType.toLowerCase() == 'epub') {
        print('🔍 开始解析EPUB文件...');
        
        final parseResult = await _epubParser!.parseFile(book.filePath);
        if (parseResult.isSuccess) {
          epubBook = parseResult.book!;
          
          // 更新书籍信息（避免重复设置late字段）
          // book.title 已经在FileService中设置，不能重复设置
          book.author ??= epubBook.author;  // 只在author为null时设置
          book.language ??= epubBook.language;  // 只在language为null时设置
          book.publisher ??= epubBook.publisher;  // 只在publisher为null时设置  
          book.description ??= epubBook.description;  // 只在description为null时设置
          book.totalPages = epubBook.estimatedPageCount;
          
          print('✅ EPUB解析成功: ${epubBook.chapterCount}章节, ${epubBook.estimatedPageCount}页');
        } else {
          print('⚠️ EPUB解析失败，使用基本信息: ${parseResult.errorSummary}');
        }
      }
      
      // 保存到数据库
      final bookId = await BookDao.addBookWithContent(book, epubBook);
      
      // 事务完成后清理缓存
      try {
        await CacheManager.clearByType(DatabaseConstants.cacheTypeBookList);
        print('✅ 事务后缓存清除成功');
      } catch (cacheError) {
        print('⚠️ 事务后缓存清除失败: $cacheError');
      }
      
      print('✅ 书籍添加完成 (ID: $bookId)');
      return bookId;
      
    } catch (e) {
      print('❌ 添加书籍失败: $e');
      rethrow;
    }
  }
  
  /// 获取所有书籍
  static Future<List<Book>> getAllBooks() async {
    _ensureInitialized();
    return await BookDao.getAllBooks();
  }
  
  /// 根据ID获取书籍
  static Future<Book?> getBookById(int id) async {
    _ensureInitialized();
    return await BookDao.getBookById(id);
  }
  
  /// 根据文件路径获取书籍
  static Future<Book?> getBookByFilePath(String filePath) async {
    _ensureInitialized();
    return await BookDao.getBookByFilePath(filePath);
  }
  
  /// 更新书籍
  static Future<void> updateBook(Book book) async {
    _ensureInitialized();
    await BookDao.updateBook(book);
  }
  
  /// 删除书籍
  static Future<bool> deleteBook(int bookId) async {
    _ensureInitialized();
    return await BookDao.deleteBook(bookId);
  }
  
  /// 批量删除书籍
  static Future<int> deleteBooksById(List<int> bookIds) async {
    _ensureInitialized();
    return await BookDao.deleteBooksById(bookIds);
  }
  
  /// 搜索书籍
  static Future<List<Book>> searchBooks(String query) async {
    _ensureInitialized();
    if (query.trim().isEmpty) return [];
    return await BookDao.searchBooks(query);
  }
  
  // ===== 阅读进度管理 =====
  
  /// 更新阅读进度
  static Future<void> updateReadingProgress(
    int bookId,
    int currentPage,
    double progress, {
    String? position,
    int? readingTimeMinutes,
  }) async {
    _ensureInitialized();
    
    try {
      await DatabaseManager.transaction((txn) async {
        // 1. 更新书籍表的进度信息
        await txn.update(
          'books',
          {
            'current_page': currentPage,
            'reading_progress': progress,
            'last_read_position': position,
            'last_read_date': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
          where: 'id = ?',
          whereArgs: [bookId],
        );
        
        // 2. 更新或插入进度记录
        final existingProgress = await txn.query(
          'reading_progress',
          where: 'book_id = ?',
          whereArgs: [bookId],
        );
        
        if (existingProgress.isNotEmpty) {
          await txn.update(
            'reading_progress',
            {
              'current_page': currentPage,
              'progress_percentage': progress,
              'position': position,
              'reading_time_minutes': readingTimeMinutes ?? 0,
              'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            },
            where: 'book_id = ?',
            whereArgs: [bookId],
          );
        } else {
          await txn.insert('reading_progress', {
            'book_id': bookId,
            'current_page': currentPage,
            'progress_percentage': progress,
            'position': position,
            'reading_time_minutes': readingTimeMinutes ?? 0,
            'session_count': 1,
          });
        }
      });
      
      // 清除相关缓存
      await CacheManager.remove('book_$bookId');
      await CacheManager.clearByType('book_list');
      
    } catch (e) {
      print('❌ 更新阅读进度失败: $e');
    }
  }
  
  /// 添加阅读时间
  static Future<void> addReadingTime(int bookId, int minutes) async {
    _ensureInitialized();
    
    try {
      await DatabaseManager.transaction((txn) async {
        // 1. 更新书籍表
        await txn.rawUpdate('''
          UPDATE books 
          SET reading_time_minutes = reading_time_minutes + ?,
              total_reading_sessions = total_reading_sessions + 1,
              updated_at = ?
          WHERE id = ?
        ''', [minutes, DateTime.now().millisecondsSinceEpoch ~/ 1000, bookId]);
        
        // 2. 更新进度表
        await txn.rawUpdate('''
          UPDATE reading_progress 
          SET reading_time_minutes = reading_time_minutes + ?,
              session_count = session_count + 1,
              updated_at = ?
          WHERE book_id = ?
        ''', [minutes, DateTime.now().millisecondsSinceEpoch ~/ 1000, bookId]);
      });
      
      // 清除相关缓存
      await CacheManager.remove('book_$bookId');
      
    } catch (e) {
      print('❌ 添加阅读时间失败: $e');
    }
  }
  
  // ===== 书签管理 =====
  
  /// 添加书签
  static Future<void> addBookmark(int bookId, Bookmark bookmark) async {
    _ensureInitialized();
    
    try {
      await DatabaseManager.insert('bookmarks', {
        'book_id': bookId,
        'bookmark_id': bookmark.id,
        'page_number': bookmark.pageNumber,
        'chapter_title': bookmark.chapterTitle,
        'chapter_position': bookmark.chapterPosition,
        'note': bookmark.note,
        'selected_text': bookmark.selectedText,
        'bookmark_type': bookmark.type.index,
        'created_date': bookmark.createdDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      });
      
      print('✅ 书签添加成功');
    } catch (e) {
      print('❌ 添加书签失败: $e');
    }
  }
  
  /// 删除书签
  static Future<void> removeBookmark(int bookId, String bookmarkId) async {
    _ensureInitialized();
    
    try {
      await DatabaseManager.delete(
        'bookmarks',
        where: 'book_id = ? AND bookmark_id = ?',
        whereArgs: [bookId, bookmarkId],
      );
      
      print('✅ 书签删除成功');
    } catch (e) {
      print('❌ 删除书签失败: $e');
    }
  }
  
  /// 获取书籍的所有书签
  static Future<List<Bookmark>> getBookmarks(int bookId) async {
    _ensureInitialized();
    
    try {
      final results = await DatabaseManager.query(
        'bookmarks',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'page_number ASC, created_date ASC',
      );
      
      return results.map((map) => _mapToBookmark(map)).toList();
    } catch (e) {
      print('❌ 获取书签失败: $e');
      return [];
    }
  }
  
  // ===== 笔记管理 =====
  
  /// 添加笔记
  static Future<void> addNote(int bookId, Note note) async {
    _ensureInitialized();
    
    try {
      await DatabaseManager.insert('notes', {
        'book_id': bookId,
        'note_id': note.id,
        'page_number': note.pageNumber,
        'chapter_title': note.chapterTitle,
        'chapter_position': note.chapterPosition,
        'content': note.content,
        'selected_text': note.selectedText,
        'note_type': note.type.index,
        'created_date': note.createdDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        'modified_date': note.modifiedDate?.millisecondsSinceEpoch,
      });
      
      print('✅ 笔记添加成功');
    } catch (e) {
      print('❌ 添加笔记失败: $e');
    }
  }
  
  /// 更新笔记
  static Future<void> updateNote(int bookId, Note updatedNote) async {
    _ensureInitialized();
    
    try {
      await DatabaseManager.update(
        'notes',
        {
          'content': updatedNote.content,
          'modified_date': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'book_id = ? AND note_id = ?',
        whereArgs: [bookId, updatedNote.id],
      );
      
      print('✅ 笔记更新成功');
    } catch (e) {
      print('❌ 更新笔记失败: $e');
    }
  }
  
  /// 删除笔记
  static Future<void> removeNote(int bookId, String noteId) async {
    _ensureInitialized();
    
    try {
      await DatabaseManager.delete(
        'notes',
        where: 'book_id = ? AND note_id = ?',
        whereArgs: [bookId, noteId],
      );
      
      print('✅ 笔记删除成功');
    } catch (e) {
      print('❌ 删除笔记失败: $e');
    }
  }
  
  /// 获取书籍的所有笔记
  static Future<List<Note>> getNotes(int bookId) async {
    _ensureInitialized();
    
    try {
      final results = await DatabaseManager.query(
        'notes',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'page_number ASC, created_date ASC',
      );
      
      return results.map((map) => _mapToNote(map)).toList();
    } catch (e) {
      print('❌ 获取笔记失败: $e');
      return [];
    }
  }
  
  // ===== 章节和内容 =====
  
  /// 获取书籍章节
  static Future<List<Chapter>> getBookChapters(int bookId) async {
    _ensureInitialized();
    return await BookDao.getBookChapters(bookId);
  }
  
  /// 获取页面内容
  static Future<String?> getPageContent(int bookId, int pageNumber) async {
    _ensureInitialized();
    return await BookDao.getPageContent(bookId, pageNumber);
  }
  
  // ===== 统计和分析 =====
  
  /// 获取阅读统计
  static Future<ReadingStats> getReadingStats() async {
    _ensureInitialized();
    
    try {
      final stats = await BookDao.getStats();
      
      // 创建并返回统计对象
      final readingStats = ReadingStats();
      readingStats.totalBooks = stats['total_books'] ?? 0;
      readingStats.finishedBooks = stats['finished_books'] ?? 0;
      readingStats.readingBooks = stats['reading_books'] ?? 0;
      readingStats.totalReadingTimeMinutes = stats['total_reading_time'] ?? 0;
      // ... 设置其他统计字段
      
      return readingStats;
    } catch (e) {
      print('❌ 获取阅读统计失败: $e');
      return ReadingStats();
    }
  }
  
  /// 获取书籍总数
  static Future<int> getTotalBooksCount() async {
    _ensureInitialized();
    
    try {
      final result = await DatabaseManager.rawQuery(
        'SELECT COUNT(*) as count FROM books'
      );
      return result.first['count'] as int;
    } catch (e) {
      print('❌ 获取书籍总数失败: $e');
      return 0;
    }
  }
  
  // ===== 高级查询 =====
  
  /// 获取收藏的书籍
  static Future<List<Book>> getFavoriteBooks() async {
    _ensureInitialized();
    
    try {
      final results = await DatabaseManager.query(
        'books',
        where: 'is_favorite = 1',
        orderBy: 'last_read_date DESC, added_date DESC',
      );
      
      return results.map((map) => BookDao.mapToBook(map)).toList();
    } catch (e) {
      print('❌ 获取收藏书籍失败: $e');
      return [];
    }
  }
  
  /// 获取最近阅读的书籍
  static Future<List<Book>> getRecentlyReadBooks({int limit = 10}) async {
    _ensureInitialized();
    
    try {
      final results = await DatabaseManager.query(
        'books',
        where: 'last_read_date IS NOT NULL',
        orderBy: 'last_read_date DESC',
        limit: limit,
      );
      
      return results.map((map) => BookDao.mapToBook(map)).toList();
    } catch (e) {
      print('❌ 获取最近阅读书籍失败: $e');
      return [];
    }
  }
  
  /// 获取正在阅读的书籍
  static Future<List<Book>> getCurrentlyReadingBooks() async {
    _ensureInitialized();
    
    try {
      final results = await DatabaseManager.query(
        'books',
        where: 'reading_progress > 0 AND reading_progress < 1.0',
        orderBy: 'last_read_date DESC',
      );
      
      return results.map((map) => BookDao.mapToBook(map)).toList();
    } catch (e) {
      print('❌ 获取正在阅读书籍失败: $e');
      return [];
    }
  }
  
  /// 获取已完成的书籍
  static Future<List<Book>> getFinishedBooks() async {
    _ensureInitialized();
    
    try {
      final results = await DatabaseManager.query(
        'books',
        where: 'reading_progress >= 1.0',
        orderBy: 'last_read_date DESC',
      );
      
      return results.map((map) => BookDao.mapToBook(map)).toList();
    } catch (e) {
      print('❌ 获取已完成书籍失败: $e');
      return [];
    }
  }
  
  /// 按文件类型筛选
  static Future<List<Book>> getBooksByFileType(String fileType) async {
    _ensureInitialized();
    
    try {
      final results = await DatabaseManager.query(
        'books',
        where: 'file_type = ?',
        whereArgs: [fileType],
        orderBy: 'added_date DESC',
      );
      
      return results.map((map) => BookDao.mapToBook(map)).toList();
    } catch (e) {
      print('❌ 按文件类型筛选失败: $e');
      return [];
    }
  }
  
  // ===== 数据备份与恢复 =====
  
  /// 导出所有数据
  static Future<Map<String, dynamic>> exportAllData() async {
    _ensureInitialized();
    
    try {
      final books = await getAllBooks();
      final exportData = {
        'version': '2.0',
        'export_date': DateTime.now().toIso8601String(),
        'books': books.map((book) => book.toJson()).toList(),
        'database_stats': await DatabaseManager.getStats(),
        'cache_stats': await CacheManager.getStats(),
      };
      
      print('✅ 数据导出完成，包含${books.length}本书籍');
      return exportData;
    } catch (e) {
      print('❌ 导出数据失败: $e');
      return {};
    }
  }
  
  /// 清空所有数据
  static Future<void> clearAllData() async {
    _ensureInitialized();
    
    try {
      await CacheManager.clearAll();
      await DatabaseManager.clearAllData();
      print('✅ 所有数据已清空');
    } catch (e) {
      print('❌ 清空数据失败: $e');
      rethrow;
    }
  }
  
  // ===== 性能和维护 =====
  
  /// 优化数据库
  static Future<void> optimize() async {
    _ensureInitialized();
    
    try {
      print('🔧 开始优化数据库...');
      
      // 1. 清理过期缓存
      await CacheManager.clearExpired();
      
      // 2. 优化数据库
      await DatabaseManager.optimize();
      
      // 3. 预热缓存
      await CacheManager.warmup();
      
      print('✅ 数据库优化完成');
      await _printServiceStats();
      
    } catch (e) {
      print('❌ 数据库优化失败: $e');
    }
  }
  
  /// 获取服务统计信息
  static Future<Map<String, dynamic>> getServiceStats() async {
    _ensureInitialized();
    
    final dbStats = await DatabaseManager.getStats();
    final cacheStats = await CacheManager.getStats();
    final bookStats = await BookDao.getStats();
    
    return {
      'database': dbStats,
      'cache': cacheStats,
      'books': bookStats,
      'service': {
        'is_initialized': _isInitialized,
        'epub_parser': _epubParser != null,
      },
    };
  }
  
  /// 打印服务统计信息
  static Future<void> _printServiceStats() async {
    try {
      final stats = await getServiceStats();
      
      print('📊 数据库服务统计:');
      print('   📚 书籍总数: ${stats['books']['total_books'] ?? 0}');
      print('   💾 数据库大小: ${stats['database']['database_size'] != null ? _formatBytes(stats['database']['database_size']) : "未知"}');
      print('   🧠 缓存项目: ${stats['cache']['combined']['total_items'] ?? 0}');
      print('   💾 缓存大小: ${stats['cache']['combined']['total_size_mb'] ?? "0"}MB');
      
    } catch (e) {
      print('⚠️ 获取服务统计失败: $e');
    }
  }
  
  /// 格式化字节大小
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 确保服务已初始化
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('数据库服务未初始化，请先调用 initialize()');
    }
  }
  
  /// 将Map转换为Bookmark对象
  static Bookmark _mapToBookmark(Map<String, dynamic> map) {
    return Bookmark(
      id: map['bookmark_id'] as String,
      pageNumber: map['page_number'] as int,
      chapterTitle: map['chapter_title'] as String,
      chapterPosition: map['chapter_position'] as String?,
      createdDate: map['created_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_date'] as int)
          : null,
      note: map['note'] as String?,
      selectedText: map['selected_text'] as String?,
      type: BookmarkType.values[map['bookmark_type'] as int? ?? 0],
    );
  }
  
  /// 将Map转换为Note对象
  static Note _mapToNote(Map<String, dynamic> map) {
    return Note(
      id: map['note_id'] as String,
      pageNumber: map['page_number'] as int,
      chapterTitle: map['chapter_title'] as String,
      chapterPosition: map['chapter_position'] as String?,
      createdDate: map['created_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_date'] as int)
          : null,
      modifiedDate: map['modified_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['modified_date'] as int)
          : null,
      content: map['content'] as String,
      selectedText: map['selected_text'] as String?,
      type: NoteType.values[map['note_type'] as int? ?? 0],
    );
  }
  
  /// 清理可能存在问题的缓存
  static Future<void> _cleanupProblematicCaches() async {
    try {
      print('🧹 开始清理可能存在问题的缓存...');
      
      // 清理所有book_list类型的缓存，这些可能存在格式问题
      await CacheManager.clearByType(DatabaseConstants.cacheTypeBookList);
      
      // 清理所有以all_books开头的缓存项
      final cacheStats = await CacheManager.getStats();
      final dbStats = cacheStats['database'] as Map<String, dynamic>?;
      
      if (dbStats != null) {
        final typeStats = dbStats['by_type'] as Map<String, dynamic>?;
        if (typeStats?.containsKey(DatabaseConstants.cacheTypeBookList) == true) {
          print('🧹 清除了book_list类型的缓存');
        }
      }
      
      print('✅ 缓存清理完成');
      
    } catch (e) {
      print('❌ 缓存清理失败: $e');
      // 不要重新抛出错误，因为这不是致命问题
    }
  }
}
