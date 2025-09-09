import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xreader/features/bookshelf/providers/bookshelf_provider.dart';
import 'package:xreader/features/bookshelf/providers/bookshelf_state.dart';
import 'package:xreader/data/models/book.dart';

void main() {
  group('BookshelfNotifier Tests', () {
    late ProviderContainer container;
    late BookshelfNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(bookshelfProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该正确', () {
      final state = container.read(bookshelfProvider);
      
      expect(state.books, isEmpty);
      expect(state.filteredBooks, isEmpty);
      expect(state.isLoading, false);
      expect(state.currentFilter, BookshelfFilter.all);
      expect(state.sortBy, BookshelfSortBy.addedDate);
      expect(state.viewMode, BookshelfViewMode.grid);
      expect(state.isSelectionMode, false);
    });

    test('设置筛选条件应该更新状态', () {
      notifier.setFilter(BookshelfFilter.reading);
      
      final state = container.read(bookshelfProvider);
      expect(state.currentFilter, BookshelfFilter.reading);
    });

    test('设置排序方式应该更新状态', () {
      notifier.setSortBy(BookshelfSortBy.title);
      
      final state = container.read(bookshelfProvider);
      expect(state.sortBy, BookshelfSortBy.title);
    });

    test('切换视图模式应该更新状态', () {
      notifier.setViewMode(BookshelfViewMode.list);
      
      final state = container.read(bookshelfProvider);
      expect(state.viewMode, BookshelfViewMode.list);
    });

    test('进入选择模式应该更新状态', () {
      notifier.enterSelectionMode();
      
      final state = container.read(bookshelfProvider);
      expect(state.isSelectionMode, true);
      expect(state.selectedBookIds, isEmpty);
    });

    test('退出选择模式应该重置状态', () {
      notifier.enterSelectionMode();
      notifier.exitSelectionMode();
      
      final state = container.read(bookshelfProvider);
      expect(state.isSelectionMode, false);
      expect(state.selectedBookIds, isEmpty);
    });

    test('搜索书籍应该更新搜索查询', () {
      notifier.searchBooks('测试');
      
      final state = container.read(bookshelfProvider);
      expect(state.searchQuery, '测试');
    });

    test('清除错误应该重置错误状态', () {
      // 手动设置错误状态进行测试
      notifier.state = notifier.state.copyWith(error: '测试错误');
      expect(notifier.state.hasError, true);
      
      notifier.clearError();
      expect(notifier.state.hasError, false);
    });
  });

  group('BookshelfState Tests', () {
    test('hasBooks getter应该正确返回', () {
      const stateEmpty = BookshelfState();
      expect(stateEmpty.hasBooks, false);

      final stateWithBooks = BookshelfState(
        books: [
          Book()..title = '测试书籍'..filePath = '/test/path'
        ],
      );
      expect(stateWithBooks.hasBooks, true);
    });

    test('displayBooks getter应该根据筛选条件返回正确的书籍', () {
      final books = [
        Book()..title = '书籍1'..filePath = '/path1',
        Book()..title = '书籍2'..filePath = '/path2',
      ];
      
      final state = BookshelfState(
        books: books,
        filteredBooks: [books[0]],
        currentFilter: BookshelfFilter.reading,
      );
      
      expect(state.displayBooks.length, 1);
      expect(state.displayBooks[0].title, '书籍1');
    });

    test('selectedBooksCount应该返回正确的数量', () {
      const state = BookshelfState(
        selectedBookIds: [1, 2, 3],
      );
      
      expect(state.selectedBooksCount, 3);
    });
  });

  group('BookshelfFilter Tests', () {
    test('所有筛选器应该有正确的标签', () {
      expect(BookshelfFilter.all.label, '全部');
      expect(BookshelfFilter.reading.label, '在读');
      expect(BookshelfFilter.finished.label, '已读');
      expect(BookshelfFilter.unread.label, '未读');
      expect(BookshelfFilter.favorites.label, '收藏');
    });
  });

  group('BookshelfSortBy Tests', () {
    test('所有排序选项应该有正确的标签', () {
      expect(BookshelfSortBy.addedDate.label, '添加时间');
      expect(BookshelfSortBy.lastRead.label, '最近阅读');
      expect(BookshelfSortBy.title.label, '书名');
      expect(BookshelfSortBy.author.label, '作者');
      expect(BookshelfSortBy.progress.label, '阅读进度');
      expect(BookshelfSortBy.fileSize.label, '文件大小');
    });
  });

  group('BookshelfViewMode Tests', () {
    test('视图模式应该有正确的标签', () {
      expect(BookshelfViewMode.grid.label, '网格');
      expect(BookshelfViewMode.list.label, '列表');
    });
  });
}