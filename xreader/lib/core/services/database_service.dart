import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../data/models/book.dart';

/// 数据库服务类 (简化实现，使用JSON文件存储)
class DatabaseService {
  static File? _booksFile;
  static List<Book> _booksCache = [];
  static bool _isInitialized = false;
  
  /// 初始化数据库
  static Future<void> initialize() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(path.join(documentsDir.path, 'xreader_db'));
      
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      
      _booksFile = File(path.join(dbDir.path, 'books.json'));
      
      // 加载现有书籍数据
      await _loadBooksFromFile();
      
      _isInitialized = true;
      print('数据库初始化成功 (JSON存储)');
    } catch (e) {
      print('数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 从文件加载书籍数据
  static Future<void> _loadBooksFromFile() async {
    try {
      if (_booksFile != null && await _booksFile!.exists()) {
        final jsonString = await _booksFile!.readAsString();
        if (jsonString.isNotEmpty) {
          final List<dynamic> jsonList = json.decode(jsonString);
          _booksCache = jsonList.map((json) => Book.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('加载书籍数据失败: $e');
      _booksCache = [];
    }
  }

  /// 保存书籍数据到文件
  static Future<void> _saveBooksToFile() async {
    try {
      if (_booksFile != null) {
        final jsonList = _booksCache.map((book) => book.toJson()).toList();
        final jsonString = json.encode(jsonList);
        await _booksFile!.writeAsString(jsonString);
      }
    } catch (e) {
      print('保存书籍数据失败: $e');
    }
  }
  
  /// 关闭数据库 (暂时注释掉)
  static Future<void> close() async {
    print('数据库关闭已暂时禁用');
  }
  
  // ===== 书籍管理 (暂时返回默认值) =====
  
  /// 添加书籍
  static Future<int> addBook(Book book) async {
    if (!_isInitialized) {
      throw Exception('数据库未初始化');
    }
    
    try {
      // 生成新的ID
      final newId = _booksCache.isEmpty 
          ? 1 
          : _booksCache.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
      
      book.id = newId;
      book.addedDate = DateTime.now();
      
      _booksCache.add(book);
      await _saveBooksToFile();
      
      print('书籍添加成功: ${book.title}');
      return newId;
    } catch (e) {
      print('添加书籍失败: $e');
      rethrow;
    }
  }
  
  /// 获取所有书籍
  static Future<List<Book>> getAllBooks() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _loadBooksFromFile(); // 确保获取最新数据
      return List<Book>.from(_booksCache);
    } catch (e) {
      print('获取书籍列表失败: $e');
      return <Book>[];
    }
  }
  
  /// 按ID获取书籍
  static Future<Book?> getBookById(int id) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _loadBooksFromFile();
      return _booksCache.where((book) => book.id == id).isNotEmpty
          ? _booksCache.firstWhere((book) => book.id == id)
          : null;
    } catch (e) {
      print('按ID获取书籍失败: $e');
      return null;
    }
  }
  
  /// 按文件路径获取书籍
  static Future<Book?> getBookByFilePath(String filePath) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _loadBooksFromFile();
      return _booksCache.where((book) => book.filePath == filePath).isNotEmpty
          ? _booksCache.firstWhere((book) => book.filePath == filePath)
          : null;
    } catch (e) {
      print('按路径获取书籍失败: $e');
      return null;
    }
  }
  
  /// 更新书籍
  static Future<void> updateBook(Book book) async {
    if (!_isInitialized) {
      throw Exception('数据库未初始化');
    }
    
    try {
      final index = _booksCache.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _booksCache[index] = book;
        await _saveBooksToFile();
        print('书籍更新成功: ${book.title}');
      } else {
        throw Exception('书籍不存在: ${book.id}');
      }
    } catch (e) {
      print('更新书籍失败: $e');
      rethrow;
    }
  }
  
  /// 删除书籍 (暂时返回false)
  static Future<bool> deleteBook(int bookId) async {
    print('删除书籍功能暂时禁用: $bookId');
    return false;
  }
  
  /// 批量删除书籍 (暂时返回0)
  static Future<int> deleteBooksById(List<int> bookIds) async {
    print('批量删除书籍功能暂时禁用: $bookIds');
    return 0;
  }
  
  // ===== 阅读进度管理 (暂时无操作) =====
  
  /// 更新阅读进度 (暂时无操作)
  static Future<void> updateReadingProgress(
    int bookId, 
    int currentPage, 
    double progress, {
    String? position,
    int? readingTimeMinutes,
  }) async {
    print('更新阅读进度功能暂时禁用: bookId=$bookId, page=$currentPage');
  }
  
  /// 添加阅读时间 (暂时无操作)
  static Future<void> addReadingTime(int bookId, int minutes) async {
    print('添加阅读时间功能暂时禁用: bookId=$bookId, minutes=$minutes');
  }
  
  // ===== 书签管理 (暂时无操作) =====
  
  /// 添加书签 (暂时无操作)
  static Future<void> addBookmark(int bookId, Bookmark bookmark) async {
    print('添加书签功能暂时禁用: bookId=$bookId');
  }
  
  /// 删除书签 (暂时无操作)
  static Future<void> removeBookmark(int bookId, String bookmarkId) async {
    print('删除书签功能暂时禁用: bookId=$bookId');
  }
  
  /// 获取书籍的所有书签 (暂时返回空列表)
  static Future<List<Bookmark>> getBookmarks(int bookId) async {
    print('获取书签功能暂时禁用: bookId=$bookId');
    return <Bookmark>[];
  }
  
  // ===== 笔记管理 (暂时无操作) =====
  
  /// 添加笔记 (暂时无操作)
  static Future<void> addNote(int bookId, Note note) async {
    print('添加笔记功能暂时禁用: bookId=$bookId');
  }
  
  /// 更新笔记 (暂时无操作)
  static Future<void> updateNote(int bookId, Note updatedNote) async {
    print('更新笔记功能暂时禁用: bookId=$bookId');
  }
  
  /// 删除笔记 (暂时无操作)
  static Future<void> removeNote(int bookId, String noteId) async {
    print('删除笔记功能暂时禁用: bookId=$bookId');
  }
  
  /// 获取书籍的所有笔记 (暂时返回空列表)
  static Future<List<Note>> getNotes(int bookId) async {
    print('获取笔记功能暂时禁用: bookId=$bookId');
    return <Note>[];
  }
  
  // ===== 搜索和筛选 (暂时返回空列表) =====
  
  /// 搜索书籍 (暂时返回空列表)
  static Future<List<Book>> searchBooks(String query) async {
    print('搜索书籍功能暂时禁用: $query');
    return <Book>[];
  }
  
  /// 获取收藏的书籍 (暂时返回空列表)
  static Future<List<Book>> getFavoriteBooks() async {
    print('获取收藏书籍功能暂时禁用');
    return <Book>[];
  }
  
  /// 获取最近阅读的书籍 (暂时返回空列表)
  static Future<List<Book>> getRecentlyReadBooks({int limit = 10}) async {
    print('获取最近阅读书籍功能暂时禁用');
    return <Book>[];
  }
  
  /// 获取正在阅读的书籍 (暂时返回空列表)
  static Future<List<Book>> getCurrentlyReadingBooks() async {
    print('获取正在阅读书籍功能暂时禁用');
    return <Book>[];
  }
  
  /// 获取已完成的书籍 (暂时返回空列表)
  static Future<List<Book>> getFinishedBooks() async {
    print('获取已完成书籍功能暂时禁用');
    return <Book>[];
  }
  
  /// 按文件类型筛选 (暂时返回空列表)
  static Future<List<Book>> getBooksByFileType(String fileType) async {
    print('按文件类型筛选功能暂时禁用: $fileType');
    return <Book>[];
  }
  
  /// 按标签筛选 (暂时返回空列表)
  static Future<List<Book>> getBooksByTag(String tag) async {
    print('按标签筛选功能暂时禁用: $tag');
    return <Book>[];
  }
  
  // ===== 统计信息 (暂时返回默认值) =====
  
  /// 获取书籍总数 (暂时返回0)
  static Future<int> getTotalBooksCount() async {
    print('获取书籍总数功能暂时禁用');
    return 0;
  }
  
  /// 获取阅读统计 (暂时返回默认统计)
  static Future<ReadingStats> getReadingStats() async {
    print('获取阅读统计功能暂时禁用');
    return ReadingStats(); // 返回空的统计对象
  }
  
  // ===== 数据备份与恢复 (暂时返回默认值) =====
  
  /// 导出所有数据 (暂时返回空数据)
  static Future<Map<String, dynamic>> exportAllData() async {
    print('导出数据功能暂时禁用');
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'books': <Map<String, dynamic>>[],
    };
  }
  
  /// 导入数据 (暂时无操作)
  static Future<void> importData(Map<String, dynamic> data) async {
    print('导入数据功能暂时禁用');
  }
  
  /// 清空所有数据 (暂时无操作)
  static Future<void> clearAllData() async {
    print('清空数据功能暂时禁用');
  }
}