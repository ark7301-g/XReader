import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/temp_settings_provider.dart';


class AppSettingsSection extends ConsumerWidget {
  const AppSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return _SettingsSection(
      title: '应用设置',
      children: [
        _SettingsItem(
          icon: Icons.notifications_outlined,
          title: '消息通知',
          subtitle: '接收应用通知',
          trailing: Switch(
            value: settings.enableNotifications,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleNotifications();
            },
          ),
        ),
        
        _SettingsItem(
          icon: Icons.backup_outlined,
          title: '自动备份',
          subtitle: '自动备份阅读数据',
          trailing: Switch(
            value: settings.autoBackup,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleAutoBackup();
            },
          ),
        ),
        
        _SettingsItem(
          icon: Icons.analytics_outlined,
          title: '阅读统计',
          subtitle: '收集阅读数据用于统计',
          trailing: Switch(
            value: settings.enableReadingStats,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleReadingStats();
            },
          ),
        ),
        
        _SettingsItem(
          icon: Icons.battery_saver,
          title: '省电模式',
          subtitle: '减少动画和后台活动',
          trailing: Switch(
            value: settings.enableBatterySaving,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).toggleBatterySaving();
            },
          ),
        ),
        
        _SettingsItem(
          icon: Icons.schedule,
          title: '自动保存间隔',
          subtitle: '每${settings.autoSaveInterval}分钟自动保存',
          onTap: () => _showAutoSaveDialog(context, ref, settings),
        ),
      ],
    );
  }

  void _showAutoSaveDialog(BuildContext context, WidgetRef ref, settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自动保存间隔'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('当前间隔: ${settings.autoSaveInterval}分钟'),
                Slider(
                  value: settings.autoSaveInterval.toDouble(),
                  min: 1.0,
                  max: 30.0,
                  divisions: 29,
                  label: '${settings.autoSaveInterval}分钟',
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier)
                        .setAutoSaveInterval(value.toInt());
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
}

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

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(icon, size: 24.sp),
      title: Text(
        title,
        style: GoogleFonts.notoSans(fontSize: 16.sp),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }
}
