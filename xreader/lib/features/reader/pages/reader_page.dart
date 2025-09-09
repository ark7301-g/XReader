import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/reader_provider.dart';
import '../providers/reader_state.dart';
import '../widgets/reader_toolbar.dart';
import '../widgets/reader_settings_panel.dart';
import '../widgets/chapter_list_dialog.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final int bookId;

  const ReaderPage({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _toolbarAnimationController;
  late Animation<Offset> _toolbarSlideAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _toolbarSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: Curves.easeInOut,
    ));

    // 设置全屏模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _toolbarAnimationController.dispose();
    
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 结束阅读会话
    ref.read(readerProvider(widget.bookId).notifier).endReadingSession();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider(widget.bookId));
    final readerSettings = ref.watch(readerSettingsProvider);

    // 监听工具栏状态变�?
    ref.listen<ReaderState>(readerProvider(widget.bookId), (previous, next) {
      if (previous?.showToolbar != next.showToolbar) {
        if (next.showToolbar) {
          _toolbarAnimationController.forward();
        } else {
          _toolbarAnimationController.reverse();
        }
      }
    });

    if (readerState.isLoading) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(readerState),
        body: const LoadingIndicator(
          message: '加载书籍中..',
          showMessage: true,
        ),
      );
    }

    if (readerState.hasError) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(readerState),
        body: ErrorState(
          title: '加载失败',
          subtitle: readerState.error,
          onRetry: () => ref.read(readerProvider(widget.bookId).notifier).loadBook(),
        ),
      );
    }

    if (!readerState.hasBook || readerState.pageContents.isEmpty) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(readerState),
        body: const EmptyState(
          icon: Icons.book_outlined,
          title: '无法加载书籍内容',
          subtitle: '请检查文件是否存在且格式正确',
        ),
      );
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(readerState),
      body: Stack(
        children: [
          // 主要阅读区域
          _buildReadingArea(readerState, readerSettings),
          
          // 顶部工具�?
          if (readerState.showToolbar)
            SlideTransition(
              position: _toolbarSlideAnimation,
              child: ReaderTopBar(
                book: readerState.book!,
                onBack: () => Navigator.of(context).pop(),
                onShowSettings: () => _showSettingsPanel(context),
                onShowChapterList: () => _showChapterList(context),
              ),
            ),
          
          // 底部工具�?
          if (readerState.showToolbar)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _toolbarAnimationController,
                curve: Curves.easeInOut,
              )),
              child: ReaderBottomBar(
                readerState: readerState,
                onProgressChanged: (progress) {
                  ref.read(readerProvider(widget.bookId).notifier)
                      .goToProgress(progress);
                },
                onPreviousPage: () {
                  ref.read(readerProvider(widget.bookId).notifier).previousPage();
                  if (_pageController.hasClients && readerState.currentPage > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onNextPage: () {
                  ref.read(readerProvider(widget.bookId).notifier).nextPage();
                  if (_pageController.hasClients && readerState.canGoToNextPage) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onAddBookmark: () => _addBookmark(context),
                onShowMenu: () => _showReaderMenu(context),
              ),
            ),
          
          // 页码指示器
          if (readerSettings.showPageNumber && !readerState.showToolbar)
            _buildPageIndicator(readerState),
          
          // 章节标题
          if (readerSettings.showChapterTitle && 
              !readerState.showToolbar && 
              readerState.currentChapter != null)
            _buildChapterTitle(readerState),
        ],
      ),
    );
  }

  Widget _buildReadingArea(ReaderState readerState, ReaderSettings readerSettings) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent event) {
          // 处理鼠标点击事件（桌面平台）
          if (event.buttons == kPrimaryMouseButton) {
            ref.read(readerProvider(widget.bookId).notifier).toggleToolbar();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // 处理触摸事件（移动平台）
            ref.read(readerProvider(widget.bookId).notifier).toggleToolbar();
          },
          onPanStart: (details) {
            _isDragging = true;
          },
          onPanEnd: (details) {
            if (!_isDragging) return;
            _isDragging = false;

            final velocity = details.velocity.pixelsPerSecond.dx;
            
            if (velocity > 500) {
              // 向右滑动 - 上一页
              ref.read(readerProvider(widget.bookId).notifier).previousPage();
              if (_pageController.hasClients && readerState.currentPage > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } else if (velocity < -500) {
              // 向左滑动 - 下一页
              ref.read(readerProvider(widget.bookId).notifier).nextPage();
              if (_pageController.hasClients && readerState.canGoToNextPage) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          },
          child: readerSettings.mode == ReaderMode.pagination
              ? _buildPaginationMode(readerState, readerSettings)
              : _buildScrollMode(readerState, readerSettings),
        ),
      ),
    );
  }

  Widget _buildPaginationMode(ReaderState readerState, ReaderSettings readerSettings) {
    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        // 处理鼠标滚轮事件（桌面平台翻页）
        if (event is PointerScrollEvent) {
          if (event.scrollDelta.dy > 0) {
            // 向下滚动 - 下一页
            if (readerState.canGoToNextPage) {
              ref.read(readerProvider(widget.bookId).notifier).nextPage();
              if (_pageController.hasClients) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          } else if (event.scrollDelta.dy < 0) {
            // 向上滚动 - 上一页
            if (readerState.currentPage > 0) {
              ref.read(readerProvider(widget.bookId).notifier).previousPage();
              if (_pageController.hasClients) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          }
        }
      },
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          ref.read(readerProvider(widget.bookId).notifier).goToPage(page);
        },
        itemCount: readerState.totalPages,
        itemBuilder: (context, index) {
          return _buildPageContent(
            readerState.pageContents[index],
            readerState,
            readerSettings,
          );
        },
      ),
    );
  }

  Widget _buildScrollMode(ReaderState readerState, ReaderSettings readerSettings) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: readerSettings.marginHorizontal.w,
        vertical: readerSettings.marginVertical.h,
      ),
      child: Column(
        children: readerState.pageContents.map((content) {
          return _buildPageContent(content, readerState, readerSettings);
        }).toList(),
      ),
    );
  }

  Widget _buildPageContent(
    String content,
    ReaderState readerState,
    ReaderSettings readerSettings,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: readerSettings.marginHorizontal.w,
        vertical: readerSettings.marginVertical.h,
      ),
      child: SelectableText(
        content,
        style: _getTextStyle(readerState, readerSettings),
        textAlign: TextAlign.justify,
        scrollPhysics: const NeverScrollableScrollPhysics(),
      ),
    );
  }

  TextStyle _getTextStyle(ReaderState readerState, ReaderSettings readerSettings) {
    String fontFamily;
    switch (readerSettings.fontFamily) {
      case 'serif':
        fontFamily = 'serif';
        break;
      case 'sans-serif':
        fontFamily = 'sans-serif';
        break;
      case 'monospace':
        fontFamily = 'monospace';
        break;
      default:
        fontFamily = 'serif';
    }

    final baseStyle = GoogleFonts.sourceSerif4(
      fontSize: readerSettings.textSize.sp,
      height: readerSettings.lineHeight,
      color: _getTextColor(readerState),
      fontWeight: FontWeight.w400,
    );

    // 如果需要使用不同字�?
    if (fontFamily != 'serif') {
      switch (fontFamily) {
        case 'sans-serif':
          return GoogleFonts.notoSans(
            fontSize: readerSettings.textSize.sp,
            height: readerSettings.lineHeight,
            color: _getTextColor(readerState),
            fontWeight: FontWeight.w400,
          );
        case 'monospace':
          return GoogleFonts.robotoMono(
            fontSize: readerSettings.textSize.sp,
            height: readerSettings.lineHeight,
            color: _getTextColor(readerState),
            fontWeight: FontWeight.w400,
          );
      }
    }

    return baseStyle;
  }

  Color _getBackgroundColor(ReaderState readerState) {
    if (readerState.isNightMode) {
      return const Color(0xFF1A1A1A);
    }
    
    switch (readerState.readerTheme) {
      case ReaderTheme.paper:
        return const Color(0xFFFFFEF7);
      case ReaderTheme.night:
        return const Color(0xFF1A1A1A);
      case ReaderTheme.sepia:
        return const Color(0xFFF4F1EA);
      case ReaderTheme.green:
        return const Color(0xFFE8F5E8);
      case ReaderTheme.blue:
        return const Color(0xFFE8F4FD);
    }
  }

  Color _getTextColor(ReaderState readerState) {
    if (readerState.isNightMode) {
      return const Color(0xFFCCCCCC);
    }
    
    switch (readerState.readerTheme) {
      case ReaderTheme.paper:
        return const Color(0xFF2B2B2B);
      case ReaderTheme.night:
        return const Color(0xFFCCCCCC);
      case ReaderTheme.sepia:
        return const Color(0xFF5B4636);
      case ReaderTheme.green:
        return const Color(0xFF2B2B2B);
      case ReaderTheme.blue:
        return const Color(0xFF2B2B2B);
    }
  }

  Widget _buildPageIndicator(ReaderState readerState) {
    return Positioned(
      bottom: 20.h,
      right: 20.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          readerState.pageInfo,
          style: GoogleFonts.notoSans(
            fontSize: 12.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTitle(ReaderState readerState) {
    return Positioned(
      top: 40.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          readerState.currentChapter!,
          style: GoogleFonts.notoSans(
            fontSize: 12.sp,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showSettingsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReaderSettingsPanel(bookId: widget.bookId),
    );
  }

  void _showChapterList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ChapterListDialog(bookId: widget.bookId),
    );
  }

  void _addBookmark(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(bookId: widget.bookId),
    );
  }

  void _showReaderMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ReaderMenuSheet(bookId: widget.bookId),
    );
  }
}

