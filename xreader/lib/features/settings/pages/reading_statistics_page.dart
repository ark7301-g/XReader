import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/temp_settings_provider.dart';


class ReadingStatisticsPage extends ConsumerWidget {
  const ReadingStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(readingStatisticsProvider);
    // final theme = Theme.of(context);

    return Scaffold(
      appBar: const SimpleAppBar(title: '阅读统计'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // 总体统计
            _buildOverallStats(context, stats),
            
            SizedBox(height: 24.h),
            
            // 阅读习惯
            _buildReadingHabits(context, stats),
            
            SizedBox(height: 24.h),
            
            // 本月统计
            _buildMonthlyStats(context, stats),
            
            SizedBox(height: 24.h),
            
            // 阅读成就
            _buildAchievements(context, stats),
            
            SizedBox(height: 24.h),
            
            // 操作按钮
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(BuildContext context, stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '总体统计',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _StatCard('总书籍', '${stats.totalBooks}', '本', Icons.library_books, Colors.blue),
              SizedBox(width: 12.w),
              _StatCard('已完成', '${stats.finishedBooks}', '本', Icons.done_all, Colors.green),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _StatCard('阅读时长', stats.formattedTotalTime, '', Icons.access_time, Colors.orange),
              SizedBox(width: 12.w),
              _StatCard('平均会话', stats.formattedAverageSessionTime, '', Icons.schedule, Colors.purple),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _StatCard('完成率', stats.formattedCompletionRate, '', Icons.trending_up, Colors.teal),
              SizedBox(width: 12.w),
              _StatCard('阅读天数', '${stats.totalReadingDays}', '天', Icons.calendar_today, Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingHabits(BuildContext context, stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '阅读习惯',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          
          // 连续阅读天数
          _buildHabitItem(
            '连续阅读',
            '${stats.currentReadingStreak}天',
            stats.currentReadingStreak >= 7 ? Colors.green : Colors.orange,
            Icons.local_fire_department,
            stats.currentReadingStreak >= 7 ? '坚持得很好！' : '继续努力',
          ),
          
          const CustomDivider(),
          
          // 最长连续记�?
          _buildHabitItem(
            '最长连续',
            '${stats.longestReadingStreak}天',
            Colors.blue,
            Icons.emoji_events,
            '个人最佳记录',
          ),
          
          const CustomDivider(),
          
          // 阅读速度
          _buildHabitItem(
            '阅读速度',
            '${stats.averageReadingSpeed.toInt()}页/小时',
            Colors.purple,
            Icons.speed,
            stats.averageReadingSpeed > 20 ? '速度很快' : '慢慢品味',
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats(BuildContext context, stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本月统计',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _StatCard('本月阅读', '${stats.thisMonthReadingTime}', '分钟', Icons.today, Colors.green),
              SizedBox(width: 12.w),
              _StatCard('本月完成', '${stats.thisMonthFinishedBooks}', '本', Icons.book, Colors.blue),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _StatCard('今日阅读', stats.formattedTodayTime, '', Icons.wb_sunny, Colors.orange),
              SizedBox(width: 12.w),
              _StatCard('本月目标', '完成${stats.thisMonthFinishedBooks}/5本', '', Icons.flag, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, stats) {
    final achievements = <Map<String, dynamic>>[
      {
        'title': '初来乍到',
        'desc': '添加第一本书',
        'achieved': stats.totalBooks > 0,
        'icon': Icons.star,
      },
      {
        'title': '博览群书',
        'desc': '阅读超过10本书',
        'achieved': stats.finishedBooks >= 10,
        'icon': Icons.local_library,
      },
      {
        'title': '坚持不懈',
        'desc': '连续阅读7天',
        'achieved': stats.currentReadingStreak >= 7,
        'icon': Icons.local_fire_department,
      },
      {
        'title': '时间管理者',
        'desc': '累计阅读超过100小时',
        'achieved': stats.totalReadingTimeMinutes >= 6000,
        'icon': Icons.access_time,
      },
      {
        'title': '完美主义者',
        'desc': '完成率达到80%以上',
        'achieved': stats.completionRate >= 0.8,
        'icon': Icons.star_rate,
      },
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '阅读成就',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: achievements.map((achievement) {
              return _AchievementBadge(
                title: achievement['title'],
                description: achievement['desc'],
                achieved: achievement['achieved'],
                icon: achievement['icon'],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        CustomButton(
          text: '刷新统计',
          icon: Icons.refresh,
          onPressed: () {
                          // ref.read(readingStatisticsProvider.notifier).refreshStatistics();
              // TODO: 实现统计数据刷新
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('统计数据已刷新')),
            );
          },
          fullWidth: true,
        ),
        SizedBox(height: 12.h),
        CustomButton(
          text: '导出统计',
          icon: Icons.file_download,
          type: ButtonType.outline,
          onPressed: () {
            // TODO: 实现统计导出
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('导出功能开发中')),
            );
          },
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildHabitItem(String title, String value, Color color, IconData icon, String desc) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(fontSize: 14.sp),
                ),
                Text(
                  desc,
                  style: GoogleFonts.notoSans(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.unit, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24.sp, color: color),
            SizedBox(height: 4.h),
            Text(
              value,
              style: GoogleFonts.notoSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: GoogleFonts.notoSans(
                  fontSize: 10.sp,
                  color: color,
                ),
              ),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String title;
  final String description;
  final bool achieved;
  final IconData icon;

  const _AchievementBadge({
    required this.title,
    required this.description,
    required this.achieved,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48.w) / 2,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: achieved ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: achieved ? Colors.amber : Colors.grey,
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: achieved ? Colors.amber : Colors.grey,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: GoogleFonts.notoSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: achieved ? Colors.amber[700] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            style: GoogleFonts.notoSans(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
