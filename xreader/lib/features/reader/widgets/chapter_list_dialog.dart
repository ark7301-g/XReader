import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/reader_provider.dart';
import '../providers/reader_state.dart';

class ChapterListDialog extends ConsumerWidget {
  final int bookId;

  const ChapterListDialog({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerState = ref.watch(readerProvider(bookId));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // 标题�?
            Row(
              children: [
                Expanded(
                  child: Text(
                    '章节目录',
                    style: GoogleFonts.notoSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    size: 24.sp,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 章节列表
            Expanded(
              child: _buildChapterList(context, ref, readerState, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList(
    BuildContext context,
    WidgetRef ref,
    ReaderState readerState,
    ThemeData theme,
  ) {
    if (readerState.chapters.isEmpty) {
      return const EmptyState(
        icon: Icons.list_outlined,
        title: '暂无章节',
        subtitle: '此书籍没有章节信息',
      );
    }

    return ListView.builder(
      itemCount: readerState.chapters.length,
      itemBuilder: (context, index) {
        final chapter = readerState.chapters[index];
        final isCurrentChapter = index == readerState.currentChapterIndex;
        final isRead = chapter.endPage < readerState.currentPage;
        final isReading = chapter.containsPage(readerState.currentPage);

        return _ChapterItem(
          chapter: chapter,
          isCurrentChapter: isCurrentChapter,
          isRead: isRead,
          isReading: isReading,
          onTap: () {
            ref.read(readerProvider(bookId).notifier).goToChapter(index);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _ChapterItem extends StatelessWidget {
  final Chapter chapter;
  final bool isCurrentChapter;
  final bool isRead;
  final bool isReading;
  final VoidCallback onTap;

  const _ChapterItem({
    required this.chapter,
    required this.isCurrentChapter,
    required this.isRead,
    required this.isReading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              color: isCurrentChapter
                  ? theme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
              border: isCurrentChapter
                  ? Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                      width: 1.w,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // 章节层级缩进
                SizedBox(width: (chapter.level - 1) * 16.w),

                // 章节状态图�?
                Container(
                  width: 20.w,
                  height: 20.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: _buildStatusIcon(theme),
                ),

                // 章节信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 章节标题
                      Text(
                        chapter.title,
                        style: GoogleFonts.notoSans(
                          fontSize: 14.sp,
                          fontWeight: isCurrentChapter
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isCurrentChapter
                              ? theme.primaryColor
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4.h),

                      // 章节页码信息
                      Row(
                        children: [
                          Text(
                            '第${chapter.startPage + 1}-${chapter.endPage + 1}页',
                            style: GoogleFonts.notoSans(
                              fontSize: 12.sp,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '共${chapter.pageCount}页',
                            style: GoogleFonts.notoSans(
                              fontSize: 12.sp,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 阅读进度指示
                if (isReading)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '阅读中',
                      style: GoogleFonts.notoSans(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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

  Widget _buildStatusIcon(ThemeData theme) {
    if (isReading) {
      return Icon(
        Icons.play_circle_filled,
        size: 16.sp,
        color: theme.primaryColor,
      );
    } else if (isRead) {
      return Icon(
        Icons.check_circle,
        size: 16.sp,
        color: Colors.green,
      );
    } else {
      return Icon(
        Icons.radio_button_unchecked,
        size: 16.sp,
        color: theme.textTheme.bodySmall?.color,
      );
    }
  }
}

/// 章节搜索对话�?
class ChapterSearchDialog extends ConsumerStatefulWidget {
  final int bookId;

  const ChapterSearchDialog({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<ChapterSearchDialog> createState() => _ChapterSearchDialogState();
}

class _ChapterSearchDialogState extends ConsumerState<ChapterSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Chapter> _filteredChapters = [];

  @override
  void initState() {
    super.initState();
    final readerState = ref.read(readerProvider(widget.bookId));
    _filteredChapters = readerState.chapters;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchChapters(String query) {
    final readerState = ref.read(readerProvider(widget.bookId));
    
    if (query.isEmpty) {
      setState(() {
        _filteredChapters = readerState.chapters;
      });
      return;
    }

    setState(() {
      _filteredChapters = readerState.chapters
          .where((chapter) =>
              chapter.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // 标题和关闭按�?
            Row(
              children: [
                Expanded(
                  child: Text(
                    '搜索章节',
                    style: GoogleFonts.notoSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    size: 24.sp,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 搜索�?
            CustomTextField(
              controller: _searchController,
              hintText: '输入章节标题搜索...',
              prefixIcon: Icons.search,
              onChanged: _searchChapters,
            ),

            SizedBox(height: 16.h),

            // 搜索结果
            Expanded(
              child: _buildSearchResults(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_filteredChapters.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: '未找到章节',
        subtitle: '尝试使用其他关键词搜索',
      );
    }

    final readerState = ref.watch(readerProvider(widget.bookId));

    return ListView.builder(
      itemCount: _filteredChapters.length,
      itemBuilder: (context, index) {
        final chapter = _filteredChapters[index];
        final originalIndex = readerState.chapters.indexOf(chapter);
        final isCurrentChapter = originalIndex == readerState.currentChapterIndex;
        final isRead = chapter.endPage < readerState.currentPage;
        final isReading = chapter.containsPage(readerState.currentPage);

        return _ChapterItem(
          chapter: chapter,
          isCurrentChapter: isCurrentChapter,
          isRead: isRead,
          isReading: isReading,
          onTap: () {
            ref.read(readerProvider(widget.bookId).notifier)
                .goToChapter(originalIndex);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

/// 章节统计面板
class ChapterStatsPanel extends ConsumerWidget {
  final int bookId;

  const ChapterStatsPanel({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerState = ref.watch(readerProvider(bookId));

    if (readerState.chapters.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalChapters = readerState.chapters.length;
    final readChapters = readerState.chapters
        .where((chapter) => chapter.endPage < readerState.currentPage)
        .length;
    final currentChapter = readerState.currentChapterIndex + 1;

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '章节阅读统计',
            style: GoogleFonts.notoSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                theme,
                '当前章节',
                '$currentChapter',
                Colors.blue,
              ),
              _buildStatItem(
                theme,
                '已读章节',
                '$readChapters',
                Colors.green,
              ),
              _buildStatItem(
                theme,
                '总章节数',
                '$totalChapters',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 12.sp,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