/// 添加书签对话框
class _BookmarkDialog extends ConsumerStatefulWidget {
  final int bookId;

  const _BookmarkDialog({required this.bookId});

  @override
  ConsumerState<_BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends ConsumerState<_BookmarkDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(
        '添加书签',
        style: GoogleFonts.notoSans(fontSize: 18.sp),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '为当前页面添加书签',
            style: GoogleFonts.notoSans(fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: _noteController,
            hintText: '添加备注（可选）',
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            ref.read(readerProvider(widget.bookId).notifier)
                .addBookmark(note: _noteController.text.trim().isEmpty 
                    ? null : _noteController.text.trim());
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('书签添加成功')),
            );
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

/// 阅读器菜�?
class _ReaderMenuSheet extends ConsumerWidget {
  final int bookId;

  const _ReaderMenuSheet({required this.bookId});

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
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(
              '搜索文本',
              style: GoogleFonts.notoSans(fontSize: 16.sp),
            ),
            onTap: () {
              Navigator.pop(context);
              _showSearchDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(
              '调节亮度',
              style: GoogleFonts.notoSans(fontSize: 16.sp),
            ),
            onTap: () {
              Navigator.pop(context);
              _showBrightnessDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.fullscreen),
            title: Text(
              '全屏模式',
              style: GoogleFonts.notoSans(fontSize: 16.sp),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(readerProvider(bookId).notifier).toggleFullScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              '书籍信息',
              style: GoogleFonts.notoSans(fontSize: 16.sp),
            ),
            onTap: () {
              Navigator.pop(context);
              _showBookInfo(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    // TODO: 实现搜索对话框
  }

  void _showBrightnessDialog(BuildContext context, WidgetRef ref) {
    // TODO: 实现亮度调节对话框
  }

  void _showBookInfo(BuildContext context, WidgetRef ref) {
    // TODO: 实现书籍信息对话框
  }
}
