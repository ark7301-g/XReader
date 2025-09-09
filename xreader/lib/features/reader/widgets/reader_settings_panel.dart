import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/reader_provider.dart';
import '../providers/reader_state.dart';

class ReaderSettingsPanel extends ConsumerStatefulWidget {
  final int bookId;

  const ReaderSettingsPanel({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<ReaderSettingsPanel> createState() => _ReaderSettingsPanelState();
}

class _ReaderSettingsPanelState extends ConsumerState<ReaderSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readerState = ref.watch(readerProvider(widget.bookId));
    final readerSettings = ref.watch(readerSettingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示�?
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // 标题
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              '阅读设置',
              style: GoogleFonts.notoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),

          // 设置内容
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  // 字体设置
                  _buildFontSettings(theme, readerState),
                  
                  SizedBox(height: 24.h),
                  
                  // 主题设置
                  _buildThemeSettings(theme, readerState),
                  
                  SizedBox(height: 24.h),
                  
                  // 阅读模式设置
                  _buildModeSettings(theme, readerState, readerSettings),
                  
                  SizedBox(height: 24.h),
                  
                  // 页面设置
                  _buildPageSettings(theme, readerSettings),
                  
                  SizedBox(height: 24.h),
                  
                  // 其他设置
                  _buildOtherSettings(theme, readerSettings),
                  
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSettings(ThemeData theme, ReaderState readerState) {
    return _SettingSection(
      title: '字体设置',
      children: [
        // 字体大小
        _SettingItem(
          title: '字体大小',
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(readerProvider(widget.bookId).notifier)
                      .updateTextSize(readerState.textSize - 1);
                },
                icon: Icon(Icons.remove, size: 20.sp),
              ),
              Container(
                width: 60.w,
                alignment: Alignment.center,
                child: Text(
                  '${readerState.textSize.toInt()}',
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(readerProvider(widget.bookId).notifier)
                      .updateTextSize(readerState.textSize + 1);
                },
                icon: Icon(Icons.add, size: 20.sp),
              ),
            ],
          ),
        ),

        // 行间距
        _SettingItem(
          title: '行间距',
          child: SizedBox(
            width: 120.w,
            child: Slider(
              value: readerState.lineHeight,
              min: 1.0,
              max: 3.0,
              divisions: 20,
              label: readerState.lineHeight.toStringAsFixed(1),
              onChanged: (value) {
                ref.read(readerProvider(widget.bookId).notifier)
                    .updateLineHeight(value);
              },
            ),
          ),
        ),

