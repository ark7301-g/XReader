import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../../core/database/enhanced_database_service.dart';
import '../../../core/services/file_service.dart';
import '../../../data/models/book.dart';
import 'bookshelf_state.dart';

// Enhanced Database Service Provider
final databaseServiceProvider = Provider((ref) {
  return EnhancedDatabaseService;
});

// File Service Provider
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

// Bookshelf Provider
final bookshelfProvider = StateNotifierProvider<BookshelfNotifier, BookshelfState>((ref) {
  return BookshelfNotifier();
});

class BookshelfNotifier extends StateNotifier<BookshelfState> {
  BookshelfNotifier() : super(BookshelfState.initial()) {
    loadBooks();
  }

  /// 加载所有书�?
  Future<void> loadBooks() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final books = await EnhancedDatabaseService.getAllBooks();
      final filteredBooks = _applyFiltersAndSort(books);
      final stats = _calculateStats(books);
      
      state = state.copyWith(
        books: books,
        filteredBooks: filteredBooks,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载书籍失败: ${e.toString()}',
      );
    }
  }

  /// 刷新书籍列表
  Future<void> refreshBooks() async {
    if (state.isRefreshing) return;
    
    state = state.copyWith(isRefreshing: true, error: null);
    
    try {
      final books = await EnhancedDatabaseService.getAllBooks();
      final filteredBooks = _applyFiltersAndSort(books);
      final stats = _calculateStats(books);
      
      state = state.copyWith(
        books: books,
        filteredBooks: filteredBooks,
        stats: stats,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: '刷新失败: ${e.toString()}',
      );
    }
  }

  /// 添加书籍
  Future<bool> addBook() async {
    print('🔄 开始添加书籍流程...');
    
    try {
      // 导入文件
      print('📁 调用文件导入...');
      final filePath = await FileService.importBook();
      if (filePath == null) {
        print('❌ 用户取消文件选择');
        return false;
      }
      
      print('📁 选择的文件: $filePath');

      // 检查是否已存在
      print('🔍 检查书籍是否已存在...');
      final existingBook = await EnhancedDatabaseService.getBookByFilePath(filePath);
      if (existingBook != null) {
        print('⚠️ 书籍已存在: ${existingBook.title}');
        state = state.copyWith(error: '该书籍已存在于书架中');
        return false;
      }

      // 创建基本书籍对象，让EnhancedDatabaseService进行完整的解析和处理
      print('📚 创建基本书籍对象...');
      final fileName = path.basenameWithoutExtension(filePath);
      final book = Book()
        ..filePath = filePath
        ..title = fileName
        ..fileType = FileService.getFileType(filePath)
        ..fileSize = await FileService.getFileSize(filePath);
      
      print('📚 基本对象创建成功: ${book.title}');

      // 使用增强数据库服务进行完整解析和添加
      // 这会自动使用新的EPUB解析器进行深度解析并存储到数据库
      print('💾 调用增强数据库服务添加书籍...');
      try {
        final bookId = await EnhancedDatabaseService.addBook(book);
        print('✅ 书籍添加成功，ID: $bookId');
        
        // 验证书籍是否真的保存到数据库
        final savedBook = await EnhancedDatabaseService.getBookById(bookId);
        if (savedBook != null) {
          print('✅ 验证成功：书籍已保存到数据库');
        } else {
          print('❌ 验证失败：书籍未在数据库中找到');
          throw Exception('书籍保存验证失败');
        }
      } catch (dbError) {
        print('❌ 数据库保存失败: $dbError');
        print('❌ 错误类型: ${dbError.runtimeType}');
        
        // 提供更友好的错误信息
        String friendlyError = '添加书籍失败';
        if (dbError.toString().contains('FOREIGN KEY constraint failed')) {
          friendlyError = '数据库约束错误，请重试';
        } else if (dbError.toString().contains('already exists')) {
          friendlyError = '该书籍已存在于书架中';
        } else if (dbError.toString().contains('parsing')) {
          friendlyError = '书籍解析失败，可能文件已损坏';
        }
        
        // 设置友好的错误信息到状态
        state = state.copyWith(error: friendlyError);
        
        if (dbError is Error) {
          print('❌ 错误堆栈:\n${dbError.stackTrace}');
        }
        rethrow;
      }
      
      // 重新加载书籍列表
      print('🔄 重新加载书籍列表...');
      await loadBooks();
      print('✅ 书籍列表已刷新');
      
      return true;
    } catch (e) {
      print('❌ 添加书籍失败: $e');
      print('❌ 错误堆栈: ${StackTrace.current}');
      state = state.copyWith(error: '添加书籍失败: ${e.toString()}');
      return false;
    }
  }

  /// 批量添加书籍
  Future<int> addMultipleBooks() async {
    try {
      final filePaths = await FileService.importMultipleBooks();
      if (filePaths.isEmpty) return 0;

      int successCount = 0;
      
      for (final filePath in filePaths) {
        try {
          // 检查是否已存在
          final existingBook = await EnhancedDatabaseService.getBookByFilePath(filePath);
          if (existingBook != null) continue;

          // 创建基本书籍对象
          final fileName = path.basenameWithoutExtension(filePath);
          final book = Book()
            ..filePath = filePath
            ..title = fileName
            ..fileType = FileService.getFileType(filePath)
            ..fileSize = await FileService.getFileSize(filePath);
          await EnhancedDatabaseService.addBook(book);
          successCount++;
        } catch (e) {
          print('添加书籍失败: $filePath, $e');
        }
      }

      // 重新加载书籍列表
      await loadBooks();
      
      return successCount;
    } catch (e) {
      state = state.copyWith(error: '批量添加失败: ${e.toString()}');
      return 0;
    }
  }

  /// 删除书籍
  Future<bool> deleteBook(int bookId, {bool deleteFile = false}) async {
    try {
      final book = await EnhancedDatabaseService.getBookById(bookId);
      if (book == null) return false;

      // 删除数据库记�?
      await EnhancedDatabaseService.deleteBook(bookId);

      // 可选：删除文件
      if (deleteFile) {
        await FileService.deleteBookFile(book.filePath);
        if (book.coverPath != null) {
          await FileService.deleteCoverFile(book.coverPath);
        }
      }

      // 重新加载书籍列表
      await loadBooks();
      
      return true;
    } catch (e) {
      state = state.copyWith(error: '删除书籍失败: ${e.toString()}');
      return false;
    }
  }

  /// 批量删除书籍
  Future<bool> deleteMultipleBooks(List<int> bookIds, {bool deleteFiles = false}) async {
    try {
      if (deleteFiles) {
        // 获取书籍信息用于删除文件
        for (final bookId in bookIds) {
          final book = await EnhancedDatabaseService.getBookById(bookId);
          if (book != null) {
            await FileService.deleteBookFile(book.filePath);
            if (book.coverPath != null) {
              await FileService.deleteCoverFile(book.coverPath);
            }
          }
        }
      }

      // 批量删除数据库记�?
      await EnhancedDatabaseService.deleteBooksById(bookIds);

      // 清除选择状�?
      exitSelectionMode();
      
      // 重新加载书籍列表
      await loadBooks();
      
      return true;
    } catch (e) {
      state = state.copyWith(error: '批量删除失败: ${e.toString()}');
      return false;
    }
  }

  /// 搜索书籍
  void searchBooks(String query) {
    state = state.copyWith(searchQuery: query);
    final filteredBooks = _applyFiltersAndSort(state.books);
    state = state.copyWith(filteredBooks: filteredBooks);
  }

  /// 设置筛选条�?
  void setFilter(BookshelfFilter filter) {
    state = state.copyWith(currentFilter: filter);
    final filteredBooks = _applyFiltersAndSort(state.books);
    state = state.copyWith(filteredBooks: filteredBooks);
  }

  /// 设置排序方式
  void setSortBy(BookshelfSortBy sortBy, {bool? ascending}) {
    state = state.copyWith(
      sortBy: sortBy,
      sortAscending: ascending ?? state.sortAscending,
    );
    final filteredBooks = _applyFiltersAndSort(state.books);
    state = state.copyWith(filteredBooks: filteredBooks);
  }

  /// 切换排序顺序
  void toggleSortOrder() {
    setSortBy(state.sortBy, ascending: !state.sortAscending);
  }

  /// 设置视图模式
  void setViewMode(BookshelfViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }

  /// 进入选择模式
  void enterSelectionMode() {
    state = state.copyWith(isSelectionMode: true, selectedBookIds: []);
  }

  /// 退出选择模式
  void exitSelectionMode() {
    state = state.copyWith(isSelectionMode: false, selectedBookIds: []);
  }

  /// 切换书籍选择状�?
  void toggleBookSelection(int bookId) {
    final selectedIds = List<int>.from(state.selectedBookIds);
    
    if (selectedIds.contains(bookId)) {
      selectedIds.remove(bookId);
    } else {
      selectedIds.add(bookId);
    }
    
    state = state.copyWith(selectedBookIds: selectedIds);
    
    // 如果没有选中的书籍，自动退出选择模式
    if (selectedIds.isEmpty) {
      exitSelectionMode();
    }
  }

  /// 全�?取消全�?
  void toggleSelectAll() {
    if (state.isAllSelected) {
      state = state.copyWith(selectedBookIds: []);
      exitSelectionMode();
    } else {
      final allBookIds = state.displayBooks.map((book) => book.id).toList();
      state = state.copyWith(selectedBookIds: allBookIds);
    }
  }

  /// 更新书籍收藏状�?
  Future<void> toggleBookFavorite(int bookId) async {
    try {
      final book = await EnhancedDatabaseService.getBookById(bookId);
      if (book == null) return;

      book.isFavorite = !book.isFavorite;
      await EnhancedDatabaseService.updateBook(book);
      
      // 重新加载书籍列表
      await loadBooks();
    } catch (e) {
      state = state.copyWith(error: '更新收藏状态失�? ${e.toString()}');
    }
  }

  /// 清除错误状�?
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 应用筛选和排序
  List<Book> _applyFiltersAndSort(List<Book> books) {
    var filteredBooks = books;

    // 应用搜索
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filteredBooks = filteredBooks.where((book) {
        return book.title.toLowerCase().contains(query) ||
               (book.author?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 应用筛�?
    switch (state.currentFilter) {
      case BookshelfFilter.all:
        break;
      case BookshelfFilter.reading:
        filteredBooks = filteredBooks.where((book) => 
          book.hasStartedReading && !book.isFinished).toList();
        break;
      case BookshelfFilter.finished:
        filteredBooks = filteredBooks.where((book) => book.isFinished).toList();
        break;
      case BookshelfFilter.unread:
        filteredBooks = filteredBooks.where((book) => !book.hasStartedReading).toList();
        break;
      case BookshelfFilter.favorites:
        filteredBooks = filteredBooks.where((book) => book.isFavorite).toList();
        break;
    }

    // 应用排序
    filteredBooks.sort((a, b) {
      int comparison = 0;
      
      switch (state.sortBy) {
        case BookshelfSortBy.addedDate:
          comparison = (a.addedDate ?? DateTime(0))
              .compareTo(b.addedDate ?? DateTime(0));
          break;
        case BookshelfSortBy.lastRead:
          comparison = (a.lastReadDate ?? DateTime(0))
              .compareTo(b.lastReadDate ?? DateTime(0));
          break;
        case BookshelfSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case BookshelfSortBy.author:
          comparison = (a.author ?? '').compareTo(b.author ?? '');
          break;
        case BookshelfSortBy.progress:
          comparison = a.readingProgress.compareTo(b.readingProgress);
          break;
        case BookshelfSortBy.fileSize:
          comparison = a.fileSize.compareTo(b.fileSize);
          break;
      }
      
      return state.sortAscending ? comparison : -comparison;
    });

    return filteredBooks;
  }

  /// 计算统计信息
  BookshelfStats _calculateStats(List<Book> books) {
    if (books.isEmpty) return const BookshelfStats();

    final readingBooks = books.where((book) => 
      book.hasStartedReading && !book.isFinished).length;
    final finishedBooks = books.where((book) => book.isFinished).length;
    final unreadBooks = books.where((book) => !book.hasStartedReading).length;
    final favoriteBooks = books.where((book) => book.isFavorite).length;
    
    final totalReadingTime = books.fold<int>(
      0, (sum, book) => sum + book.readingTimeMinutes);
    
    final averageProgress = books.fold<double>(
      0.0, (sum, book) => sum + book.readingProgress) / books.length;
    
    final totalFileSize = books.fold<int>(
      0, (sum, book) => sum + book.fileSize) ~/ (1024 * 1024); // Convert to MB

    return BookshelfStats(
      totalBooks: books.length,
      readingBooks: readingBooks,
      finishedBooks: finishedBooks,
      unreadBooks: unreadBooks,
      favoriteBooks: favoriteBooks,
      totalReadingTimeMinutes: totalReadingTime,
      averageProgress: averageProgress,
      totalFileSizeMB: totalFileSize,
    );
  }
}
