import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/enhanced_database_service.dart';
import '../../../data/models/book.dart';
import 'settings_state.dart';

// Settings Provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

// Reading Statistics Provider
final readingStatisticsProvider = StateNotifierProvider<ReadingStatisticsNotifier, ReadingStatistics>((ref) {
  return ReadingStatisticsNotifier();
});

// App Info Provider
final appInfoProvider = Provider<AppInfo>((ref) {
  return AppInfo.current;
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';

  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        state = AppSettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('加载设置失败: $e');
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(state.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('保存设置失败: $e');
    }
  }

  // 通用设置方法
  Future<void> _updateSetting<T>(T value, AppSettings Function(T) updater) async {
    state = updater(value);
    await _saveSettings();
  }

  /// 语言设置
  Future<void> setLanguage(String language) async {
    await _updateSetting(language, (value) => state.copyWith(language: value));
  }

  /// 通知设置
  Future<void> toggleNotifications() async {
    await _updateSetting(!state.enableNotifications, 
        (value) => state.copyWith(enableNotifications: value));
  }

  /// 自动备份设置
  Future<void> toggleAutoBackup() async {
    await _updateSetting(!state.autoBackup, 
        (value) => state.copyWith(autoBackup: value));
  }

  Future<void> setBackupLocation(String location) async {
    await _updateSetting(location, (value) => state.copyWith(backupLocation: value));
  }

  /// 阅读统计设置
  Future<void> toggleReadingStats() async {
    await _updateSetting(!state.enableReadingStats, 
        (value) => state.copyWith(enableReadingStats: value));
  }

  Future<void> toggleShareReadingData() async {
    await _updateSetting(!state.shareReadingData, 
        (value) => state.copyWith(shareReadingData: value));
  }

  /// 自动保存间隔
  Future<void> setAutoSaveInterval(int minutes) async {
    await _updateSetting(minutes, (value) => state.copyWith(autoSaveInterval: value));
  }

  /// 阅读控制设置
  Future<void> toggleVolumeKeyTurn() async {
    await _updateSetting(!state.enableVolumeKeyTurn, 
        (value) => state.copyWith(enableVolumeKeyTurn: value));
  }

  Future<void> toggleTapTurn() async {
    await _updateSetting(!state.enableTapTurn, 
        (value) => state.copyWith(enableTapTurn: value));
  }

  Future<void> toggleKeepScreenOn() async {
    await _updateSetting(!state.keepScreenOn, 
        (value) => state.copyWith(keepScreenOn: value));
  }

  /// 夜间模式设置
  Future<void> toggleAutoNightMode() async {
    await _updateSetting(!state.autoNightMode, 
        (value) => state.copyWith(autoNightMode: value));
  }

  Future<void> setNightModeTime(String startTime, String endTime) async {
    state = state.copyWith(
      nightModeStartTime: startTime,
      nightModeEndTime: endTime,
    );
    await _saveSettings();
  }

  /// 电池节约模式
  Future<void> toggleBatterySaving() async {
    await _updateSetting(!state.enableBatterySaving, 
        (value) => state.copyWith(enableBatterySaving: value));
  }

  /// 默认阅读设置
  Future<void> setDefaultTextSize(double size) async {
    await _updateSetting(size, (value) => state.copyWith(defaultTextSize: value));
  }

  Future<void> setDefaultLineHeight(double height) async {
    await _updateSetting(height, (value) => state.copyWith(defaultLineHeight: value));
  }

  Future<void> setDefaultFontFamily(String family) async {
    await _updateSetting(family, (value) => state.copyWith(defaultFontFamily: value));
  }

  Future<void> setDefaultReaderTheme(String theme) async {
    await _updateSetting(theme, (value) => state.copyWith(defaultReaderTheme: value));
  }

  Future<void> setDefaultReaderMode(String mode) async {
    await _updateSetting(mode, (value) => state.copyWith(defaultReaderMode: value));
  }

  Future<void> setDefaultBrightness(double brightness) async {
    await _updateSetting(brightness, (value) => state.copyWith(defaultBrightness: value));
  }

  Future<void> setDefaultMargins(double horizontal, double vertical) async {
    state = state.copyWith(
      defaultMarginHorizontal: horizontal,
      defaultMarginVertical: vertical,
    );
    await _saveSettings();
  }

  /// 页面显示设置
  Future<void> toggleShowPageNumber() async {
    await _updateSetting(!state.showPageNumber, 
        (value) => state.copyWith(showPageNumber: value));
  }

  Future<void> toggleShowChapterTitle() async {
    await _updateSetting(!state.showChapterTitle, 
        (value) => state.copyWith(showChapterTitle: value));
  }

  /// 动画设置
  Future<void> togglePageAnimation() async {
    await _updateSetting(!state.enablePageAnimation, 
        (value) => state.copyWith(enablePageAnimation: value));
  }

  Future<void> setPageAnimationType(String type) async {
    await _updateSetting(type, (value) => state.copyWith(pageAnimationType: value));
  }

  Future<void> setReadingDirection(String direction) async {
    await _updateSetting(direction, (value) => state.copyWith(readingDirection: value));
  }

  /// 重置设置
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  /// 重置阅读设置
  Future<void> resetReadingSettings() async {
    state = state.copyWith(
      defaultTextSize: 18.0,
      defaultLineHeight: 1.6,
      defaultFontFamily: 'default',
      defaultReaderTheme: 'paper',
      defaultReaderMode: 'pagination',
      defaultBrightness: 0.5,
      defaultMarginHorizontal: 24.0,
      defaultMarginVertical: 48.0,
      showPageNumber: true,
      showChapterTitle: true,
      enablePageAnimation: true,
      pageAnimationType: 'slide',
      readingDirection: 'leftToRight',
    );
    await _saveSettings();
  }

  /// 导出设置
  Map<String, dynamic> exportSettings() {
    return state.toJson();
  }

  /// 导入设置
  Future<void> importSettings(Map<String, dynamic> settingsMap) async {
    try {
      state = AppSettings.fromJson(settingsMap);
      await _saveSettings();
    } catch (e) {
      print('导入设置失败: $e');
      throw Exception('设置格式无效');
    }
  }
}

