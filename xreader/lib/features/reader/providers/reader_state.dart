import '../../../data/models/book.dart';

class ReaderState {
  final Book? book;
  final bool isLoading;
  final bool showToolbar;
  final bool isNightMode;
  final double textSize;
  final double lineHeight;
  final String fontFamily;
  final ReaderTheme readerTheme;
  final int currentPage;
  final int totalPages;
  final double readingProgress;
  final List<String> pageContents;
  final bool isFullScreen;
  final String? error;
  final ReaderMode readerMode;
  final double brightness;
  final bool autoNightMode;
  final bool keepScreenOn;
  final PageTurnAnimation pageTurnAnimation;
  final ReadingDirection readingDirection;
  final double scrollPosition;
  final bool isScrollMode;
  final String? currentChapter;
  final List<Chapter> chapters;
  final int currentChapterIndex;

  const ReaderState({
    this.book,
    this.isLoading = false,
    this.showToolbar = false,
    this.isNightMode = false,
    this.textSize = 18.0,
    this.lineHeight = 1.6,
    this.fontFamily = 'default',
    this.readerTheme = ReaderTheme.paper,
    this.currentPage = 0,
    this.totalPages = 0,
    this.readingProgress = 0.0,
    this.pageContents = const [],
    this.isFullScreen = false,
    this.error,
    this.readerMode = ReaderMode.pagination,
    this.brightness = 0.5,
    this.autoNightMode = false,
    this.keepScreenOn = true,
    this.pageTurnAnimation = PageTurnAnimation.slide,
    this.readingDirection = ReadingDirection.leftToRight,
    this.scrollPosition = 0.0,
    this.isScrollMode = false,
    this.currentChapter,
    this.chapters = const [],
    this.currentChapterIndex = 0,
  });

  bool get hasBook => book != null;
  bool get hasError => error != null;
  bool get canGoToPreviousPage => currentPage > 0;
  bool get canGoToNextPage => currentPage < totalPages - 1;
  bool get hasChapters => chapters.isNotEmpty;
  String get formattedProgress => '${(readingProgress * 100).toInt()}%';
  
  String get pageInfo {
    if (totalPages > 0) {
      return '${currentPage + 1} / $totalPages';
    }
    return '';
  }

  Chapter? get currentChapterInfo {
    if (currentChapterIndex >= 0 && currentChapterIndex < chapters.length) {
      return chapters[currentChapterIndex];
    }
    return null;
  }

  ReaderState copyWith({
    Book? book,
    bool? isLoading,
    bool? showToolbar,
    bool? isNightMode,
    double? textSize,
    double? lineHeight,
    String? fontFamily,
    ReaderTheme? readerTheme,
    int? currentPage,
    int? totalPages,
    double? readingProgress,
    List<String>? pageContents,
    bool? isFullScreen,
    String? error,
    ReaderMode? readerMode,
    double? brightness,
    bool? autoNightMode,
    bool? keepScreenOn,
    PageTurnAnimation? pageTurnAnimation,
    ReadingDirection? readingDirection,
    double? scrollPosition,
    bool? isScrollMode,
    String? currentChapter,
    List<Chapter>? chapters,
    int? currentChapterIndex,
  }) {
    return ReaderState(
      book: book ?? this.book,
      isLoading: isLoading ?? this.isLoading,
      showToolbar: showToolbar ?? this.showToolbar,
      isNightMode: isNightMode ?? this.isNightMode,
      textSize: textSize ?? this.textSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      readerTheme: readerTheme ?? this.readerTheme,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      readingProgress: readingProgress ?? this.readingProgress,
      pageContents: pageContents ?? this.pageContents,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      error: error,
      readerMode: readerMode ?? this.readerMode,
      brightness: brightness ?? this.brightness,
      autoNightMode: autoNightMode ?? this.autoNightMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      pageTurnAnimation: pageTurnAnimation ?? this.pageTurnAnimation,
      readingDirection: readingDirection ?? this.readingDirection,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isScrollMode: isScrollMode ?? this.isScrollMode,
      currentChapter: currentChapter ?? this.currentChapter,
      chapters: chapters ?? this.chapters,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
    );
  }

  static ReaderState initial() => const ReaderState();
}

enum ReaderTheme {
  paper('纸质', '#FFFEF7', '#2B2B2B'),
  night('夜间', '#1A1A1A', '#CCCCCC'),
  sepia('棕褐', '#F4F1EA', '#5B4636'),
  green('护眼', '#E8F5E8', '#2B2B2B'),
  blue('蓝色', '#E8F4FD', '#2B2B2B');

