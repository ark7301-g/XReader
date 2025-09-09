// import 'package:isar/isar.dart';  // 暂时注释掉

// part 'book.g.dart';  // 暂时注释掉

// @collection  // 暂时注释掉
class Book {
  int id = 0; // Id id = Isar.autoIncrement;  // 暂时修改
  
  // @Index(unique: true)  // 暂时注释掉
  late String filePath;
  
  late String title;
  String? author;
  String? publisher;
  String? description;
  String? language;
  String? coverPath;
  
  // 文件信息
  late String fileType; // epub, pdf
  int fileSize = 0; // 字节
  
  // 时间信息
  DateTime? addedDate;
  DateTime? lastReadDate;
  DateTime? publishDate;
  
  // 阅读进度
  int currentPage = 0;
  int totalPages = 0;
  double readingProgress = 0.0; // 0.0 �?1.0
  String? lastReadPosition; // 具体位置标识�?
  
  // 阅读统计
  int readingTimeMinutes = 0;
  int totalReadingSessions = 0;
  
  // 书签和笔�?
  List<Bookmark> bookmarks = [];
  List<Note> notes = [];
  
  // 个人设置
  bool isFavorite = false;
  List<String> tags = [];
  int rating = 0; // 1-5星评�?
  
  // 阅读设置（每本书可以有独立设置）
  double? customFontSize;
  double? customLineHeight;
  String? customFontFamily;
  int? customThemeMode; // 0: 跟随系统, 1: 明亮, 2: 夜间, 3: 棕褐

  // 默认构造函数
  Book();

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'author': author,
      'publisher': publisher,
      'description': description,
      'language': language,
      'coverPath': coverPath,
      'fileType': fileType,
      'fileSize': fileSize,
      'addedDate': addedDate?.toIso8601String(),
      'lastReadDate': lastReadDate?.toIso8601String(),
      'publishDate': publishDate?.toIso8601String(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'readingProgress': readingProgress,
      'lastReadPosition': lastReadPosition,
      'readingTimeMinutes': readingTimeMinutes,
      'totalReadingSessions': totalReadingSessions,
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'isFavorite': isFavorite,
      'tags': tags,
      'rating': rating,
      'customFontSize': customFontSize,
      'customLineHeight': customLineHeight,
      'customFontFamily': customFontFamily,
      'customThemeMode': customThemeMode,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final book = Book();
    book.id = json['id'] ?? 0;
    book.filePath = json['filePath'] ?? '';
    book.title = json['title'] ?? '';
    book.author = json['author'];
    book.publisher = json['publisher'];
    book.description = json['description'];
    book.language = json['language'];
    book.coverPath = json['coverPath'];
    book.fileType = json['fileType'] ?? '';
    book.fileSize = json['fileSize'] ?? 0;
    book.addedDate = json['addedDate'] != null ? DateTime.parse(json['addedDate']) : null;
    book.lastReadDate = json['lastReadDate'] != null ? DateTime.parse(json['lastReadDate']) : null;
    book.publishDate = json['publishDate'] != null ? DateTime.parse(json['publishDate']) : null;
    book.currentPage = json['currentPage'] ?? 0;
    book.totalPages = json['totalPages'] ?? 0;
    book.readingProgress = (json['readingProgress'] ?? 0.0).toDouble();
    book.lastReadPosition = json['lastReadPosition'];
    book.readingTimeMinutes = json['readingTimeMinutes'] ?? 0;
    book.totalReadingSessions = json['totalReadingSessions'] ?? 0;
    book.isFavorite = json['isFavorite'] ?? false;
    book.tags = List<String>.from(json['tags'] ?? []);
    book.rating = json['rating'] ?? 0;
    book.customFontSize = json['customFontSize']?.toDouble();
    book.customLineHeight = json['customLineHeight']?.toDouble();
    book.customFontFamily = json['customFontFamily'];
    book.customThemeMode = json['customThemeMode'];

    // 添加书签和笔记
    if (json['bookmarks'] != null) {
      book.bookmarks = (json['bookmarks'] as List)
          .map((b) => Bookmark.fromJson(b))
          .toList();
    }
    
    if (json['notes'] != null) {
      book.notes = (json['notes'] as List)
          .map((n) => Note.fromJson(n))
          .toList();
    }

    return book;
  }
}

// @embedded  // 暂时注释掉
class Bookmark {
  late String id; // 唯一标识符
  late int pageNumber;
  late String chapterTitle;
  String? chapterPosition; // 章节内具体位置
  DateTime? createdDate;
  String? note;
  String? selectedText; // 书签处的文本片段
  // @enumerated  // 暂时注释掉
  BookmarkType type = BookmarkType.bookmark; // 书签类型

