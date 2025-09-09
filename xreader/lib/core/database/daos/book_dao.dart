import 'dart:convert';
import '../database_manager.dart';
import '../database_schema.dart';
import '../cache_manager.dart';
import '../../epub/models/epub_book.dart';
import '../../../data/models/book.dart';
import '../../../features/reader/providers/reader_state.dart';

/// 书籍数据访问对象
/// 
/// 负责书籍相关的所有数据库操作，包括：
/// - 基本CRUD操作
/// - 复杂查询和统计
/// - 缓存管理
/// - EPUB解析结果存储
class BookDao {
  /// 添加书籍
  static Future<int> addBook(Book book) async {
    try {
      final id = await DatabaseManager.insert(
        DatabaseConstants.booksTable,
        _bookToMap(book),
      );
      
      // 清除相关缓存
      await CacheManager.clearByType(DatabaseConstants.cacheTypeBookList);
      
      print('✅ 书籍添加成功: ${book.title} (ID: $id)');
      return id;
    } catch (e) {
      print('❌ 添加书籍失败: $e');
      rethrow;
    }
  }
  
  /// 添加书籍及其解析内容
  static Future<int> addBookWithContent(Book book, EpubBookModel? epubBook) async {
    return await DatabaseManager.transaction((txn) async {
      int? bookId;
      try {
        // 1. 添加基本书籍信息
        print('🔍 准备插入书籍信息: ${book.title}');
        final bookMap = _bookToMap(book);
        print('📋 书籍数据映射: $bookMap');
        
        bookId = await txn.insert(
          DatabaseConstants.booksTable,
          bookMap,
        );
        
        print('✅ 书籍基本信息插入成功，ID: $bookId');
        
        if (epubBook != null) {
          // 验证bookId有效性
          final verifyBook = await txn.query(
            DatabaseConstants.booksTable,
            where: 'id = ?',
            whereArgs: [bookId],
            limit: 1,
          );
          
          if (verifyBook.isEmpty) {
            throw Exception('书籍插入失败：无法验证插入的书籍记录');
          }
          
          print('✅ 书籍记录验证成功，继续插入相关内容');
          
          // 2. 添加章节信息
          if (epubBook.chapters.isNotEmpty) {
            await _insertChapters(txn, bookId, epubBook.chapters);
          } else {
            print('⚠️ 没有章节信息需要插入');
          }
          
          // 3. 添加内容信息
          if (epubBook.contentFiles.isNotEmpty) {
            await _insertContents(txn, bookId, epubBook.contentFiles);
          } else {
            print('⚠️ 没有内容文件需要插入');
          }
          
          // 4. 更新书籍的解析元数据
          final updateResult = await txn.update(
            DatabaseConstants.booksTable,
            {
              'parsing_metadata': json.encode(epubBook.parsingMetadata.toJson()),
              'epub_version': epubBook.version,
              'total_pages': epubBook.estimatedPageCount,
            },
            where: 'id = ?',
            whereArgs: [bookId],
          );
          
          if (updateResult == 0) {
            print('⚠️ 更新书籍元数据失败，但不影响主流程');
          } else {
            print('✅ 书籍元数据更新成功');
          }
        }
        
        // 暂时跳过缓存清理，避免事务冲突
        print('! 跳过事务中的缓存清理（将在事务完成后处理）');
        
        print('✅ 书籍及内容添加成功: ${book.title} (ID: $bookId)');
        return bookId;
        
      } catch (e) {
        print('❌ 添加书籍及内容失败: $e');
        print('❌ 错误类型: ${e.runtimeType}');
        if (bookId != null) {
          print('❌ 失败的书籍ID: $bookId');
        }
        // 事务会自动回滚，但我们可以记录更多调试信息
        if (e.toString().contains('FOREIGN KEY constraint failed')) {
          print('💡 建议检查数据库外键约束设置');
        }
        rethrow;
      }
    });
  }
  