        // 字体选择
        _SettingItem(
          title: '字体',
          child: DropdownButton<String>(
            value: readerState.fontFamily,
            onChanged: (value) {
              if (value != null) {
                ref.read(readerProvider(widget.bookId).notifier)
                    .updateFontFamily(value);
              }
            },
            items: const [
              DropdownMenuItem(value: 'default', child: Text('默认')),
              DropdownMenuItem(value: 'serif', child: Text('衬线字体')),
              DropdownMenuItem(value: 'sans-serif', child: Text('无衬线体')),
              DropdownMenuItem(value: 'monospace', child: Text('等宽字体')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSettings(ThemeData theme, ReaderState readerState) {
    return _SettingSection(
      title: '主题设置',
      children: [
        // 夜间模式
        _SettingItem(
          title: '夜间模式',
          child: Switch(
            value: readerState.isNightMode,
            onChanged: (value) {
              ref.read(readerProvider(widget.bookId).notifier).toggleNightMode();
            },
          ),
        ),

        // 阅读主题
        _SettingItem(
          title: '阅读主题',
          child: Wrap(
            spacing: 8.w,
            children: ReaderTheme.values.map((readerTheme) {
              final isSelected = readerState.readerTheme == readerTheme;
              return GestureDetector(
                onTap: () {
                  ref.read(readerProvider(widget.bookId).notifier)
                      .updateReaderTheme(readerTheme);
                },
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                      readerTheme.backgroundColor.substring(1),
                      radix: 16,
                    ) + 0xFF000000),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected ? theme.primaryColor : Colors.grey,
                      width: isSelected ? 3.w : 1.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16.sp,
                          color: Color(int.parse(
                            readerTheme.textColor.substring(1),
                            radix: 16,
                          ) + 0xFF000000),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),

        // 亮度调节
        _SettingItem(
          title: '亮度',
          child: SizedBox(
            width: 120.w,
            child: Slider(
              value: readerState.brightness,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                ref.read(readerProvider(widget.bookId).notifier)
                    .updateBrightness(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSettings(
    ThemeData theme,
    ReaderState readerState,
    ReaderSettings readerSettings,
  ) {
    return _SettingSection(
      title: '阅读模式',
      children: [
        // 阅读模式选择
        _SettingItem(
          title: '模式',
          child: SegmentedButton<ReaderMode>(
            segments: ReaderMode.values.map((mode) {
              return ButtonSegment<ReaderMode>(
                value: mode,
                label: Text(mode.label),
              );
            }).toList(),
            selected: {readerState.readerMode},
            onSelectionChanged: (Set<ReaderMode> selection) {
              ref.read(readerProvider(widget.bookId).notifier)
                  .updateReaderMode(selection.first);
            },
          ),
        ),

        // 翻页动画
        _SettingItem(
          title: '翻页动画',
          child: DropdownButton<PageTurnAnimation>(
            value: readerState.pageTurnAnimation,
            onChanged: (value) {
              if (value != null) {
                ref.read(readerProvider(widget.bookId).notifier)
                    .updatePageTurnAnimation(value);
              }
            },
            items: PageTurnAnimation.values.map((animation) {
              return DropdownMenuItem(
                value: animation,
                child: Text(animation.label),
              );
            }).toList(),
          ),
        ),

        // 阅读方向
        _SettingItem(
          title: '阅读方向',
          child: DropdownButton<ReadingDirection>(
            value: readerState.readingDirection,
            onChanged: (value) {
              if (value != null) {
                ref.read(readerProvider(widget.bookId).notifier)
                    .updateReadingDirection(value);
              }
            },
            items: ReadingDirection.values.map((direction) {
              return DropdownMenuItem(
                value: direction,
                child: Text(direction.label),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSettings(ThemeData theme, ReaderSettings readerSettings) {
    return _SettingSection(
      title: '页面设置',
      children: [
        // 显示页码
        _SettingItem(
          title: '显示页码',
          child: Switch(
            value: readerSettings.showPageNumber,
            onChanged: (value) {
              ref.read(readerSettingsProvider.notifier).togglePageNumber();
            },
          ),
        ),

        // 显示章节标题
        _SettingItem(
          title: '显示章节',
          child: Switch(
            value: readerSettings.showChapterTitle,
            onChanged: (value) {
              ref.read(readerSettingsProvider.notifier).toggleChapterTitle();
            },
          ),
        ),

        // 页面边距
        _SettingItem(
          title: '水平边距',
          child: SizedBox(
            width: 120.w,
            child: Slider(
              value: readerSettings.marginHorizontal,
              min: 0.0,
              max: 50.0,
              divisions: 10,
              label: readerSettings.marginHorizontal.toInt().toString(),
              onChanged: (value) {
                ref.read(readerSettingsProvider.notifier).updateMargins(
                  value,
                  readerSettings.marginVertical,
                );
              },
            ),
          ),
        ),

        _SettingItem(
          title: '垂直边距',
          child: SizedBox(
            width: 120.w,
            child: Slider(
              value: readerSettings.marginVertical,
              min: 0.0,
              max: 100.0,
              divisions: 20,
              label: readerSettings.marginVertical.toInt().toString(),
              onChanged: (value) {
                ref.read(readerSettingsProvider.notifier).updateMargins(
                  readerSettings.marginHorizontal,
                  value,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherSettings(ThemeData theme, ReaderSettings readerSettings) {
    return _SettingSection(
      title: '其他设置',
      children: [
        // 保持屏幕常亮
        _SettingItem(
          title: '保持屏幕常亮',
          child: Switch(
            value: readerSettings.keepScreenOn,
            onChanged: (value) {
              ref.read(readerSettingsProvider.notifier).toggleKeepScreenOn();
            },
          ),
        ),

        // 音量键翻页
        _SettingItem(
          title: '音量键翻页',
          child: Switch(
            value: readerSettings.enableVolumeKeyTurn,
            onChanged: (value) {
              ref.read(readerSettingsProvider.notifier).toggleVolumeKeyTurn();
            },
          ),
        ),

        // 点击翻页
        _SettingItem(
          title: '点击翻页',
          child: Switch(
            value: readerSettings.enableTapTurn,
            onChanged: (value) {
              ref.read(readerSettingsProvider.notifier).toggleTapTurn();
            },
          ),
        ),

        // 自动夜间模式
        _SettingItem(
          title: '自动夜间模式',
          child: Switch(
            value: readerSettings.autoNightMode,
            onChanged: (value) {
              ref.read(readerSettingsProvider.notifier).toggleAutoNightMode();
            },
          ),
        ),
      ],
    );
  }
}

/// 设置区块
class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: children
                .expand((child) => [child, if (child != children.last) const CustomDivider()])
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// 设置�?
class _SettingItem extends StatelessWidget {
  final String title;
  final Widget child;
  final String? subtitle;

  const _SettingItem({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: GoogleFonts.notoSans(
                      fontSize: 12.sp,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 16.w),
          child,
        ],
      ),
    );
  }
}