class ReadingStatisticsNotifier extends StateNotifier<ReadingStatistics> {
  ReadingStatisticsNotifier() : super(const ReadingStatistics()) {
    _loadStatistics();
  }

  /// 加载统计数据
  Future<void> _loadStatistics() async {
    try {
      final books = await EnhancedDatabaseService.getAllBooks();
      final stats = await _calculateStatistics(books);
      state = stats;
    } catch (e) {
      print('加载统计数据失败: $e');
    }
  }

  /// 刷新统计数据
  Future<void> refreshStatistics() async {
    await _loadStatistics();
  }

  /// 计算统计数据
  Future<ReadingStatistics> _calculateStatistics(List<Book> books) async {
    if (books.isEmpty) {
      return const ReadingStatistics();
    }

    // 基础统计
    final totalBooks = books.length;
    final finishedBooks = books.where((book) => book.isFinished).length;
    final readingBooks = books.where((book) => book.hasStartedReading && !book.isFinished).length;
    final totalReadingTime = books.fold<int>(0, (sum, book) => sum + book.readingTimeMinutes);
    final totalSessions = books.fold<int>(0, (sum, book) => sum + book.totalReadingSessions);

    // 时间统计
    final readDates = books
        .where((book) => book.lastReadDate != null)
        .map((book) => book.lastReadDate!)
        .toList();
    
    DateTime? firstReadDate;
    DateTime? lastReadDate;
    
    if (readDates.isNotEmpty) {
      readDates.sort();
      firstReadDate = readDates.first;
      lastReadDate = readDates.last;
    }

    // 月度统计
    final monthlyReadingTime = <String, int>{};
    final monthlyBooksFinished = <String, int>{};
    final dailyReadingTime = <String, int>{};

    for (final book in books) {
      if (book.lastReadDate != null) {
        final date = book.lastReadDate!;
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        // 月度阅读时间
        monthlyReadingTime[monthKey] = (monthlyReadingTime[monthKey] ?? 0) + book.readingTimeMinutes;
        
        // 日度阅读时间
        dailyReadingTime[dayKey] = (dailyReadingTime[dayKey] ?? 0) + book.readingTimeMinutes;
        
        // 月度完成书籍
        if (book.isFinished) {
          monthlyBooksFinished[monthKey] = (monthlyBooksFinished[monthKey] ?? 0) + 1;
        }
      }
    }

    // 作者统�?
    final authorCount = <String, int>{};
    for (final book in books) {
      if (book.author != null && book.author!.isNotEmpty) {
        authorCount[book.author!] = (authorCount[book.author!] ?? 0) + 1;
      }
    }
    
    final favoriteAuthors = authorCount.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10);

    // 阅读速度计算（简化版本）
    double averageSpeed = 0.0;
    if (totalReadingTime > 0) {
      final totalPages = books.fold<int>(0, (sum, book) => sum + book.totalPages);
      averageSpeed = totalPages / (totalReadingTime / 60.0); // pages per hour
    }

    // 阅读连续天数计算（简化版本）
    int currentStreak = 0;
    int longestStreak = 0;
    