  /// 获取所有书籍
  static Future<List<Book>> getAllBooks({
    bool useCache = true,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final cacheKey = 'all_books_${orderBy ?? 'default'}_${limit ?? 'all'}_${offset ?? '0'}';
      
      if (useCache) {
        final cached = await CacheManager.get<List<Book>>(
          cacheKey,
          maxAge: const Duration(hours: 1),
          fromJson: (json) => (json['books'] as List)
              .map((item) => Book.fromJson(item))
              .toList(),
        );
        
        if (cached != null) {
          return cached;
        }
      }
      
      final results = await DatabaseManager.query(
        DatabaseConstants.booksTable,
        orderBy: orderBy ?? 'added_date DESC',
        limit: limit,
        offset: offset,
      );
      
      final books = results.map((map) => mapToBook(map)).toList();
      
      // 缓存结果
      if (useCache && books.isNotEmpty) {
        await CacheManager.put(
          cacheKey,
          {'books': books.map((b) => b.toJson()).toList()},
          cacheType: DatabaseConstants.cacheTypeBookList,
          expiry: const Duration(hours: 1),
        );
      }
      
      return books;
    } catch (e) {
      print('❌ 获取所有书籍失败: $e');
      return [];
    }
  }
  
  /// 根据ID获取书籍
  static Future<Book?> getBookById(int id, {bool includeContent = false}) async {
    try {
      final cacheKey = 'book_$id${includeContent ? '_with_content' : ''}';
      
      // 尝试从缓存获取
      final cached = await CacheManager.get<Book>(
        cacheKey,
        maxAge: const Duration(hours: 12),
        fromJson: (json) => Book.fromJson(json),
      );
      
      if (cached != null) {
        return cached;
      }
      
      final results = await DatabaseManager.query(
        DatabaseConstants.booksTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (results.isEmpty) return null;
      
      final book = mapToBook(results.first);
      
      if (includeContent) {
        // 加载章节信息
        await getBookChapters(id);
        // 这里可以根据需要加载更多内容
      }
      
      // 缓存结果
      await CacheManager.put(
        cacheKey,
        book.toJson(),
        cacheType: DatabaseConstants.cacheTypeBookList,
        expiry: const Duration(hours: 12),
      );
      
      return book;
    } catch (e) {
      print('❌ 获取书籍失败 (ID: $id): $e');
      return null;
    }
  }
  
  /// 根据文件路径获取书籍
  static Future<Book?> getBookByFilePath(String filePath) async {
    try {
      final results = await DatabaseManager.query(
        DatabaseConstants.booksTable,
        where: 'file_path = ?',
        whereArgs: [filePath],
        limit: 1,
      );
      
      if (results.isEmpty) return null;
      
      return mapToBook(results.first);
    } catch (e) {
      print('❌ 根据文件路径获取书籍失败: $e');
      return null;
    }
  }
  
  /// 更新书籍
  static Future<void> updateBook(Book book) async {
    try {
      await DatabaseManager.update(
        DatabaseConstants.booksTable,
        _bookToMap(book),
        where: 'id = ?',
        whereArgs: [book.id],
      );
      
      // 清除相关缓存
      await CacheManager.remove('book_${book.id}');
      await CacheManager.remove('book_${book.id}_with_content');
      await CacheManager.clearByType(DatabaseConstants.cacheTypeBookList);
      
      print('✅ 书籍更新成功: ${book.title}');
    } catch (e) {
      print('❌ 更新书籍失败: $e');
      rethrow;
    }
  }
  
  /// 删除书籍
  static Future<bool> deleteBook(int bookId) async {
    try {
      final result = await DatabaseManager.delete(
        DatabaseConstants.booksTable,
        where: 'id = ?',
        whereArgs: [bookId],
      );
      
      if (result > 0) {
        // 清除相关缓存
        await CacheManager.remove('book_$bookId');
        await CacheManager.remove('book_${bookId}_with_content');
        await CacheManager.clearByType(DatabaseConstants.cacheTypeBookList);
        await CacheManager.clearByType(DatabaseConstants.cacheTypePageContent);
        
        print('✅ 书籍删除成功 (ID: $bookId)');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ 删除书籍失败: $e');
      return false;
    }
  }
  
  /// 批量删除书籍
  static Future<int> deleteBooksById(List<int> bookIds) async {
    try {
      if (bookIds.isEmpty) return 0;
      
      final placeholders = bookIds.map((_) => '?').join(',');
      final result = await DatabaseManager.rawExecute(
        'DELETE FROM ${DatabaseConstants.booksTable} WHERE id IN ($placeholders)',
        bookIds,
      );
      
      // 清除相关缓存
      for (final id in bookIds) {
        await CacheManager.remove('book_$id');
        await CacheManager.remove('book_${id}_with_content');
      }
      await CacheManager.clearByType(DatabaseConstants.cacheTypeBookList);
      await CacheManager.clearByType(DatabaseConstants.cacheTypePageContent);
      
      print('✅ 批量删除 $result 本书籍');
      return result;
    } catch (e) {
      print('❌ 批量删除书籍失败: $e');
      return 0;
    }
  }
  
  /// 搜索书籍
  static Future<List<Book>> searchBooks(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final cacheKey = 'search_${query.hashCode}_${limit}_$offset';
      
      // 尝试从缓存获取
      final cached = await CacheManager.get<List<Book>>(
        cacheKey,
        maxAge: const Duration(minutes: 30),
        fromJson: (json) => (json['books'] as List)
            .map((item) => Book.fromJson(item))
            .toList(),
      );
      
      if (cached != null) {
        return cached;
      }
      
      final searchTerm = '%${query.toLowerCase()}%';
      final results = await DatabaseManager.query(
        DatabaseConstants.booksTable,
        where: 'LOWER(title) LIKE ? OR LOWER(author) LIKE ? OR LOWER(description) LIKE ?',
        whereArgs: [searchTerm, searchTerm, searchTerm],
        orderBy: 'last_read_date DESC, added_date DESC',
        limit: limit,
        offset: offset,
      );
      
      final books = results.map((map) => mapToBook(map)).toList();
      
      // 缓存结果
      if (books.isNotEmpty) {
        await CacheManager.put(
          cacheKey,
          {'books': books.map((b) => b.toJson()).toList()},
          cacheType: DatabaseConstants.cacheTypeSearchResult,
          expiry: const Duration(minutes: 30),
        );
      }
      
      return books;
    } catch (e) {
      print('❌ 搜索书籍失败: $e');
      return [];
    }
  }
  
  /// 获取书籍章节
  static Future<List<Chapter>> getBookChapters(int bookId, {bool useCache = true}) async {
    try {
      final cacheKey = 'chapters_$bookId';
      
      if (useCache) {
        final cached = await CacheManager.get<List<Chapter>>(
          cacheKey,
          maxAge: const Duration(days: 7),
          fromJson: (json) => (json['chapters'] as List)
              .map((item) => Chapter.fromJson(item))
              .toList(),
        );
        
        if (cached != null) {
          return cached;
        }
      }
      
      final results = await DatabaseManager.query(
        DatabaseConstants.chaptersTable,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'sort_order ASC, start_page ASC',
      );
      
      final chapters = results.map((map) => _mapToChapter(map)).toList();
      
      // 缓存结果
      if (useCache && chapters.isNotEmpty) {
        await CacheManager.put(
          cacheKey,
          {'chapters': chapters.map((c) => c.toJson()).toList()},
          cacheType: DatabaseConstants.cacheTypeChapterList,
          expiry: const Duration(days: 7),
        );
      }
      
      return chapters;
    } catch (e) {
      print('❌ 获取书籍章节失败: $e');
      return [];
    }
  }
  
  /// 获取页面内容
  static Future<String?> getPageContent(int bookId, int pageNumber) async {
    try {
      final cacheKey = 'page_${bookId}_$pageNumber';
      
      // 尝试从缓存获取
      final cached = await CacheManager.get<String>(
        cacheKey,
        maxAge: const Duration(days: 1),
      );
      
      if (cached != null) {
        return cached;
      }
      
      final results = await DatabaseManager.query(
        DatabaseConstants.bookContentsTable,
        columns: ['content'],
        where: 'book_id = ? AND page_number = ?',
        whereArgs: [bookId, pageNumber],
        limit: 1,
      );
      
      if (results.isEmpty) return null;
      
      final content = results.first['content'] as String;
      
      // 缓存结果
      await CacheManager.put(
        cacheKey,
        content,
        cacheType: DatabaseConstants.cacheTypePageContent,
        expiry: const Duration(days: 1),
      );
      
      return content;
    } catch (e) {
      print('❌ 获取页面内容失败: $e');
      return null;
    }
  }
  
  /// 获取统计信息
  static Future<Map<String, dynamic>> getStats() async {
    try {
      const cacheKey = 'book_stats';
      
      // 尝试从缓存获取
      final cached = await CacheManager.get<Map<String, dynamic>>(
        cacheKey,
        maxAge: const Duration(hours: 1),
      );
      
      if (cached != null) {
        return cached;
      }
      
      const statsQuery = '''
        SELECT 
          COUNT(*) as total_books,
          COUNT(CASE WHEN reading_progress > 0 AND reading_progress < 1.0 THEN 1 END) as reading_books,
          COUNT(CASE WHEN reading_progress >= 1.0 THEN 1 END) as finished_books,
          COUNT(CASE WHEN reading_progress = 0 THEN 1 END) as unread_books,
          COUNT(CASE WHEN is_favorite = 1 THEN 1 END) as favorite_books,
          SUM(reading_time_minutes) as total_reading_time,
          AVG(reading_progress) as average_progress,
          SUM(file_size) as total_file_size,
          COUNT(CASE WHEN file_type = 'epub' THEN 1 END) as epub_books,
          COUNT(CASE WHEN file_type = 'pdf' THEN 1 END) as pdf_books
        FROM ${DatabaseConstants.booksTable}
      ''';
      
      final results = await DatabaseManager.rawQuery(statsQuery);
      final stats = results.first;
      
      // 缓存结果
      await CacheManager.put(
        cacheKey,
        stats,
        cacheType: DatabaseConstants.cacheTypeBookList,
        expiry: const Duration(hours: 1),
      );
      
      return stats;
    } catch (e) {
      print('❌ 获取统计信息失败: $e');
      return {};
    }
  }
  
  /// 插入章节信息
  static Future<void> _insertChapters(dynamic txn, int bookId, List<EpubChapterModel> chapters) async {
    try {
      print('📖 开始插入 ${chapters.length} 个章节');
      
      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        try {
          await txn.insert(DatabaseConstants.chaptersTable, {
            'book_id': bookId,
            'chapter_id': chapter.id,
            'title': chapter.title,
            'level': chapter.level,
            'href': chapter.href,
            'anchor': chapter.anchor,
            'start_page': chapter.startPage,
            'end_page': chapter.endPage,
            'sort_order': i,
          });
        } catch (chapterError) {
          print('❌ 插入章节失败: ${chapter.title}, 错误: $chapterError');
          print('📋 章节数据: bookId=$bookId, chapterId=${chapter.id}');
          rethrow;
        }
      }
      
      print('✅ 章节插入完成: ${chapters.length}个章节');
    } catch (e) {
      print('❌ 批量插入章节失败: $e');
      print('📋 BookId: $bookId');
      print('📋 章节总数: ${chapters.length}');
      rethrow;
    }
  }
  
