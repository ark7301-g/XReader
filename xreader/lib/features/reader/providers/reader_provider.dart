import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/database/enhanced_database_service.dart';
import '../../../data/models/book.dart';
import '../services/epub_reader_service.dart';
import '../services/pdf_reader_service.dart';
import 'reader_state.dart';

// Reader Provider
final readerProvider = StateNotifierProvider.family<ReaderNotifier, ReaderState, int>((ref, bookId) {
  return ReaderNotifier(bookId);
});

// Reader Settings Provider
final readerSettingsProvider = StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
  return ReaderSettingsNotifier();
});

class ReaderNotifier extends StateNotifier<ReaderState> {
  final int bookId;
  Timer? _readingTimer;
  Timer? _progressSaveTimer;
  DateTime? _sessionStartTime;
  EpubReaderService? _epubService;
  PdfReaderService? _pdfService;

  ReaderNotifier(this.bookId) : super(ReaderState.initial()) {
    loadBook();
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _progressSaveTimer?.cancel();
    super.dispose();
  }

  /// 加载书籍
  Future<void> loadBook() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final book = await EnhancedDatabaseService.getBookById(bookId);
      if (book == null) {
        state = state.copyWith(
          isLoading: false,
          error: '书籍不存在',
        );
        return;
      }

      // 根据文件类型选择合适的阅读器服�?
      List<String> pageContents = [];
      List<Chapter> chapters = [];
      int totalPages = 0;

      switch (book.fileType.toLowerCase()) {
        case 'epub':
          // 使用增强数据库服务获取已解析的内容
          print('📚 从数据库获取EPUB解析内容...');
          try {
            chapters = await EnhancedDatabaseService.getBookChapters(book.id);
            print('✅ 获取到${chapters.length}个章节');
            
            // 构建页面内容
            pageContents = [];
            int successCount = 0;
            int failCount = 0;
            
            for (int i = 0; i < book.totalPages; i++) {
              final content = await EnhancedDatabaseService.getPageContent(book.id, i + 1);
              if (content != null && content.isNotEmpty) {
                pageContents.add(content);
                successCount++;
              } else {
                pageContents.add('页面 ${i + 1} 的内容暂时无法显示\n\n请尝试重新加载此书籍');
                failCount++;
              }
            }
            totalPages = pageContents.length;
            print('✅ 页面内容获取完成: 成功 $successCount 页, 失败 $failCount 页, 总计 $totalPages 页');
            
            // 如果大部分页面都失败了，回退到旧解析器
            if (failCount > successCount) {
              print('⚠️ 大部分页面内容缺失，回退到EpubReaderService');
              throw Exception('数据库内容不完整，需要重新解析');
            }
          } catch (e) {
            print('❌ 从数据库获取内容失败: $e');
            // 回退到旧的解析方式
            _epubService = EpubReaderService();
            final result = await _epubService!.loadBook(book.filePath);
            pageContents = result.pages;
            chapters = result.chapters;
            totalPages = pageContents.length;
          }
          break;
        
        case 'pdf':
          _pdfService = PdfReaderService();
          final result = await _pdfService!.loadBook(book.filePath);
          pageContents = result.pages;
          totalPages = pageContents.length;
          break;
        
        default:
          throw Exception('不支持的文件格式: ${book.fileType}');
      }

      // 计算当前页和进度
      final currentPage = book.currentPage.clamp(0, max(0, totalPages - 1));
      final progress = totalPages > 0 ? currentPage / totalPages : 0.0;

      state = state.copyWith(
        book: book,
        pageContents: pageContents,
        chapters: chapters,
        currentPage: currentPage,
        totalPages: totalPages,
        readingProgress: progress,
        isLoading: false,
      );

      // 开始阅读会�?
      _startReadingSession();
      
