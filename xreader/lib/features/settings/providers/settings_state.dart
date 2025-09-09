class AppSettings {
  final String language;
  final bool enableNotifications;
  final bool autoBackup;
  final String backupLocation;
  final bool enableReadingStats;
  final bool shareReadingData;
  final int autoSaveInterval; // 分钟
  final bool enableVolumeKeyTurn;
  final bool enableTapTurn;
  final bool keepScreenOn;
  final bool autoNightMode;
  final String nightModeStartTime;
  final String nightModeEndTime;
  final bool enableBatterySaving;
  final double defaultTextSize;
  final double defaultLineHeight;
  final String defaultFontFamily;
  final String defaultReaderTheme;
  final String defaultReaderMode;
  final double defaultBrightness;
  final double defaultMarginHorizontal;
  final double defaultMarginVertical;
  final bool showPageNumber;
  final bool showChapterTitle;
  final bool enablePageAnimation;
  final String pageAnimationType;
  final String readingDirection;

  const AppSettings({
    this.language = 'zh_CN',
    this.enableNotifications = true,
    this.autoBackup = false,
    this.backupLocation = 'local',
    this.enableReadingStats = true,
    this.shareReadingData = false,
    this.autoSaveInterval = 5,
    this.enableVolumeKeyTurn = true,
    this.enableTapTurn = true,
    this.keepScreenOn = true,
    this.autoNightMode = false,
    this.nightModeStartTime = '22:00',
    this.nightModeEndTime = '06:00',
    this.enableBatterySaving = false,
    this.defaultTextSize = 18.0,
    this.defaultLineHeight = 1.6,
    this.defaultFontFamily = 'default',
    this.defaultReaderTheme = 'paper',
    this.defaultReaderMode = 'pagination',
    this.defaultBrightness = 0.5,
    this.defaultMarginHorizontal = 24.0,
    this.defaultMarginVertical = 48.0,
    this.showPageNumber = true,
    this.showChapterTitle = true,
    this.enablePageAnimation = true,
    this.pageAnimationType = 'slide',
    this.readingDirection = 'leftToRight',
  });

  AppSettings copyWith({
    String? language,
    bool? enableNotifications,
    bool? autoBackup,
    String? backupLocation,
    bool? enableReadingStats,
    bool? shareReadingData,
    int? autoSaveInterval,
    bool? enableVolumeKeyTurn,
    bool? enableTapTurn,
    bool? keepScreenOn,
    bool? autoNightMode,
    String? nightModeStartTime,
    String? nightModeEndTime,
    bool? enableBatterySaving,
    double? defaultTextSize,
    double? defaultLineHeight,
    String? defaultFontFamily,
    String? defaultReaderTheme,
    String? defaultReaderMode,
    double? defaultBrightness,
    double? defaultMarginHorizontal,
    double? defaultMarginVertical,
    bool? showPageNumber,
    bool? showChapterTitle,
    bool? enablePageAnimation,
    String? pageAnimationType,
    String? readingDirection,
  }) {
    return AppSettings(
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoBackup: autoBackup ?? this.autoBackup,
      backupLocation: backupLocation ?? this.backupLocation,
      enableReadingStats: enableReadingStats ?? this.enableReadingStats,
      shareReadingData: shareReadingData ?? this.shareReadingData,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      enableVolumeKeyTurn: enableVolumeKeyTurn ?? this.enableVolumeKeyTurn,
      enableTapTurn: enableTapTurn ?? this.enableTapTurn,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      autoNightMode: autoNightMode ?? this.autoNightMode,
      nightModeStartTime: nightModeStartTime ?? this.nightModeStartTime,
      nightModeEndTime: nightModeEndTime ?? this.nightModeEndTime,
      enableBatterySaving: enableBatterySaving ?? this.enableBatterySaving,
      defaultTextSize: defaultTextSize ?? this.defaultTextSize,
      defaultLineHeight: defaultLineHeight ?? this.defaultLineHeight,
      defaultFontFamily: defaultFontFamily ?? this.defaultFontFamily,
      defaultReaderTheme: defaultReaderTheme ?? this.defaultReaderTheme,
      defaultReaderMode: defaultReaderMode ?? this.defaultReaderMode,
      defaultBrightness: defaultBrightness ?? this.defaultBrightness,
      defaultMarginHorizontal: defaultMarginHorizontal ?? this.defaultMarginHorizontal,
      defaultMarginVertical: defaultMarginVertical ?? this.defaultMarginVertical,
      showPageNumber: showPageNumber ?? this.showPageNumber,
      showChapterTitle: showChapterTitle ?? this.showChapterTitle,
      enablePageAnimation: enablePageAnimation ?? this.enablePageAnimation,
      pageAnimationType: pageAnimationType ?? this.pageAnimationType,
      readingDirection: readingDirection ?? this.readingDirection,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'enableNotifications': enableNotifications,
      'autoBackup': autoBackup,
      'backupLocation': backupLocation,
      'enableReadingStats': enableReadingStats,
      'shareReadingData': shareReadingData,
      'autoSaveInterval': autoSaveInterval,
      'enableVolumeKeyTurn': enableVolumeKeyTurn,
      'enableTapTurn': enableTapTurn,
      'keepScreenOn': keepScreenOn,
      'autoNightMode': autoNightMode,
      'nightModeStartTime': nightModeStartTime,
      'nightModeEndTime': nightModeEndTime,
      'enableBatterySaving': enableBatterySaving,
      'defaultTextSize': defaultTextSize,
      'defaultLineHeight': defaultLineHeight,
      'defaultFontFamily': defaultFontFamily,
      'defaultReaderTheme': defaultReaderTheme,
      'defaultReaderMode': defaultReaderMode,
      'defaultBrightness': defaultBrightness,
      'defaultMarginHorizontal': defaultMarginHorizontal,
      'defaultMarginVertical': defaultMarginVertical,
      'showPageNumber': showPageNumber,
      'showChapterTitle': showChapterTitle,
      'enablePageAnimation': enablePageAnimation,
      'pageAnimationType': pageAnimationType,
      'readingDirection': readingDirection,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] ?? 'zh_CN',
      enableNotifications: json['enableNotifications'] ?? true,
      autoBackup: json['autoBackup'] ?? false,
      backupLocation: json['backupLocation'] ?? 'local',
      enableReadingStats: json['enableReadingStats'] ?? true,
      shareReadingData: json['shareReadingData'] ?? false,
      autoSaveInterval: json['autoSaveInterval'] ?? 5,
      enableVolumeKeyTurn: json['enableVolumeKeyTurn'] ?? true,
      enableTapTurn: json['enableTapTurn'] ?? true,
      keepScreenOn: json['keepScreenOn'] ?? true,
      autoNightMode: json['autoNightMode'] ?? false,
      nightModeStartTime: json['nightModeStartTime'] ?? '22:00',
      nightModeEndTime: json['nightModeEndTime'] ?? '06:00',
      enableBatterySaving: json['enableBatterySaving'] ?? false,
      defaultTextSize: (json['defaultTextSize'] ?? 18.0).toDouble(),
      defaultLineHeight: (json['defaultLineHeight'] ?? 1.6).toDouble(),
      defaultFontFamily: json['defaultFontFamily'] ?? 'default',
      defaultReaderTheme: json['defaultReaderTheme'] ?? 'paper',
      defaultReaderMode: json['defaultReaderMode'] ?? 'pagination',
      defaultBrightness: (json['defaultBrightness'] ?? 0.5).toDouble(),
      defaultMarginHorizontal: (json['defaultMarginHorizontal'] ?? 24.0).toDouble(),
      defaultMarginVertical: (json['defaultMarginVertical'] ?? 48.0).toDouble(),
      showPageNumber: json['showPageNumber'] ?? true,
      showChapterTitle: json['showChapterTitle'] ?? true,
      enablePageAnimation: json['enablePageAnimation'] ?? true,
      pageAnimationType: json['pageAnimationType'] ?? 'slide',
      readingDirection: json['readingDirection'] ?? 'leftToRight',
    );
  }
}