  const ReaderTheme(this.label, this.backgroundColor, this.textColor);
  final String label;
  final String backgroundColor;
  final String textColor;
}

enum ReaderMode {
  pagination('分页模式'),
  scroll('滚动模式');

  const ReaderMode(this.label);
  final String label;
}

enum PageTurnAnimation {
  slide('滑动'),
  curl('翻页'),
  fade('淡入淡出'),
  none('无动画');

  const PageTurnAnimation(this.label);
  final String label;
}

enum ReadingDirection {
  leftToRight('从左到右'),
  rightToLeft('从右到左'),
  topToBottom('从上到下');

  const ReadingDirection(this.label);
  final String label;
}

class Chapter {
  final String id;
  final String title;
  final int startPage;
  final int endPage;
  final String? href;
  final int level; // 章节层级�?为一级标题，2为二级标题等

  const Chapter({
    required this.id,
    required this.title,
    required this.startPage,
    required this.endPage,
    this.href,
    this.level = 1,
  });

  int get pageCount => endPage - startPage + 1;
  
  bool containsPage(int page) => page >= startPage && page <= endPage;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startPage': startPage,
    'endPage': endPage,
    'href': href,
    'level': level,
  };
  
  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'] as String,
    title: json['title'] as String,
    startPage: json['startPage'] as int,
    endPage: json['endPage'] as int,
    href: json['href'] as String?,
    level: json['level'] as int? ?? 1,
  );
}

// 阅读器设�?
class ReaderSettings {
  final double textSize;
  final double lineHeight;
  final String fontFamily;
  final ReaderTheme theme;
  final ReaderMode mode;
  final double brightness;
  final bool autoNightMode;
  final bool keepScreenOn;
  final PageTurnAnimation animation;
  final ReadingDirection direction;
  final bool showPageNumber;
  final bool showChapterTitle;
  final bool enableVolumeKeyTurn;
  final bool enableTapTurn;
  final double marginHorizontal;
  final double marginVertical;

  const ReaderSettings({
    this.textSize = 18.0,
    this.lineHeight = 1.6,
    this.fontFamily = 'default',
    this.theme = ReaderTheme.paper,
    this.mode = ReaderMode.pagination,
    this.brightness = 0.5,
    this.autoNightMode = false,
    this.keepScreenOn = true,
    this.animation = PageTurnAnimation.slide,
    this.direction = ReadingDirection.leftToRight,
    this.showPageNumber = true,
    this.showChapterTitle = true,
    this.enableVolumeKeyTurn = true,
    this.enableTapTurn = true,
    this.marginHorizontal = 24.0,
    this.marginVertical = 48.0,
  });

  ReaderSettings copyWith({
    double? textSize,
    double? lineHeight,
    String? fontFamily,
    ReaderTheme? theme,
    ReaderMode? mode,
    double? brightness,
    bool? autoNightMode,
    bool? keepScreenOn,
    PageTurnAnimation? animation,
    ReadingDirection? direction,
    bool? showPageNumber,
    bool? showChapterTitle,
    bool? enableVolumeKeyTurn,
    bool? enableTapTurn,
    double? marginHorizontal,
    double? marginVertical,
  }) {
    return ReaderSettings(
      textSize: textSize ?? this.textSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      theme: theme ?? this.theme,
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      autoNightMode: autoNightMode ?? this.autoNightMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      animation: animation ?? this.animation,
      direction: direction ?? this.direction,
      showPageNumber: showPageNumber ?? this.showPageNumber,
      showChapterTitle: showChapterTitle ?? this.showChapterTitle,
      enableVolumeKeyTurn: enableVolumeKeyTurn ?? this.enableVolumeKeyTurn,
      enableTapTurn: enableTapTurn ?? this.enableTapTurn,
      marginHorizontal: marginHorizontal ?? this.marginHorizontal,
      marginVertical: marginVertical ?? this.marginVertical,
    );
  }
}

// 阅读统计
class ReadingSession {
  final DateTime startTime;
  final DateTime? endTime;
  final int startPage;
  final int? endPage;
  final String bookId;

  const ReadingSession({
    required this.startTime,
    this.endTime,
    required this.startPage,
    this.endPage,
    required this.bookId,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  int get pagesRead => (endPage ?? startPage) - startPage;
}
