import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_widgets.dart';

import '../widgets/reading_settings_section.dart';
import '../widgets/app_settings_section.dart';
import '../widgets/statistics_section.dart';
import '../widgets/about_section.dart';


class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: const CustomAppBar(
        title: '设置',
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 阅读设置
            const ReadingSettingsSection(),
            
            SizedBox(height: 24.h),
            
            // 应用设置
            const AppSettingsSection(),
            
            SizedBox(height: 24.h),
            
            // 统计信息
            const StatisticsSection(),
            
            SizedBox(height: 24.h),
            
            // 关于应用
            const AboutSection(),
            
            SizedBox(height: 24.h),
            
            // 其他操作
            _buildOtherActions(context, ref),
            
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherActions(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: '其他',
      children: [
        _SettingsItem(
          icon: Icons.feedback_outlined,
          title: '意见反馈',
          subtitle: '帮助我们改进应用',
          onTap: () => _showFeedbackDialog(context),
        ),
        
        _SettingsItem(
          icon: Icons.star_outline,
          title: '评分应用',
          subtitle: '在应用商店给我们评分',
          onTap: () => _rateApp(context),
        ),
        
        _SettingsItem(
          icon: Icons.share_outlined,
          title: '分享应用',
          subtitle: '推荐给朋友',
          onTap: () => _shareApp(context),
        ),
        
        _SettingsItem(
          icon: Icons.refresh,
          title: '重置设置',
          subtitle: '恢复到默认设置',
          onTap: () => _showResetDialog(context, ref),
          isDestructive: true,
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FeedbackDialog(),
    );
  }

  void _rateApp(BuildContext context) {
    // TODO: 实现应用评分功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('即将跳转到应用商店')),
    );
  }

  void _shareApp(BuildContext context) {
    // TODO: 实现应用分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '重置设置',
          style: GoogleFonts.notoSans(fontSize: 18.sp),
        ),
        content: Text(
          '确定要将所有设置恢复到默认状态吗？此操作无法撤销。',
          style: GoogleFonts.notoSans(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现重置功能
              // ref.read(appSettingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已重置')),
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

/// 设置�?
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
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
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: theme.textTheme.bodySmall?.color,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 4.h,
      ),
    );
  }
}

/// 意见反馈对话�?
class _FeedbackDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  String _selectedCategory = '功能建议';

  final List<String> _categories = [
    '功能建议',
    '界面优化',
    '性能问题',
    'Bug反馈',
    '其他',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '意见反馈',
        style: GoogleFonts.notoSans(fontSize: 18.sp),
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 反馈类型
              Text(
                '反馈类型',
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.notoSans(fontSize: 14.sp),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              SizedBox(height: 16.h),
              
              // 反馈内容
              Text(
                '反馈内容',
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              CustomTextField(
                controller: _feedbackController,
                hintText: '请详细描述您的意见或建议...',
                maxLines: 4, // 减少行数
              ),
              
              SizedBox(height: 16.h),
              
              // 联系方式
              Text(
                '联系方式（可选）',
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              CustomTextField(
                controller: _contactController,
                hintText: '邮箱或微信号',
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _feedbackController.text.trim().isNotEmpty
              ? () => _submitFeedback(context)
              : null,
          child: const Text('提交'),
        ),
      ],
    );
  }

  void _submitFeedback(BuildContext context) {
    // TODO: 实现反馈提交功能
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('反馈已提交，感谢您的意见')),
    );
  }
}

/// 导出功能对话�?