// 统计数据
class ReadingStatistics {
  final int totalBooks;
  final int finishedBooks;
  final int readingBooks;
  final int totalReadingTimeMinutes;
  final int totalReadingSessions;
  final DateTime? firstReadDate;
  final DateTime? lastReadDate;
  final Map<String, int> monthlyReadingTime; // YYYY-MM -> minutes
  final Map<String, int> monthlyBooksFinished; // YYYY-MM -> count
  final Map<String, int> dailyReadingTime; // YYYY-MM-DD -> minutes
  final List<String> favoriteGenres;
  final List<String> favoriteAuthors;
  final double averageReadingSpeed; // pages per hour
  final int longestReadingStreak; // days
  final int currentReadingStreak; // days

  const ReadingStatistics({
    this.totalBooks = 0,
    this.finishedBooks = 0,
    this.readingBooks = 0,
    this.totalReadingTimeMinutes = 0,
    this.totalReadingSessions = 0,
    this.firstReadDate,
    this.lastReadDate,
    this.monthlyReadingTime = const {},
    this.monthlyBooksFinished = const {},
    this.dailyReadingTime = const {},
    this.favoriteGenres = const [],
    this.favoriteAuthors = const [],
    this.averageReadingSpeed = 0.0,
    this.longestReadingStreak = 0,
    this.currentReadingStreak = 0,
  });

