import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/temp_settings_provider.dart';


class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider);

    return _SettingsSection(
      title: '关于',
      children: [
        _SettingsItem(
          icon: Icons.info_outline,
          title: '版本信息',
          subtitle: 'v${appInfo.version} (${appInfo.buildNumber})',
          onTap: () => _showVersionDialog(context, appInfo),
        ),
        
        _SettingsItem(
          icon: Icons.description_outlined,
          title: '用户协议',
          subtitle: '查看用户服务协议',
          onTap: () => _showTermsDialog(context),
        ),
        
        _SettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: '隐私政策',
          subtitle: '了解我们如何保护您的隐私',
          onTap: () => _showPrivacyDialog(context),
        ),
        
        _SettingsItem(
          icon: Icons.group_outlined,
          title: '开发团队',
          subtitle: appInfo.developer,
          onTap: () => _showTeamDialog(context, appInfo),
        ),
        
        _SettingsItem(
          icon: Icons.update_outlined,
          title: '检查更新',
          subtitle: '查看是否有新版本',
          onTap: () => _checkForUpdates(context),
        ),
      ],
    );
  }

  void _showVersionDialog(BuildContext context, appInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.book, size: 32.sp, color: Theme.of(context).primaryColor),
            SizedBox(width: 12.w),
            const Text('XReader'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本: ${appInfo.version}',
              style: GoogleFonts.notoSans(fontSize: 16.sp),
            ),
            Text(
              '构建号: ${appInfo.buildNumber}',
              style: GoogleFonts.notoSans(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              appInfo.description,
              style: GoogleFonts.notoSans(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              '主要功能:',
              style: GoogleFonts.notoSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            ...appInfo.features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16.sp, color: Colors.green),
                  SizedBox(width: 8.w),
                  Text(
                    feature,
                    style: GoogleFonts.notoSans(fontSize: 12.sp),
                  ),
                ],
              ),
            )).toList(),
          ],
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

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户服务协议'),
        content: SingleChildScrollView(
          child: Text(
            '''感谢您选择使用XReader�?

本协议是您与XReader之间关于使用本应用的法律协议�?

1. 服务说明
XReader是一款电子书阅读应用，为用户提供本地电子书阅读功能�?

2. 使用规则
- 请合法使用本应用
- 不得用于任何违法用�?
- 尊重知识产权

3. 隐私保护
我们重视您的隐私，详情请查看隐私政策�?

4. 免责声明
本应用按"现状"提供，不提供任何明示或暗示的保证�?

5. 协议变更
我们有权随时修改本协议，修改后的协议将在应用内公布�?

如有疑问，请联系我们：support@xreader.com''',
            style: GoogleFonts.notoSans(fontSize: 12.sp),
          ),
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

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: SingleChildScrollView(
          child: Text(
            '''XReader隐私政策

更新日期：2024年1月1日

我们重视您的隐私权，本政策说明了我们如何收集、使用和保护您的信息�?

1. 信息收集
- 阅读记录：为提供阅读进度同步功能
- 应用使用数据：用于改进应用性能
- 设备信息：用于适配不同设备

2. 信息使用
- 提供核心功能服务
- 改进用户体验
- 技术支�?

3. 信息保护
- 数据本地存储
- 不会泄露给第三方
- 采用业界标准的安全措�?

4. 用户权利
- 可随时删除个人数�?
- 可关闭数据收集功�?
- 可联系我们了解数据使用情�?

5. 联系我们
如有隐私相关问题，请联系：privacy@xreader.com''',
            style: GoogleFonts.notoSans(fontSize: 12.sp),
          ),
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

  void _showTeamDialog(BuildContext context, appInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开发团队'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40.r,
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                Icons.group,
                size: 40.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              appInfo.developer,
              style: GoogleFonts.notoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '致力于打造最优秀的阅读体验',
              style: GoogleFonts.notoSans(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ContactButton(
                  icon: Icons.email,
                  label: '邮箱',
                  onTap: () {
                    // TODO: 打开邮箱
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('邮箱: ${appInfo.email}')),
                    );
                  },
                ),
                _ContactButton(
                  icon: Icons.web,
                  label: '官网',
                  onTap: () {
                    // TODO: 打开网站
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('官网: ${appInfo.website}')),
                    );
                  },
                ),
              ],
            ),
          ],
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

  void _checkForUpdates(BuildContext context) {
    // TODO: 实现更新检查
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('检查更新'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            const Text('正在检查更新..'),
          ],
        ),
      ),
    );

    // 模拟检查更新
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('检查完成'),
          content: const Text('当前已是最新版本'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    });
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 24.sp,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.notoSans(fontSize: 12.sp),
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
