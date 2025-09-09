import 'package:flutter_riverpod/flutter_riverpod.dart';

// 临时设置数据类
class TempAppSettings {
  final double defaultTextSize;
  final double defaultLineHeight;
  final String defaultFontFamily;
  final String defaultReaderTheme;
  final String defaultReaderMode;
  final double defaultMarginHorizontal;
  final double defaultMarginVertical;
  final bool enableVolumeKeyTurn;
  final bool enableTapTurn;
  final bool keepScreenOn;
  final bool showPageNumber;
  final bool showChapterTitle;
  final bool enableNotifications;
  final bool autoBackup;
  final bool enableReadingStats;
  final bool enableBatterySaving;
  final int autoSaveInterval;

  const TempAppSettings({
    this.defaultTextSize = 18.0,
    this.defaultLineHeight = 1.6,
    this.defaultFontFamily = 'default',
    this.defaultReaderTheme = 'paper',
    this.defaultReaderMode = 'pagination',
    this.defaultMarginHorizontal = 24.0,
    this.defaultMarginVertical = 48.0,
    this.enableVolumeKeyTurn = true,
    this.enableTapTurn = true,
    this.keepScreenOn = false,
    this.showPageNumber = true,
    this.showChapterTitle = true,
    this.enableNotifications = true,
    this.autoBackup = false,
    this.enableReadingStats = true,
    this.enableBatterySaving = false,
    this.autoSaveInterval = 5,
  });
}

// 临时统计数据类
class TempReadingStats {
  final int totalBooks;
  final int finishedBooks;
  final String formattedTotalTime;
  final String formattedTodayTime;
  final int currentReadingStreak;
  final String formattedCompletionRate;

  const TempReadingStats({
    this.totalBooks = 0,
    this.finishedBooks = 0,
    this.formattedTotalTime = '0小时',
    this.formattedTodayTime = '0分钟',
    this.currentReadingStreak = 0,
    this.formattedCompletionRate = '0%',
  });
}

// 临时应用信息类
class TempAppInfo {
  final String version;
  final String buildNumber;
  final String developer;

  const TempAppInfo({
    this.version = '1.0.0',
    this.buildNumber = '1',
    this.developer = 'XReader Team',
  });
}

// 临时设置控制器
class TempSettingsNotifier extends StateNotifier<TempAppSettings> {
  TempSettingsNotifier() : super(const TempAppSettings());

  void setDefaultTextSize(double size) => state = const TempAppSettings();
  void setDefaultLineHeight(double height) => state = const TempAppSettings();
  void setDefaultFontFamily(String family) => state = const TempAppSettings();
  void setDefaultReaderTheme(String theme) => state = const TempAppSettings();
  void setDefaultReaderMode(String mode) => state = const TempAppSettings();
  void setDefaultMargins(double horizontal, double vertical) => state = const TempAppSettings();
  void toggleVolumeKeyTurn() => state = const TempAppSettings();
  void toggleTapTurn() => state = const TempAppSettings();
  void toggleKeepScreenOn() => state = const TempAppSettings();
  void toggleShowPageNumber() => state = const TempAppSettings();
  void toggleShowChapterTitle() => state = const TempAppSettings();
  void toggleNotifications() => state = const TempAppSettings();
  void toggleAutoBackup() => state = const TempAppSettings();
  void toggleReadingStats() => state = const TempAppSettings();
  void toggleBatterySaving() => state = const TempAppSettings();
  void setAutoSaveInterval(int minutes) => state = const TempAppSettings();
  void resetReadingSettings() => state = const TempAppSettings();
}

// Providers
final appSettingsProvider = StateNotifierProvider<TempSettingsNotifier, TempAppSettings>((ref) {
  return TempSettingsNotifier();
});

final readingStatisticsProvider = StateProvider<TempReadingStats>((ref) => const TempReadingStats());

final appInfoProvider = Provider<TempAppInfo>((ref) => const TempAppInfo());
