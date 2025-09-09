import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/temp_settings_provider.dart';

import '../pages/reading_statistics_page.dart';

class StatisticsSection extends ConsumerWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(readingStatisticsProvider);

    return _SettingsSection(
      title: '阅读统计',
      children: [
        _SettingsItem(
          icon: Icons.analytics_outlined,
          title: '详细统计',
          subtitle: '查看完整的阅读数据统计',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ReadingStatisticsPage(),
              ),
            );
          },
        ),
        
        // 快速统计预�?
        Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  _StatItem('总书籍', '${stats.totalBooks}本', Icons.library_books),
                  SizedBox(width: 16.w),
                  _StatItem('已读书籍', '${stats.finishedBooks}本', Icons.done_all),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _StatItem('总时间', stats.formattedTotalTime, Icons.access_time),
                  SizedBox(width: 16.w),
                  _StatItem('今日阅读', stats.formattedTodayTime, Icons.today),
                ],
              ),
              if (stats.currentReadingStreak > 0) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _StatItem('连续阅读', '${stats.currentReadingStreak}天', Icons.local_fire_department),
                    SizedBox(width: 16.w),
                    _StatItem('完成率', stats.formattedCompletionRate, Icons.trending_up),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: theme.primaryColor,
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: GoogleFonts.notoSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 10.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
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
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
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
      trailing: (onTap != null ? Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: theme.textTheme.bodySmall?.color,
      ) : null),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }
}