      // 定期保存进度
      _startProgressSaveTimer();

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载书籍失败: ${e.toString()}',
      );
    }
  }

  /// 切换工具栏显示
  void toggleToolbar() {
    state = state.copyWith(showToolbar: !state.showToolbar);
    
    // 3秒后自动隐藏工具栏
    if (state.showToolbar) {
      Timer(const Duration(seconds: 3), () {
        if (mounted && state.showToolbar) {
          state = state.copyWith(showToolbar: false);
        }
      });
    }
  }

  /// 显示工具栏
  void showToolbar() {
    state = state.copyWith(showToolbar: true);
  }

  /// 隐藏工具栏
  void hideToolbar() {
    state = state.copyWith(showToolbar: false);
  }

  /// 下一�?
  void nextPage() {
    if (state.canGoToNextPage) {
      final newPage = state.currentPage + 1;
      _updatePage(newPage);
    }
  }

  /// 上一�?
  void previousPage() {
    if (state.canGoToPreviousPage) {
      final newPage = state.currentPage - 1;
      _updatePage(newPage);
    }
  }

  /// 跳转到指定页
  void goToPage(int page) {
    final targetPage = page.clamp(0, state.totalPages - 1);
    _updatePage(targetPage);
  }

  /// 跳转到指定进�?
  void goToProgress(double progress) {
    final targetPage = (progress * state.totalPages).floor().clamp(0, state.totalPages - 1);
    _updatePage(targetPage);
  }

  /// 跳转到章节
  void goToChapter(int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < state.chapters.length) {
      final chapter = state.chapters[chapterIndex];
      _updatePage(chapter.startPage);
      state = state.copyWith(currentChapterIndex: chapterIndex);
    }
  }

  /// 更新当前�?
  void _updatePage(int page) {
    final newProgress = state.totalPages > 0 ? page / state.totalPages : 0.0;
    
    // 找到当前章节
    int chapterIndex = state.currentChapterIndex;
    for (int i = 0; i < state.chapters.length; i++) {
      if (state.chapters[i].containsPage(page)) {
        chapterIndex = i;
        break;
      }
    }

    state = state.copyWith(
      currentPage: page,
      readingProgress: newProgress,
      currentChapterIndex: chapterIndex,
      currentChapter: state.chapters.isNotEmpty && chapterIndex < state.chapters.length 
          ? state.chapters[chapterIndex].title 
          : null,
    );
  }

  /// 更新阅读设置
  void updateTextSize(double size) {
    state = state.copyWith(textSize: size.clamp(12.0, 32.0));
  }

  void updateLineHeight(double height) {
    state = state.copyWith(lineHeight: height.clamp(1.0, 3.0));
  }

  void updateFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
  }

  void updateReaderTheme(ReaderTheme theme) {
    state = state.copyWith(readerTheme: theme);
  }

  void toggleNightMode() {
    state = state.copyWith(isNightMode: !state.isNightMode);
  }

  void updateBrightness(double brightness) {
    state = state.copyWith(brightness: brightness.clamp(0.0, 1.0));
  }

  void toggleFullScreen() {
    state = state.copyWith(isFullScreen: !state.isFullScreen);
    
    if (state.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void updateReaderMode(ReaderMode mode) {
    state = state.copyWith(readerMode: mode);
  }

  void updatePageTurnAnimation(PageTurnAnimation animation) {
    state = state.copyWith(pageTurnAnimation: animation);
  }

  void updateReadingDirection(ReadingDirection direction) {
    state = state.copyWith(readingDirection: direction);
  }

  /// 添加书签
  Future<void> addBookmark({String? note}) async {
    if (state.book == null) return;

    try {
      final bookmark = Bookmark()
        ..id = DateTime.now().millisecondsSinceEpoch.toString()
        ..pageNumber = state.currentPage
        ..chapterTitle = state.currentChapter ?? '第${state.currentPage + 1}页'
        ..createdDate = DateTime.now()
        ..note = note
        ..type = BookmarkType.bookmark;

      await EnhancedDatabaseService.addBookmark(state.book!.id, bookmark);
    } catch (e) {
      state = state.copyWith(error: '添加书签失败: ${e.toString()}');
    }
  }

  /// 保存阅读进度
  Future<void> saveProgress() async {
    if (state.book == null) return;

    try {
      await EnhancedDatabaseService.updateReadingProgress(
        state.book!.id,
        state.currentPage,
        state.readingProgress,
        readingTimeMinutes: _getSessionDuration(),
      );
    } catch (e) {
      print('保存进度失败: $e');
    }
  }

  /// 开始阅读会�?
  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
    
    // 每分钟记录一次阅读时间
    _readingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (state.book != null) {
        EnhancedDatabaseService.addReadingTime(state.book!.id, 1);
      }
    });
  }

  /// 开始进度保存定时器
  void _startProgressSaveTimer() {
    // 每30秒保存一次进度
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      saveProgress();
    });
  }

  /// 获取本次会话时长（分钟）
  int _getSessionDuration() {
    if (_sessionStartTime == null) return 0;
    final duration = DateTime.now().difference(_sessionStartTime!);
    return duration.inMinutes;
  }

  /// 结束阅读会话
  Future<void> endReadingSession() async {
    _readingTimer?.cancel();
    _progressSaveTimer?.cancel();
    
    // 保存最终进�?
    await saveProgress();
    
    // 记录最后阅读时�?
    if (state.book != null) {
      final sessionDuration = _getSessionDuration();
      if (sessionDuration > 0) {
        await EnhancedDatabaseService.addReadingTime(state.book!.id, sessionDuration);
      }
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 搜索文本
  List<SearchResult> searchInBook(String query) {
    if (query.isEmpty || state.pageContents.isEmpty) return [];

    final results = <SearchResult>[];
    for (int i = 0; i < state.pageContents.length; i++) {
      final content = state.pageContents[i];
      final matches = query.allMatches(content.toLowerCase());
      
      for (final match in matches) {
        // 获取匹配文本的上下文
        final start = max(0, match.start - 50);
        final end = min(content.length, match.end + 50);
        final context = content.substring(start, end);
        
        results.add(SearchResult(
          pageIndex: i,
          position: match.start,
          context: context,
          matchStart: match.start - start,
          matchEnd: match.end - start,
        ));
      }
    }
    
    return results;
  }
}

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier() : super(const ReaderSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: 从SharedPreferences加载设置
  }

  Future<void> _saveSettings() async {
    // TODO: 保存设置到SharedPreferences
  }

  void updateTextSize(double size) {
    state = state.copyWith(textSize: size);
    _saveSettings();
  }

  void updateLineHeight(double height) {
    state = state.copyWith(lineHeight: height);
    _saveSettings();
  }

  void updateFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
    _saveSettings();
  }

  void updateTheme(ReaderTheme theme) {
    state = state.copyWith(theme: theme);
    _saveSettings();
  }

  void updateMode(ReaderMode mode) {
    state = state.copyWith(mode: mode);
    _saveSettings();
  }

  void updateBrightness(double brightness) {
    state = state.copyWith(brightness: brightness);
    _saveSettings();
  }

  void toggleAutoNightMode() {
    state = state.copyWith(autoNightMode: !state.autoNightMode);
    _saveSettings();
  }

  void toggleKeepScreenOn() {
    state = state.copyWith(keepScreenOn: !state.keepScreenOn);
    _saveSettings();
  }

  void updateAnimation(PageTurnAnimation animation) {
    state = state.copyWith(animation: animation);
    _saveSettings();
  }

  void updateDirection(ReadingDirection direction) {
    state = state.copyWith(direction: direction);
    _saveSettings();
  }

  void togglePageNumber() {
    state = state.copyWith(showPageNumber: !state.showPageNumber);
    _saveSettings();
  }

  void toggleChapterTitle() {
    state = state.copyWith(showChapterTitle: !state.showChapterTitle);
    _saveSettings();
  }

  void toggleVolumeKeyTurn() {
    state = state.copyWith(enableVolumeKeyTurn: !state.enableVolumeKeyTurn);
    _saveSettings();
  }

  void toggleTapTurn() {
    state = state.copyWith(enableTapTurn: !state.enableTapTurn);
    _saveSettings();
  }

  void updateMargins(double horizontal, double vertical) {
    state = state.copyWith(
      marginHorizontal: horizontal,
      marginVertical: vertical,
    );
    _saveSettings();
  }
}

// 搜索结果
class SearchResult {
  final int pageIndex;
  final int position;
  final String context;
  final int matchStart;
  final int matchEnd;

  const SearchResult({
    required this.pageIndex,
    required this.position,
    required this.context,
    required this.matchStart,
    required this.matchEnd,
  });

  String get highlightedContext {
    final before = context.substring(0, matchStart);
    final match = context.substring(matchStart, matchEnd);
    final after = context.substring(matchEnd);
    return '$before<mark>$match</mark>$after';
  }
}

// EPUB阅读器结�?
class EpubReaderResult {
  final List<String> pages;
  final List<Chapter> chapters;
  final String? coverImagePath;

  const EpubReaderResult({
    required this.pages,
    required this.chapters,
    this.coverImagePath,
  });
}

// PDF阅读器结�? 
class PdfReaderResult {
  final List<String> pages;
  final String? title;
  final String? author;

  const PdfReaderResult({
    required this.pages,
    this.title,
    this.author,
  });
}