  Bookmark({
    String? id,
    int? pageNumber,
    String? chapterTitle,
    this.chapterPosition,
    this.createdDate,
    this.note,
    this.selectedText,
    this.type = BookmarkType.bookmark,
  }) {
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    this.pageNumber = pageNumber ?? 0;
    this.chapterTitle = chapterTitle ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'chapterTitle': chapterTitle,
      'chapterPosition': chapterPosition,
      'createdDate': createdDate?.toIso8601String(),
      'note': note,
      'selectedText': selectedText,
      'type': type.index,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? '',
      pageNumber: json['pageNumber'] ?? 0,
      chapterTitle: json['chapterTitle'] ?? '',
      chapterPosition: json['chapterPosition'],
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : null,
      note: json['note'],
      selectedText: json['selectedText'],
      type: BookmarkType.values[json['type'] ?? 0],
    );
  }
}

// @embedded  // 暂时注释掉
class Note {
  late String id;
  late int pageNumber;
  late String chapterTitle;
  String? chapterPosition;
  DateTime? createdDate;
  DateTime? modifiedDate;
  late String content; // 笔记内容
  String? selectedText; // 关联的原�?
  List<String> tags = []; // 笔记标签
  // @enumerated  // 暂时注释掉
  NoteType type = NoteType.note;

  Note({
    String? id,
    int? pageNumber,
    String? chapterTitle,
    this.chapterPosition,
    this.createdDate,
    this.modifiedDate,
    String? content,
    this.selectedText,
    List<String>? tags,
    this.type = NoteType.note,
  }) {
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    this.pageNumber = pageNumber ?? 0;
    this.chapterTitle = chapterTitle ?? '';
    this.content = content ?? '';
    this.tags = tags ?? [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'chapterTitle': chapterTitle,
      'chapterPosition': chapterPosition,
      'createdDate': createdDate?.toIso8601String(),
      'modifiedDate': modifiedDate?.toIso8601String(),
      'content': content,
      'selectedText': selectedText,
      'tags': tags,
      'type': type.index,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      pageNumber: json['pageNumber'] ?? 0,
      chapterTitle: json['chapterTitle'] ?? '',
      chapterPosition: json['chapterPosition'],
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : null,
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate']) 
          : null,
      content: json['content'] ?? '',
      selectedText: json['selectedText'],
      tags: List<String>.from(json['tags'] ?? []),
      type: NoteType.values[json['type'] ?? 0],
    );
  }
}

enum BookmarkType {
  bookmark, // 普通书签
  highlight, // 高亮标记
  lastRead, // 最后阅读位置
}

enum NoteType {
  note, // 普通笔记
  thought, // 感想
  question, // 问题
  summary, // 总结
}

// 书籍统计信息（可选，用于统计页面�?
// @embedded  // 暂时注释掉
class ReadingStats {
  int totalBooks = 0;
  int finishedBooks = 0;
  int readingBooks = 0;
  int totalReadingTimeMinutes = 0;
  int totalReadingSessions = 0;
  DateTime? firstReadDate;
  DateTime? lastReadDate;
  
  // 年度统计
  // @ignore  // 暂时注释掉
  Map<int, int> yearlyReadingTime = {}; // 年份 -> 阅读时长（分钟）
  // @ignore  // 暂时注释掉
  Map<int, int> yearlyBooksFinished = {}; // 年份 -> 完成书籍�?
  
  // 月度统计
  // @ignore  // 暂时注释掉
  Map<String, int> monthlyReadingTime = {}; // YYYY-MM -> 阅读时长（分钟）
  // @ignore  // 暂时注释掉
  Map<String, int> monthlyBooksFinished = {}; // YYYY-MM -> 完成书籍数
}

// 扩展方法
extension BookExtensions on Book {
  // 是否已开始阅�?
  bool get hasStartedReading => readingProgress > 0.0;
  
  // 是否已完成阅�?
  bool get isFinished => readingProgress >= 1.0;
  
  // 格式化的阅读进度
  String get formattedProgress => '${(readingProgress * 100).toInt()}%';
  
  // 格式化的阅读时长
  String get formattedReadingTime {
    if (readingTimeMinutes < 60) {
      return '$readingTimeMinutes分钟';
    } else {
      final hours = readingTimeMinutes ~/ 60;
      final minutes = readingTimeMinutes % 60;
      return '$hours小时$minutes分钟';
    }
  }
  
  // 获取文件大小的友好显�?
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
  
  // 检查是否需要备份书签和笔记
  bool get needsBackup {
    return bookmarks.isNotEmpty || notes.isNotEmpty;
  }
  
  // 获取最近的书签
  Bookmark? get latestBookmark {
    if (bookmarks.isEmpty) return null;
    bookmarks.sort((a, b) => (b.createdDate ?? DateTime(0))
        .compareTo(a.createdDate ?? DateTime(0)));
    return bookmarks.first;
  }
  
  // 更新阅读进度
  void updateReadingProgress(int currentPage, DateTime readTime) {
    this.currentPage = currentPage;
    if (totalPages > 0) {
      readingProgress = currentPage / totalPages;
    }
    lastReadDate = readTime;
  }
  
  // 添加阅读时间
  void addReadingTime(int minutes) {
    readingTimeMinutes += minutes;
    totalReadingSessions++;
  }
}
