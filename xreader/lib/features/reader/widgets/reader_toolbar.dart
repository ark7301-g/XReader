import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/book.dart';

import '../providers/reader_provider.dart';
import '../providers/reader_state.dart';

/// 阅读器顶部工具栏
class ReaderTopBar extends ConsumerWidget {
  final Book book;
  final VoidCallback onBack;
  final VoidCallback? onShowSettings;
  final VoidCallback? onShowChapterList;

  const ReaderTopBar({
    super.key,
    required this.book,
    required this.onBack,
    this.onShowSettings,
    this.onShowChapterList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16.w,
        right: 16.w,
        bottom: 8.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackgroundColor.withOpacity(0.95),
            theme.scaffoldBackgroundColor.withOpacity(0.8),
            theme.scaffoldBackgroundColor.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20.sp,
              color: theme.iconTheme.color,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          // 书籍标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.author != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    book.author!,
                    style: GoogleFonts.notoSans(
                      fontSize: 12.sp,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // 章节列表按钮
          if (onShowChapterList != null)
            IconButton(
              onPressed: onShowChapterList,
              icon: Icon(
                Icons.list,
                size: 22.sp,
                color: theme.iconTheme.color,
              ),
            ),
          
          // 设置按钮
          if (onShowSettings != null)
            IconButton(
              onPressed: onShowSettings,
              icon: Icon(
                Icons.settings,
                size: 22.sp,
                color: theme.iconTheme.color,
              ),
            ),
        ],
      ),
    );
  }
}

/// 阅读器底部工具栏
class ReaderBottomBar extends ConsumerWidget {
  final ReaderState readerState;
  final Function(double) onProgressChanged;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback? onAddBookmark;
  final VoidCallback? onShowMenu;

  const ReaderBottomBar({
    super.key,
    required this.readerState,
    required this.onProgressChanged,
    required this.onPreviousPage,
    required this.onNextPage,
    this.onAddBookmark,
    this.onShowMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 12.h,
          bottom: MediaQuery.of(context).padding.bottom + 12.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              theme.scaffoldBackgroundColor.withOpacity(0.95),
              theme.scaffoldBackgroundColor.withOpacity(0.8),
              theme.scaffoldBackgroundColor.withOpacity(0.0),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度�?
            _buildProgressBar(context),
            
            SizedBox(height: 16.h),
            
            // 工具按钮行 - 使用Flexible布局防止溢出
            Row(
              children: [
                // 上一页
                Flexible(
                  child: _ToolButton(
                    icon: Icons.keyboard_arrow_left,
                    onTap: readerState.canGoToPreviousPage ? onPreviousPage : null,
                    isEnabled: readerState.canGoToPreviousPage,
                  ),
                ),
                
                // 书签
                if (onAddBookmark != null) ...[
                  SizedBox(width: 8.w),
                  Flexible(
                    child: _ToolButton(
                      icon: Icons.bookmark_add_outlined,
                      onTap: onAddBookmark,
                    ),
                  ),
                ],
                
                // 页面信息 - 中心位置，可扩展
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      readerState.pageInfo,
                      style: GoogleFonts.notoSans(
                        fontSize: 12.sp,
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // 菜单
                if (onShowMenu != null) ...[
                  Flexible(
                    child: _ToolButton(
                      icon: Icons.more_vert,
                      onTap: onShowMenu,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                
                // 下一页
                Flexible(
                  child: _ToolButton(
                    icon: Icons.keyboard_arrow_right,
                    onTap: readerState.canGoToNextPage ? onNextPage : null,
                    isEnabled: readerState.canGoToNextPage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // 进度信息
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${readerState.currentPage + 1}',
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            Text(
              readerState.formattedProgress,
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${readerState.totalPages}',
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8.h),
        
        // 进度滑块
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
            activeTrackColor: theme.primaryColor,
            inactiveTrackColor: theme.dividerColor.withOpacity(0.3),
            thumbColor: theme.primaryColor,
            overlayColor: theme.primaryColor.withOpacity(0.2),
          ),
          child: Slider(
            value: readerState.readingProgress.clamp(0.0, 1.0),
            onChanged: onProgressChanged,
            min: 0.0,
            max: 1.0,
          ),
        ),
      ],
    );
  }
}

/// 工具按钮
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _ToolButton({
    required this.icon,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 获取屏幕宽度，动态调整按钮大小
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth > 600 ? 48.w : 44.w;
    
    Widget button = Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(isEnabled ? 0.8 : 0.4),
        borderRadius: BorderRadius.circular((buttonSize / 2).r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Icon(
        icon,
        size: (buttonSize * 0.45).sp, // 按钮大小的45%
        color: isEnabled 
            ? theme.iconTheme.color 
            : theme.iconTheme.color?.withOpacity(0.4),
      ),
    );



    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: button,
    );
  }
}

/// 快速设置工具栏
class QuickSettingsBar extends ConsumerWidget {
  final int bookId;

  const QuickSettingsBar({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerState = ref.watch(readerProvider(bookId));
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 字体大小调节
          Flexible(
            child: _QuickSettingButton(
              icon: Icons.text_increase,
              label: '字体',
              onPressed: () {
                ref.read(readerProvider(bookId).notifier)
                    .updateTextSize(readerState.textSize + 1);
              },
            ),
          ),
          
          // 夜间模式切换
          Flexible(
            child: _QuickSettingButton(
              icon: readerState.isNightMode 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
              label: readerState.isNightMode ? '日间' : '夜间',
              onPressed: () {
                ref.read(readerProvider(bookId).notifier).toggleNightMode();
              },
            ),
          ),
          
          // 主题切换
          Flexible(
            child: _QuickSettingButton(
              icon: Icons.palette_outlined,
              label: '主题',
              onPressed: () => _showThemeSelector(context, ref),
            ),
          ),
          
          // 阅读模式切换
          Flexible(
            child: _QuickSettingButton(
              icon: readerState.readerMode == ReaderMode.pagination
                  ? Icons.view_agenda
                  : Icons.view_day,
              label: readerState.readerMode == ReaderMode.pagination ? '滚动' : '分页',
              onPressed: () {
                final newMode = readerState.readerMode == ReaderMode.pagination
                    ? ReaderMode.scroll
                    : ReaderMode.pagination;
                ref.read(readerProvider(bookId).notifier).updateReaderMode(newMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '选择主题',
          style: GoogleFonts.notoSans(fontSize: 18.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReaderTheme.values.map((theme) {
            return ListTile(
              leading: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: Color(int.parse(theme.backgroundColor.substring(1), radix: 16) + 0xFF000000),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              title: Text(
                theme.label,
                style: GoogleFonts.notoSans(fontSize: 14.sp),
              ),
              onTap: () {
                ref.read(readerProvider(bookId).notifier).updateReaderTheme(theme);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 快速设置按钮组件 - 响应式设计
class _QuickSettingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickSettingButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          constraints: BoxConstraints(
            minWidth: 40.w,
            minHeight: 40.h,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.notoSans(fontSize: 10.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
