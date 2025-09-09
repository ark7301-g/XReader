import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/bookshelf_provider.dart';
import '../providers/bookshelf_state.dart';
import '../widgets/book_card.dart';

class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _isScrolled = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // 控制回到顶部按钮显示
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
    
    // 控制标题动画
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final bookshelfState = ref.watch(bookshelfProvider);
    
    return Scaffold(
      appBar: bookshelfState.isSelectionMode
          ? _buildSelectionAppBar(theme, bookshelfState)
          : _buildAnimatedAppBar(theme, bookshelfState),
      body: Stack(
        children: [
          Column(
            children: [
              // 大标题区域（未滚动时显示）
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: _isScrolled ? 0 : 60.h,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isScrolled ? 0.0 : 1.0,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Books',
                        style: GoogleFonts.notoSans(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 主要内容区域
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(bookshelfProvider.notifier).refreshBooks(),
                  child: _buildBody(theme, bookshelfState),
                ),
              ),
            ],
          ),
          
          // 回到顶部按钮
          if (_showScrollToTop)
            Positioned(
              right: 16.w,
              bottom: 80.h,
              child: SafeArea(
                child: FloatingActionButton.small(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
            ),
        ],
      ),

    );
  }

  PreferredSizeWidget _buildAnimatedAppBar(ThemeData theme, BookshelfState state) {
    return CustomAppBar(
      title: _isScrolled ? 'Books' : '', // 滚动后才显示标题
      centerTitle: false, // 标题靠左对齐
      automaticallyImplyLeading: false, // 不显示默认的leading
      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(_isScrolled ? 0.95 : 0.0),
      elevation: _isScrolled ? 1.0 : 0.0,
      actions: [
        IconButton(
          icon: Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          onPressed: () => _showAddBookMenu(context),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(ThemeData theme, BookshelfState state) {
    return CustomAppBar(
      title: '已选择 ${state.selectedBooksCount} 本',
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(bookshelfProvider.notifier).exitSelectionMode();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () {
            ref.read(bookshelfProvider.notifier).toggleSelectAll();
          },
        ),
        if (state.hasSelectedBooks)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showBatchDeleteConfirmation(context),
          ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, BookshelfState state) {
    if (state.isLoading && !state.hasBooks) {
      return const LoadingIndicator(
        message: '加载书籍�?..',
        showMessage: true,
      );
    }

    if (state.hasError) {
      return ErrorState(
        title: '加载失败',
        subtitle: state.error,
        onRetry: () => ref.read(bookshelfProvider.notifier).loadBooks(),
      );
    }

    if (!state.hasBooks) {
      return _buildEmptyState();
    }

    // 简化为只显示网格视图，移除筛选栏
    return _buildGridView(state);
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.library_books_outlined,
      title: '书架还是空的',
      subtitle: '点击下方�?+ 按钮添加您的第一本书',
      action: CustomButton(
        text: '添加书籍',
        icon: Icons.add,
        onPressed: () => _showAddBookMenu(context),
      ),
    );
  }



  Widget _buildGridView(BookshelfState state) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: state.displayBooks.length,
      itemBuilder: (context, index) {
        final book = state.displayBooks[index];
        return BookCard(
          book: book,
          mode: BookCardMode.grid,
          isSelected: state.selectedBookIds.contains(book.id),
          onTap: state.isSelectionMode
              ? () => ref.read(bookshelfProvider.notifier)
                  .toggleBookSelection(book.id)
              : null,
          onLongPress: state.isSelectionMode
              ? null
              : () {
                  ref.read(bookshelfProvider.notifier).enterSelectionMode();
                  ref.read(bookshelfProvider.notifier).toggleBookSelection(book.id);
                },
        );
      },
    );
  }





  void _showAddBookMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text(
                '添加单个书籍',
                style: GoogleFonts.notoSans(fontSize: 16.sp),
              ),
              onTap: () async {
                Navigator.pop(context);
                final success = await ref.read(bookshelfProvider.notifier).addBook();
                if (mounted && success) {
                  // 使用更安全的方式显示消息
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('书籍添加成功')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(
                '批量添加书籍',
                style: GoogleFonts.notoSans(fontSize: 16.sp),
              ),
              onTap: () async {
                Navigator.pop(context);
                final count = await ref.read(bookshelfProvider.notifier).addMultipleBooks();
                if (mounted && count > 0) {
                  // 使用更安全的方式显示消息
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('成功添加 $count 本书籍')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }







  void _showBatchDeleteConfirmation(BuildContext context) {
    final selectedCount = ref.read(bookshelfProvider).selectedBooksCount;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '批量删除',
          style: GoogleFonts.notoSans(fontSize: 18.sp),
        ),
        content: Text(
          '确定要删除选中的 $selectedCount 本书籍吗？\n\n此操作将删除书籍记录，但不会删除原文件。',
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
              final selectedIds = ref.read(bookshelfProvider).selectedBookIds;
              ref.read(bookshelfProvider.notifier).deleteMultipleBooks(selectedIds);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }


}