  /// 插入内容信息（批量优化）
  static Future<void> _insertContents(dynamic txn, int bookId, List<EpubContentFile> contentFiles) async {
    try {
      // 首先验证bookId是否有效
      print('🔍 验证bookId: $bookId');
      final bookExists = await txn.query(
        DatabaseConstants.booksTable,
        where: 'id = ?',
        whereArgs: [bookId],
        limit: 1,
      );
      
      if (bookExists.isEmpty) {
        throw Exception('外键约束错误: 找不到对应的书籍记录 (bookId: $bookId)');
      }
      
      // 批量准备所有要插入的数据
      final List<Map<String, dynamic>> contentBatch = [];
      
      for (final contentFile in contentFiles) {
        for (int i = 0; i < contentFile.pages.length; i++) {
          final pageContent = contentFile.pages[i];
          contentBatch.add({
            'book_id': bookId,
            'content_file_id': contentFile.id,
            'href': contentFile.href,
            'media_type': contentFile.mediaType,
            'page_number': i + 1,  // 页码从1开始，而不是从0开始
            'content': pageContent,
            'raw_content': contentFile.rawContent,
            'content_length': pageContent.length,
            'processing_strategy': contentFile.processingInfo.strategy,
            'processing_time': contentFile.processingInfo.processingTime.inMilliseconds,
            'quality_score': contentFile.processingInfo.qualityScore,
          });
        }
      }
      
      print('📄 准备插入 ${contentBatch.length} 条内容记录');
      
      // 分批插入以避免数据库锁定（每批50条记录，减少批量大小）
      const batchSize = 50;
      for (int i = 0; i < contentBatch.length; i += batchSize) {
        final end = (i + batchSize < contentBatch.length) ? i + batchSize : contentBatch.length;
        final batch = contentBatch.sublist(i, end);
        
        for (final record in batch) {
          try {
            await txn.insert(DatabaseConstants.bookContentsTable, record);
          } catch (insertError) {
            print('❌ 插入单条记录失败: $insertError');
            print('📋 记录内容: $record');
            rethrow;
          }
        }
        
        print('📄 批量插入内容进度: $end/${contentBatch.length}');
      }
      
      print('✅ 内容插入完成: ${contentBatch.length}条记录');
    } catch (e) {
      print('❌ 插入内容失败: $e');
      print('📋 BookId: $bookId');
      print('📋 内容文件数: ${contentFiles.length}');
      rethrow;
    }
  }
  