  String get formattedTotalTime {
    if (totalReadingTimeMinutes < 60) {
      return '$totalReadingTimeMinutes分钟';
    } else if (totalReadingTimeMinutes < 60 * 24) {
      final hours = totalReadingTimeMinutes ~/ 60;
      final minutes = totalReadingTimeMinutes % 60;
      return '$hours小时$minutes分钟';
    } else {
      final days = totalReadingTimeMinutes ~/ (60 * 24);
      final hours = (totalReadingTimeMinutes % (60 * 24)) ~/ 60;
      return '$days�?{hours}小时';
    }
  }

  double get completionRate {
    if (totalBooks == 0) return 0.0;
    return finishedBooks / totalBooks;
  }

  String get formattedCompletionRate {
    return '${(completionRate * 100).toInt()}%';
  }

  double get averageSessionTime {
    if (totalReadingSessions == 0) return 0.0;
    return totalReadingTimeMinutes / totalReadingSessions;
  }

  String get formattedAverageSessionTime {
    final minutes = averageSessionTime.round();
    if (minutes < 60) {
      return '$minutes分钟';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours小时$remainingMinutes分钟';
    }
  }

  // 获取本月阅读时间
  int get thisMonthReadingTime {
    final now = DateTime.now();
    final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return monthlyReadingTime[thisMonth] ?? 0;
  }

  // 获取本月完成书籍�?
  int get thisMonthFinishedBooks {
    final now = DateTime.now();
    final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return monthlyBooksFinished[thisMonth] ?? 0;
  }

  // 获取今天阅读时间
  int get todayReadingTime {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return dailyReadingTime[todayKey] ?? 0;
  }

  String get formattedTodayTime {
    final minutes = todayReadingTime;
    if (minutes < 60) {
      return '$minutes分钟';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours小时$remainingMinutes分钟';
    }
  }

  // 获取阅读天数
  int get totalReadingDays {
    return dailyReadingTime.values.where((time) => time > 0).length;
  }

  // 检查是否有阅读习惯（连�?天以上）
  bool get hasReadingHabit {
    return currentReadingStreak >= 7;
  }

  // 获取最喜欢的类�?
  String? get topGenre {
    if (favoriteGenres.isEmpty) return null;
    return favoriteGenres.first;
  }

  // 获取最喜欢的作�?
  String? get topAuthor {
    if (favoriteAuthors.isEmpty) return null;
    return favoriteAuthors.first;
  }
}

// 应用信息
class AppInfo {
  final String version;
  final String buildNumber;
  final DateTime releaseDate;
  final String description;
  final List<String> features;
  final String developer;
  final String email;
  final String website;
  final String privacy;
  final String terms;

  const AppInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.description,
    required this.features,
    required this.developer,
    required this.email,
    required this.website,
    required this.privacy,
    required this.terms,
  });

  static AppInfo get current => AppInfo(
    version: '1.0.0',
    buildNumber: '1',
    releaseDate: DateTime(2024, 1, 1),
    description: 'XReader 是一款极简、沉浸式的电子书阅读器，专注于提供优质的阅读体验',
    features: [
      '支持EPUB、PDF格式',
      '极简界面设计',
      '多种阅读主题',
      '阅读进度同步',
      '书签和笔记功能',
      '阅读统计分析',
      '夜间模式',
      '字体和排版定制',
    ],
    developer: 'XReader Team',
    email: 'support@xreader.com',
    website: 'https://xreader.com',
    privacy: 'https://xreader.com/privacy',
    terms: 'https://xreader.com/terms',
  );
}
