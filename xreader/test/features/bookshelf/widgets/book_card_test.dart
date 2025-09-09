import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xreader/features/bookshelf/widgets/book_card.dart';
import 'package:xreader/data/models/book.dart';

void main() {
  group('BookCard Widget Tests', () {
    late Book testBook;

    setUp(() {
      testBook = Book()
        ..id = 1
        ..title = '测试书籍'
        ..author = '测试作者'
        ..filePath = '/test/path/book.epub'
        ..fileType = 'epub'
        ..totalPages = 100
        ..currentPage = 50
        ..readingProgress = 0.5
        ..isFavorite = false;
    });

    Widget createTestWidget(Widget child) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        child: ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: child,
            ),
          ),
        ),
      );
    }

    testWidgets('BookCard 应该显示书籍基本信息', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          BookCard(book: testBook, mode: BookCardMode.grid),
        ),
      );

      // 验证书籍标题显示
      expect(find.text('测试书籍'), findsOneWidget);
      
      // 验证作者显示
      expect(find.text('测试作者'), findsOneWidget);
      
      // 验证文件类型标识
      expect(find.text('EPUB'), findsOneWidget);
    });

    testWidgets('BookCard 网格模式应该正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          BookCard(book: testBook, mode: BookCardMode.grid),
        ),
      );

      // 验证网格模式的布局结构
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('BookCard 列表模式应该正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          BookCard(book: testBook, mode: BookCardMode.list),
        ),
      );

      // 验证列表模式的布局结构
      expect(find.byType(Row), findsWidgets);
      
      // 验证进度显示
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('收藏书籍应该显示收藏图标', (WidgetTester tester) async {
      testBook.isFavorite = true;
      
      await tester.pumpWidget(
        createTestWidget(
          BookCard(book: testBook, mode: BookCardMode.grid),
        ),
      );

      // 验证收藏图标显示
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('已开始阅读的书籍应该显示进度', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          BookCard(book: testBook, mode: BookCardMode.list),
        ),
      );

      // 验证进度条显示
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      // 验证进度文本
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('选中状态应该正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          BookCard(
            book: testBook,
            mode: BookCardMode.grid,
            isSelected: true,
          ),
        ),
      );

      // 验证选中图标显示
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('点击应该触发回调', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        createTestWidget(
          BookCard(
            book: testBook,
            mode: BookCardMode.grid,
            onTap: () => tapped = true,
          ),
        ),
      );

      // 点击书籍卡片
      await tester.tap(find.byType(BookCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('长按应该触发回调', (WidgetTester tester) async {
      bool longPressed = false;
      
      await tester.pumpWidget(
        createTestWidget(
          BookCard(
            book: testBook,
            mode: BookCardMode.grid,
            onLongPress: () => longPressed = true,
          ),
        ),
      );

      // 长按书籍卡片
      await tester.longPress(find.byType(BookCard));
      await tester.pump();

      expect(longPressed, true);
    });

    testWidgets('不同文件类型应该显示对应颜色', (WidgetTester tester) async {
      // 测试PDF文件
      testBook.fileType = 'pdf';
      
      await tester.pumpWidget(
        createTestWidget(
          BookCard(book: testBook, mode: BookCardMode.grid),
        ),
      );

      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('无作者的书籍应该不显示作者信息', (WidgetTester tester) async {
      testBook.author = null;
      
      await tester.pumpWidget(
        createTestWidget(
          BookCard(book: testBook, mode: BookCardMode.grid),
        ),
      );

      // 验证只显示标题，不显示作者
      expect(find.text('测试书籍'), findsOneWidget);
      expect(find.text('测试作者'), findsNothing);
    });
  });

  group('BookActionSheet Tests', () {
    late Book testBook;

    setUp(() {
      testBook = Book()
        ..id = 1
        ..title = '测试书籍'
        ..author = '测试作者'
        ..filePath = '/test/path/book.epub';
    });

    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BookActionSheet(book: testBook),
          ),
        ),
      );
    }

    testWidgets('BookActionSheet 应该显示操作选项', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 验证操作选项显示
      expect(find.text('继续阅读'), findsOneWidget);
      expect(find.text('添加收藏'), findsOneWidget);
      expect(find.text('书籍详情'), findsOneWidget);
      expect(find.text('删除书籍'), findsOneWidget);
    });

    testWidgets('收藏状态应该正确显示', (WidgetTester tester) async {
      testBook.isFavorite = true;
      
      await tester.pumpWidget(createTestWidget());

      expect(find.text('取消收藏'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}