    if (dailyReadingTime.isNotEmpty) {
      final sortedDays = dailyReadingTime.keys.toList()..sort();
      int tempStreak = 0;
      
      for (int i = 0; i < sortedDays.length; i++) {
        if (dailyReadingTime[sortedDays[i]]! > 0) {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else {
          tempStreak = 0;
        }
      }
      
      // 计算当前连续天数（从今天往回算�?
      final today = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final dayKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        
        if ((dailyReadingTime[dayKey] ?? 0) > 0) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    return ReadingStatistics(
      totalBooks: totalBooks,
      finishedBooks: finishedBooks,
      readingBooks: readingBooks,
      totalReadingTimeMinutes: totalReadingTime,
      totalReadingSessions: totalSessions,
      firstReadDate: firstReadDate,
      lastReadDate: lastReadDate,
      monthlyReadingTime: monthlyReadingTime,
      monthlyBooksFinished: monthlyBooksFinished,
      dailyReadingTime: dailyReadingTime,
      favoriteGenres: const [], // 需要书籍类型信�?
      favoriteAuthors: favoriteAuthors.map((e) => e.key).toList(),
      averageReadingSpeed: averageSpeed,
      longestReadingStreak: longestStreak,
      currentReadingStreak: currentStreak,
    );
  }

  /// 获取年度统计
  Map<String, dynamic> getYearlyStats(int year) {
    final yearlyReadingTime = <int, int>{};
    final yearlyBooksFinished = <int, int>{};
    
    for (final entry in state.monthlyReadingTime.entries) {
      final date = entry.key.split('-');
      final entryYear = int.parse(date[0]);
      final month = int.parse(date[1]);
      
      if (entryYear == year) {
        yearlyReadingTime[month] = entry.value;
      }
    }
    
    for (final entry in state.monthlyBooksFinished.entries) {
      final date = entry.key.split('-');
      final entryYear = int.parse(date[0]);
      final month = int.parse(date[1]);
      
      if (entryYear == year) {
        yearlyBooksFinished[month] = entry.value;
      }
    }
    
    return {
      'year': year,
      'monthlyReadingTime': yearlyReadingTime,
      'monthlyBooksFinished': yearlyBooksFinished,
      'totalTime': yearlyReadingTime.values.fold<int>(0, (sum, time) => sum + time),
      'totalBooks': yearlyBooksFinished.values.fold<int>(0, (sum, count) => sum + count),
    };
  }

  /// 获取本周统计
  Map<String, int> getWeeklyStats() {
    final now = DateTime.now();
    final weeklyStats = <String, int>{};
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayName = _getDayName(date.weekday);
      
      weeklyStats[dayName] = state.dailyReadingTime[dayKey] ?? 0;
    }
    
    return weeklyStats;
  }

  String _getDayName(int weekday) {
    const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return dayNames[weekday - 1];
  }

  /// 获取阅读目标完成情况
  Map<String, dynamic> getGoalProgress(int dailyGoalMinutes, int weeklyGoalBooks) {
    final todayTime = state.todayReadingTime;
    final weeklyStats = getWeeklyStats();
    final weeklyTime = weeklyStats.values.fold<int>(0, (sum, time) => sum + time);
    
    // 本周完成书籍数（简化计算）
    final weeklyBooks = state.thisMonthFinishedBooks; // 使用月度数据作为近似
    
    return {
      'dailyProgress': dailyGoalMinutes > 0 ? todayTime / dailyGoalMinutes : 0.0,
      'weeklyTimeProgress': weeklyGoalBooks > 0 ? weeklyTime / (dailyGoalMinutes * 7) : 0.0,
      'weeklyBooksProgress': weeklyGoalBooks > 0 ? weeklyBooks / weeklyGoalBooks : 0.0,
      'todayTime': todayTime,
      'weeklyTime': weeklyTime,
      'weeklyBooks': weeklyBooks,
    };
  }

  /// 清除统计数据
  Future<void> clearStatistics() async {
    state = const ReadingStatistics();
  }

  /// 导出统计数据
  Map<String, dynamic> exportStatistics() {
    return {
      'totalBooks': state.totalBooks,
      'finishedBooks': state.finishedBooks,
      'readingBooks': state.readingBooks,
      'totalReadingTimeMinutes': state.totalReadingTimeMinutes,
      'totalReadingSessions': state.totalReadingSessions,
      'firstReadDate': state.firstReadDate?.toIso8601String(),
      'lastReadDate': state.lastReadDate?.toIso8601String(),
      'monthlyReadingTime': state.monthlyReadingTime,
      'monthlyBooksFinished': state.monthlyBooksFinished,
      'dailyReadingTime': state.dailyReadingTime,
      'favoriteGenres': state.favoriteGenres,
      'favoriteAuthors': state.favoriteAuthors,
      'averageReadingSpeed': state.averageReadingSpeed,
      'longestReadingStreak': state.longestReadingStreak,
      'currentReadingStreak': state.currentReadingStreak,
    };
  }
}
