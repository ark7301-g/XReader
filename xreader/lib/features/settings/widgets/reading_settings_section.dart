import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/temp_settings_provider.dart';


class ReadingSettingsSection extends ConsumerWidget {
  const ReadingSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);

    return _SettingsSection(
      title: '阅读设置',
      children: [
        // 默认字体大小
        _SettingsItem(
          icon: Icons.text_fields,
          title: '默认字体大小',
          subtitle: '${settings.defaultTextSize.toInt()}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  if (settings.defaultTextSize > 12) {
                    ref.read(appSettingsProvider.notifier)
                        .setDefaultTextSize(settings.defaultTextSize - 1);
                  }
                },
                icon: Icon(Icons.remove, size: 20.sp),
              ),
              Text(
                '${settings.defaultTextSize.toInt()}',
                style: GoogleFonts.notoSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (settings.defaultTextSize < 32) {
                    ref.read(appSettingsProvider.notifier)
                        .setDefaultTextSize(settings.defaultTextSize + 1);
                  }
                },
                icon: Icon(Icons.add, size: 20.sp),
              ),
            ],
          ),
          onTap: () => _showTextSizeDialog(context, ref, settings),
        ),

        // 默认行间距
        _SettingsItem(
          icon: Icons.format_line_spacing,
          title: '默认行间距',
          subtitle: settings.defaultLineHeight.toStringAsFixed(1),
          onTap: () => _showLineHeightDialog(context, ref, settings),
        ),

        // 默认字体
        _SettingsItem(
          icon: Icons.font_download,
          title: '默认字体',
          subtitle: _getFontDisplayName(settings.defaultFontFamily),
          onTap: () => _showFontFamilyDialog(context, ref, settings),
        ),

        // 默认主题
        _SettingsItem(
          icon: Icons.palette,
          title: '默认阅读主题',
          subtitle: _getThemeDisplayName(settings.defaultReaderTheme),
          onTap: () => _showThemeDialog(context, ref, settings),
        ),

        // 默认阅读模式
        _SettingsItem(
          icon: Icons.view_agenda,
          title: '默认阅读模式',
          subtitle: _getModeDisplayName(settings.defaultReaderMode),
          onTap: () => _showModeDialog(context, ref, settings),
        ),

        // 默认页面边距
        _SettingsItem(
          icon: Icons.border_outer,
          title: '页面边距',
          subtitle: '水平${settings.defaultMarginHorizontal.toInt()} 垂直${settings.defaultMarginVertical.toInt()}',
          onTap: () => _showMarginsDialog(context, ref, settings),
        ),

        // 音量键翻页
        _SettingsItem(
          icon: Icons.volume_up,
          title: '音量键翻页',
          subtitle: '使用音量键控制翻页',
          trailing: Switch(
            value: settings.enableVolumeKeyTurn,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleVolumeKeyTurn();
            },
          ),
        ),

        // 点击翻页
        _SettingsItem(
          icon: Icons.touch_app,
          title: '点击翻页',
          subtitle: '点击屏幕边缘翻页',
          trailing: Switch(
            value: settings.enableTapTurn,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleTapTurn();
            },
          ),
        ),

        // 保持屏幕常亮
        _SettingsItem(
          icon: Icons.screen_lock_portrait,
          title: '保持屏幕常亮',
          subtitle: '阅读时屏幕不自动息屏',
          trailing: Switch(
            value: settings.keepScreenOn,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleKeepScreenOn();
            },
          ),
        ),

        // 显示页码
        _SettingsItem(
          icon: Icons.numbers,
          title: '显示页码',
          subtitle: '在阅读界面显示页码',
          trailing: Switch(
            value: settings.showPageNumber,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleShowPageNumber();
            },
          ),
        ),

        // 显示章节标题
        _SettingsItem(
          icon: Icons.title,
          title: '显示章节标题',
          subtitle: '在阅读界面显示当前章节',
          trailing: Switch(
            value: settings.showChapterTitle,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleShowChapterTitle();
            },
          ),
        ),

        // 重置阅读设置
        _SettingsItem(
          icon: Icons.restore,
          title: '重置阅读设置',
          subtitle: '恢复阅读设置到默认值',
          onTap: () => _showResetReadingSettingsDialog(context, ref),
          isDestructive: true,
        ),
      ],
    );
  }

  String _getFontDisplayName(String fontFamily) {
    switch (fontFamily) {
      case 'default':
        return '默认字体';
      case 'serif':
        return '衬线字体';
      case 'sans-serif':
        return '无衬线体';
      case 'monospace':
        return '等宽字体';
      default:
        return '默认字体';
    }
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'paper':
        return '纸质';
      case 'night':
        return '夜间';
      case 'sepia':
        return '棕褐';
      case 'green':
        return '护眼色';
      case 'blue':
        return '蓝色';
      default:
        return '纸质';
    }
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'pagination':
        return '分页模式';
      case 'scroll':
        return '滚动模式';
      default:
        return '分页模式';
    }
  }

  void _showTextSizeDialog(BuildContext context, WidgetRef ref, settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字体大小'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '示例文本',
                  style: GoogleFonts.sourceSerif4(
                    fontSize: settings.defaultTextSize.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Slider(
                  value: settings.defaultTextSize,
                  min: 12.0,
                  max: 32.0,
                  divisions: 20,
                  label: settings.defaultTextSize.toInt().toString(),
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier).setDefaultTextSize(value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showLineHeightDialog(BuildContext context, WidgetRef ref, settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('行间距'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '这是示例文本\n用于预览行间距效果\n您可以调节滑块来改变行间距',
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 16.sp,
                      height: settings.defaultLineHeight,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Slider(
                  value: settings.defaultLineHeight,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  label: settings.defaultLineHeight.toStringAsFixed(1),
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier).setDefaultLineHeight(value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFontFamilyDialog(BuildContext context, WidgetRef ref, settings) {
    final fontOptions = [
      {'value': 'default', 'label': '默认字体'},
      {'value': 'serif', 'label': '衬线字体'},
      {'value': 'sans-serif', 'label': '无衬线体'},
      {'value': 'monospace', 'label': '等宽字体'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择字体'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fontOptions.map((font) {
            final isSelected = settings.defaultFontFamily == font['value'];
            return ListTile(
              title: Text(
                font['label']!,
                style: _getFontStyle(font['value']!),
              ),
              leading: Radio<String>(
                value: font['value']!,
                groupValue: settings.defaultFontFamily,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).setDefaultFontFamily(value);
                  }
                },
              ),
              onTap: () {
                ref.read(appSettingsProvider.notifier).setDefaultFontFamily(font['value']!);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  TextStyle _getFontStyle(String fontFamily) {
    switch (fontFamily) {
      case 'serif':
        return GoogleFonts.sourceSerif4(fontSize: 16.sp);
      case 'sans-serif':
        return GoogleFonts.notoSans(fontSize: 16.sp);
      case 'monospace':
        return GoogleFonts.robotoMono(fontSize: 16.sp);
      default:
        return GoogleFonts.sourceSerif4(fontSize: 16.sp);
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, settings) {
    final themeOptions = [
      {'value': 'paper', 'label': '纸质', 'bg': '#FFFEF7', 'text': '#2B2B2B'},
      {'value': 'night', 'label': '夜间', 'bg': '#1A1A1A', 'text': '#CCCCCC'},
      {'value': 'sepia', 'label': '棕褐', 'bg': '#F4F1EA', 'text': '#5B4636'},
      {'value': 'green', 'label': '护眼色', 'bg': '#E8F5E8', 'text': '#2B2B2B'},
      {'value': 'blue', 'label': '蓝色', 'bg': '#E8F4FD', 'text': '#2B2B2B'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择阅读主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themeOptions.map((theme) {
            final isSelected = settings.defaultReaderTheme == theme['value'];
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                title: Text(theme['label']!),
                leading: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Color(int.parse(theme['bg']!.substring(1), radix: 16) + 0xFF000000),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                      width: isSelected ? 3.w : 1.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16.sp,
                          color: Color(int.parse(theme['text']!.substring(1), radix: 16) + 0xFF000000),
                        )
                      : null,
                ),
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setDefaultReaderTheme(theme['value']!);
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showModeDialog(BuildContext context, WidgetRef ref, settings) {
    final modeOptions = [
      {'value': 'pagination', 'label': '分页模式', 'desc': '传统的翻页阅读方式'},
      {'value': 'scroll', 'label': '滚动模式', 'desc': '上下滚动连续阅读'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择阅读模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modeOptions.map((mode) {
            return ListTile(
              title: Text(mode['label']!),
              subtitle: Text(mode['desc']!),
              leading: Radio<String>(
                value: mode['value']!,
                groupValue: settings.defaultReaderMode,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).setDefaultReaderMode(value);
                  }
                },
              ),
              onTap: () {
                ref.read(appSettingsProvider.notifier).setDefaultReaderMode(mode['value']!);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMarginsDialog(BuildContext context, WidgetRef ref, settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('页面边距'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 水平边距
                Row(
                  children: [
                    const Text('水平边距'),
                    Expanded(
                      child: Slider(
                        value: settings.defaultMarginHorizontal,
                        min: 0.0,
                        max: 50.0,
                        divisions: 10,
                        label: settings.defaultMarginHorizontal.toInt().toString(),
                        onChanged: (value) {
                          ref.read(appSettingsProvider.notifier).setDefaultMargins(
                            value,
                            settings.defaultMarginVertical,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                // 垂直边距
                Row(
                  children: [
                    const Text('垂直边距'),
                    Expanded(
                      child: Slider(
                        value: settings.defaultMarginVertical,
                        min: 0.0,
                        max: 100.0,
                        divisions: 20,
                        label: settings.defaultMarginVertical.toInt().toString(),
                        onChanged: (value) {
                          ref.read(appSettingsProvider.notifier).setDefaultMargins(
                            settings.defaultMarginHorizontal,
                            value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showResetReadingSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置阅读设置'),
        content: const Text('确定要将阅读设置恢复到默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).resetReadingSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('阅读设置已重置')),
              );
            },
            child: Text(
              '重置',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置区块
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
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

/// 设置项
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        size: 24.sp,
        color: isDestructive 
            ? theme.colorScheme.error 
            : theme.iconTheme.color,
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 16.sp,
          color: isDestructive 
              ? theme.colorScheme.error 
              : theme.textTheme.bodyMedium?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null ? Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: theme.textTheme.bodySmall?.color,
      ) : null),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 4.h,
      ),
    );
  }
}
