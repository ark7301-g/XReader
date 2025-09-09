import '../../../data/models/book.dart';

class BookshelfState {
  final List<Book> books;
  final List<Book> filteredBooks;
  final bool isLoading;
  final bool isRefreshing;
  final String searchQuery;
  final BookshelfFilter currentFilter;
  final BookshelfSortBy sortBy;
  final bool sortAscending;
  final BookshelfViewMode viewMode;
  final List<int> selectedBookIds;
  final bool isSelectionMode;
  final String? error;
  final BookshelfStats stats;

  const BookshelfState({
    this.books = const [],
    this.filteredBooks = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.searchQuery = '',
    this.currentFilter = BookshelfFilter.all,
    this.sortBy = BookshelfSortBy.addedDate,
    this.sortAscending = true,
    this.viewMode = BookshelfViewMode.grid,
    this.selectedBookIds = const [],
    this.isSelectionMode = false,
    this.error,
    this.stats = const BookshelfStats(),
  });

  bool get hasBooks => books.isNotEmpty;
  bool get hasFilteredBooks => filteredBooks.isNotEmpty;
  bool get hasError => error != null;
  bool get hasSelectedBooks => selectedBookIds.isNotEmpty;
  int get selectedBooksCount => selectedBookIds.length;
  bool get isAllSelected => selectedBookIds.length == filteredBooks.length;
  
  List<Book> get displayBooks {
    if (searchQuery.isNotEmpty || currentFilter != BookshelfFilter.all) {
      return filteredBooks;
    }
    return books;
  }

  BookshelfState copyWith({
    List<Book>? books,
    List<Book>? filteredBooks,
    bool? isLoading,
    bool? isRefreshing,
    String? searchQuery,
    BookshelfFilter? currentFilter,
    BookshelfSortBy? sortBy,
    bool? sortAscending,
    BookshelfViewMode? viewMode,
    List<int>? selectedBookIds,
    bool? isSelectionMode,
    String? error,
    BookshelfStats? stats,
  }) {
    return BookshelfState(
      books: books ?? this.books,
      filteredBooks: filteredBooks ?? this.filteredBooks,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
      currentFilter: currentFilter ?? this.currentFilter,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      viewMode: viewMode ?? this.viewMode,
      selectedBookIds: selectedBookIds ?? this.selectedBookIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      error: error,
      stats: stats ?? this.stats,
    );
  }

  static BookshelfState initial() => const BookshelfState();
}

enum BookshelfFilter {
  all('全部'),
  reading('在读'),
  finished('已读'),
  unread('未读'),
  favorites('收藏');

  const BookshelfFilter(this.label);
  final String label;
}

enum BookshelfSortBy {
  addedDate('添加时间'),
  lastRead('最近阅读'),
  title('书名'),
  author('作者'),
  progress('阅读进度'),
  fileSize('文件大小');

  const BookshelfSortBy(this.label);
  final String label;
}

enum BookshelfViewMode {
  grid('网格'),
  list('列表');

  const BookshelfViewMode(this.label);
  final String label;
}

class BookshelfStats {
  final int totalBooks;
  final int readingBooks;
  final int finishedBooks;
  final int unreadBooks;
  final int favoriteBooks;
  final int totalReadingTimeMinutes;
  final double averageProgress;
  final int totalFileSizeMB;

  const BookshelfStats({
    this.totalBooks = 0,
    this.readingBooks = 0,
    this.finishedBooks = 0,
    this.unreadBooks = 0,
    this.favoriteBooks = 0,
    this.totalReadingTimeMinutes = 0,
    this.averageProgress = 0,
    this.totalFileSizeMB = 0,
  });

  String get formattedReadingTime {
    if (totalReadingTimeMinutes < 60) {
      return '$totalReadingTimeMinutes分钟';
    } else if (totalReadingTimeMinutes < 60 * 24) {
      final hours = totalReadingTimeMinutes ~/ 60;
      final minutes = totalReadingTimeMinutes % 60;
      return '$hours小时$minutes分钟';
    } else {
      final days = totalReadingTimeMinutes ~/ (60 * 24);
      final hours = (totalReadingTimeMinutes % (60 * 24)) ~/ 60;
      return '$days天$hours小时';
    }
  }

  String get formattedFileSize {
    if (totalFileSizeMB < 1024) {
      return '${totalFileSizeMB}MB';
    } else {
      return '${(totalFileSizeMB / 1024).toStringAsFixed(1)}GB';
    }
  }

  String get formattedAverageProgress {
    return '${(averageProgress * 100).toInt()}%';
  }
}
