import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/book.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/bookshelf_provider.dart';
import '../../reader/pages/reader_page.dart';

class BookCard extends ConsumerWidget {
  final Book book;
  final BookCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showProgress;
  final bool showStats;

  const BookCard({
    super.key,
    required this.book,
    this.mode = BookCardMode.grid,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showProgress = true,
    this.showStats = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return mode == BookCardMode.grid
        ? _buildGridCard(context, ref)
        : _buildListCard(context, ref);
  }

  Widget _buildGridCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap ?? () => _openBook(context, ref),
      onLongPress: onLongPress ?? () => _showBookMenu(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
          border: isSelected 
              ? Border.all(color: theme.primaryColor, width: 2.w)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            color: theme.cardColor,
            child: Column(
              children: [
                // 书籍封面区域
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // 封面图片
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12.r),
                          ),
                        ),
                        child: _buildCoverImage(),
                      ),
                      
                      // 收藏图标
                      if (book.isFavorite)
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.favorite,
                              size: 12.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      
                      // 文件类型标识
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getFileTypeColor().withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            book.fileType.toUpperCase(),
                            style: GoogleFonts.notoSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      // 选择模式覆盖�?
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12.r),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_circle,
                              size: 32.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // 书籍信息区域
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 书名
                        Expanded(
                          child: Text(
                            book.title,
                            style: GoogleFonts.notoSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        SizedBox(height: 2.h),
                        
                        // 作�?
                        if (book.author != null && book.author!.isNotEmpty)
                          Text(
                            book.author!,
                            style: GoogleFonts.notoSans(
                              fontSize: 11.sp,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        // 阅读进度
                        if (showProgress && book.hasStartedReading) ...[
                          SizedBox(height: 4.h),
                          _buildProgressIndicator(theme),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap ?? () => _openBook(context, ref),
      onLongPress: onLongPress ?? () => _showBookMenu(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected 
              ? Border.all(color: theme.primaryColor, width: 2.w)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 封面缩略�?
            Container(
              width: 50.w,
              height: 70.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: theme.dividerColor.withOpacity(0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: _buildCoverImage(),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // 书籍信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 书名和收藏图�?
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          book.title,
                          style: GoogleFonts.notoSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (book.isFavorite) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.favorite,
                          size: 16.sp,
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // 作�?
                  if (book.author != null && book.author!.isNotEmpty)
                    Text(
                      book.author!,
                      style: GoogleFonts.notoSans(
                        fontSize: 14.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  SizedBox(height: 6.h),
                  
                  // 进度和统计信�?
                  Row(
                    children: [
                      // 文件类型
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getFileTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          book.fileType.toUpperCase(),
                          style: GoogleFonts.notoSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _getFileTypeColor(),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 8.w),
                      
                      // 阅读进度
                      if (book.hasStartedReading)
                        Text(
                          book.formattedProgress,
                          style: GoogleFonts.notoSans(
                            fontSize: 12.sp,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // 最后阅读时�?
                      if (book.lastReadDate != null)
                        Text(
                          _formatLastReadDate(book.lastReadDate!),
                          style: GoogleFonts.notoSans(
                            fontSize: 11.sp,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                  
                  // 阅读进度�?
                  if (showProgress && book.hasStartedReading) ...[
                    SizedBox(height: 6.h),
                    _buildProgressIndicator(theme),
                  ],
                ],
              ),
            ),
            
            // 选择图标
            if (isSelected) ...[
              SizedBox(width: 12.w),
              Icon(
                Icons.check_circle,
                size: 24.sp,
                color: theme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (book.coverPath != null && File(book.coverPath!).existsSync()) {
      return Image.file(
        File(book.coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
      );
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      color: _getFileTypeColor().withOpacity(0.1),
      child: Center(
        child: Icon(
          _getFileTypeIcon(),
          size: mode == BookCardMode.grid ? 32.sp : 24.sp,
          color: _getFileTypeColor(),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: book.readingProgress,
          backgroundColor: theme.dividerColor.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          minHeight: 2.h,
        ),
        if (mode == BookCardMode.list) ...[
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '第${book.currentPage}页',
                style: GoogleFonts.notoSans(
                  fontSize: 10.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              Text(
                '共${book.totalPages}页',
                style: GoogleFonts.notoSans(
                  fontSize: 10.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getFileTypeColor() {
    switch (book.fileType.toLowerCase()) {
      case 'epub':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon() {
    switch (book.fileType.toLowerCase()) {
      case 'epub':
        return Icons.menu_book;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.description;
    }
  }

  String _formatLastReadDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _openBook(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderPage(bookId: book.id),
      ),
    );
  }

  void _showBookMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BookActionSheet(book: book),
    );
  }
}

enum BookCardMode { grid, list }

/// 书籍操作菜单
class BookActionSheet extends ConsumerWidget {
  final Book book;

  const BookActionSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 书籍信息头部
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                  child: book.coverPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: Image.file(
                            File(book.coverPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.book, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.notoSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (book.author != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          book.author!,
                          style: GoogleFonts.notoSans(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),
          const CustomDivider(),
          
          // 操作按钮
          _buildActionItem(
            context,
            icon: Icons.play_arrow,
            title: '继续阅读',
            onTap: () {
              Navigator.pop(context);
              // TODO: 导航到阅读器
            },
          ),
          
          _buildActionItem(
            context,
            icon: book.isFavorite ? Icons.favorite : Icons.favorite_border,
            title: book.isFavorite ? '取消收藏' : '添加收藏',
            onTap: () {
              Navigator.pop(context);
              ref.read(bookshelfProvider.notifier).toggleBookFavorite(book.id);
            },
          ),
          
          _buildActionItem(
            context,
            icon: Icons.info_outline,
            title: '书籍详情',
            onTap: () {
              Navigator.pop(context);
              // TODO: 显示书籍详情
            },
          ),
          
          _buildActionItem(
            context,
            icon: Icons.delete_outline,
            title: '删除书籍',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, ref);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        size: 24.sp,
        color: isDestructive ? theme.colorScheme.error : theme.iconTheme.color,
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 16.sp,
          color: isDestructive ? theme.colorScheme.error : theme.textTheme.bodyMedium?.color,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '删除书籍',
          style: GoogleFonts.notoSans(fontSize: 18.sp),
        ),
        content: Text(
          '确定要删除《${book.title}》吗？\n\n此操作将删除书籍记录，但不会删除原文件。',
          style: GoogleFonts.notoSans(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(bookshelfProvider.notifier).deleteBook(book.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