  /// 将Book对象转换为Map
  static Map<String, dynamic> _bookToMap(Book book) {
    return {
      if (book.id != 0) 'id': book.id,
      'file_path': book.filePath,
      'title': book.title,
      'author': book.author,
      'publisher': book.publisher,
      'description': book.description,
      'language': book.language,
      'cover_path': book.coverPath,
      'file_type': book.fileType,
      'file_size': book.fileSize,
      'added_date': book.addedDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'last_read_date': book.lastReadDate?.millisecondsSinceEpoch,
      'publish_date': book.publishDate?.millisecondsSinceEpoch,
      'current_page': book.currentPage,
      'total_pages': book.totalPages,
      'reading_progress': book.readingProgress,
      'last_read_position': book.lastReadPosition,
      'reading_time_minutes': book.readingTimeMinutes,
      'total_reading_sessions': book.totalReadingSessions,
      'is_favorite': book.isFavorite ? 1 : 0,
      'rating': book.rating,
      'custom_font_size': book.customFontSize,
      'custom_line_height': book.customLineHeight,
      'custom_font_family': book.customFontFamily,
      'custom_theme_mode': book.customThemeMode,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }
  
  /// 将Map转换为Book对象
  static Book mapToBook(Map<String, dynamic> map) {
    final book = Book();
    book.id = map['id'] as int;
    book.filePath = map['file_path'] as String;
    book.title = map['title'] as String;
    book.author = map['author'] as String?;
    book.publisher = map['publisher'] as String?;
    book.description = map['description'] as String?;
    book.language = map['language'] as String?;
    book.coverPath = map['cover_path'] as String?;
    book.fileType = map['file_type'] as String;
    book.fileSize = map['file_size'] as int;
    book.addedDate = map['added_date'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['added_date'] as int)
        : null;
    book.lastReadDate = map['last_read_date'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['last_read_date'] as int)
        : null;
    book.publishDate = map['publish_date'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['publish_date'] as int)
        : null;
    book.currentPage = map['current_page'] as int? ?? 0;
    book.totalPages = map['total_pages'] as int? ?? 0;
    book.readingProgress = (map['reading_progress'] as num?)?.toDouble() ?? 0.0;
    book.lastReadPosition = map['last_read_position'] as String?;
    book.readingTimeMinutes = map['reading_time_minutes'] as int? ?? 0;
    book.totalReadingSessions = map['total_reading_sessions'] as int? ?? 0;
    book.isFavorite = (map['is_favorite'] as int?) == 1;
    book.rating = map['rating'] as int? ?? 0;
    book.customFontSize = (map['custom_font_size'] as num?)?.toDouble();
    book.customLineHeight = (map['custom_line_height'] as num?)?.toDouble();
    book.customFontFamily = map['custom_font_family'] as String?;
    book.customThemeMode = map['custom_theme_mode'] as int?;
    
    return book;
  }
  
  /// 将Map转换为Chapter对象
  static Chapter _mapToChapter(Map<String, dynamic> map) {
    return Chapter(
      id: map['chapter_id'] as String,
      title: map['title'] as String,
      startPage: map['start_page'] as int,
      endPage: map['end_page'] as int,
      href: map['href'] as String?,
      level: map['level'] as int? ?? 1,
    );
  }
}

/// 扩展EpubParsingMetadata以支持JSON序列化
extension EpubParsingMetadataJson on EpubParsingMetadata {
  Map<String, dynamic> toJson() {
    return {
      'processing_time_ms': processingTime.inMilliseconds,
      'strategies_used': strategiesUsed,
      'error_count': errors.length,
      'warning_count': warnings.length,
      'estimated_pages': estimatedPages,
      'parsing_version': parsingVersion,
      'diagnostics': diagnostics,
    };
  }
  
  static EpubParsingMetadata fromJson(Map<String, dynamic> json) {
    return EpubParsingMetadata(
      processingTime: Duration(milliseconds: json['processing_time_ms'] ?? 0),
      strategiesUsed: List<String>.from(json['strategies_used'] ?? []),
      errors: [], // 简化，不保存详细错误信息
      warnings: [], // 简化，不保存详细警告信息
      estimatedPages: json['estimated_pages'] ?? 0,
      parsingVersion: json['parsing_version'] ?? '',
      diagnostics: Map<String, dynamic>.from(json['diagnostics'] ?? {}),
    );
  }
}
