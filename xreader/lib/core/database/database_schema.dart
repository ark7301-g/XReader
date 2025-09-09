/// 数据库Schema定义
/// 
/// 这个文件定义了XReader应用的完整数据库结构，
/// 包括所有表的创建SQL和版本管理。
class DatabaseSchema {
  static const String databaseName = 'xreader.db';
  static const int currentVersion = 2;
  
  /// 获取所有表的创建SQL
  static List<String> get createTableStatements => [
    createBooksTable,
    createBookContentsTable,
    createChaptersTable,
    createReadingProgressTable,
    createBookmarksTable,
    createNotesTable,
    createTagsTable,
    createBookTagsTable,
    createReadingSessionsTable,
    createCacheMetadataTable,
  ];
  
  /// 获取所有索引的创建SQL
  static List<String> get createIndexStatements => [
    'CREATE INDEX idx_books_file_path ON books(file_path);',
    'CREATE INDEX idx_books_added_date ON books(added_date);',
    'CREATE INDEX idx_books_last_read_date ON books(last_read_date);',
    'CREATE INDEX idx_books_is_favorite ON books(is_favorite);',
    'CREATE INDEX idx_book_contents_book_id ON book_contents(book_id);',
    'CREATE INDEX idx_chapters_book_id ON chapters(book_id);',
    'CREATE INDEX idx_chapters_start_page ON chapters(start_page);',
    'CREATE INDEX idx_reading_progress_book_id ON reading_progress(book_id);',
    'CREATE INDEX idx_bookmarks_book_id ON bookmarks(book_id);',
    'CREATE INDEX idx_bookmarks_page_number ON bookmarks(page_number);',
    'CREATE INDEX idx_notes_book_id ON notes(book_id);',
    'CREATE INDEX idx_book_tags_book_id ON book_tags(book_id);',
    'CREATE INDEX idx_book_tags_tag_id ON book_tags(tag_id);',
    'CREATE INDEX idx_reading_sessions_book_id ON reading_sessions(book_id);',
    'CREATE INDEX idx_reading_sessions_start_time ON reading_sessions(start_time);',
    'CREATE INDEX idx_cache_metadata_cache_key ON cache_metadata(cache_key);',
  ];

  /// 书籍基本信息表
  static const String createBooksTable = '''
    CREATE TABLE books (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_path TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      author TEXT,
      publisher TEXT,
      description TEXT,
      language TEXT,
      isbn TEXT,
      cover_path TEXT,
      file_type TEXT NOT NULL,
      file_size INTEGER NOT NULL DEFAULT 0,
      epub_version TEXT,
      identifier TEXT,
      rights TEXT,
      subject TEXT,
      added_date INTEGER NOT NULL,
      last_read_date INTEGER,
      publish_date INTEGER,
      current_page INTEGER NOT NULL DEFAULT 0,
      total_pages INTEGER NOT NULL DEFAULT 0,
      reading_progress REAL NOT NULL DEFAULT 0.0,
      last_read_position TEXT,
      reading_time_minutes INTEGER NOT NULL DEFAULT 0,
      total_reading_sessions INTEGER NOT NULL DEFAULT 0,
      is_favorite INTEGER NOT NULL DEFAULT 0,
      rating INTEGER NOT NULL DEFAULT 0,
      custom_font_size REAL,
      custom_line_height REAL,
      custom_font_family TEXT,
      custom_theme_mode INTEGER,
      parsing_metadata TEXT,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
    );
  ''';

  /// 书籍内容表（存储分页后的内容）
  static const String createBookContentsTable = '''
    CREATE TABLE book_contents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      content_file_id TEXT NOT NULL,
      href TEXT NOT NULL,
      media_type TEXT NOT NULL,
      page_number INTEGER NOT NULL,
      content TEXT NOT NULL,
      raw_content TEXT,
      content_length INTEGER NOT NULL DEFAULT 0,
      processing_strategy TEXT,
      processing_time INTEGER,
      quality_score REAL NOT NULL DEFAULT 1.0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
      UNIQUE(book_id, content_file_id, page_number)
    );
  ''';

  /// 章节信息表
  static const String createChaptersTable = '''
    CREATE TABLE chapters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      chapter_id TEXT NOT NULL,
      title TEXT NOT NULL,
      level INTEGER NOT NULL DEFAULT 1,
      href TEXT,
      anchor TEXT,
      start_page INTEGER NOT NULL,
      end_page INTEGER NOT NULL,
      parent_chapter_id INTEGER,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
      FOREIGN KEY (parent_chapter_id) REFERENCES chapters (id) ON DELETE CASCADE,
      UNIQUE(book_id, chapter_id)
    );
  ''';

  /// 阅读进度表
  static const String createReadingProgressTable = '''
    CREATE TABLE reading_progress (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      current_page INTEGER NOT NULL,
      progress_percentage REAL NOT NULL,
      position TEXT,
      chapter_id TEXT,
      scroll_position REAL,
      reading_time_minutes INTEGER NOT NULL DEFAULT 0,
      session_count INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
      UNIQUE(book_id)
    );
  ''';

  /// 书签表
  static const String createBookmarksTable = '''
    CREATE TABLE bookmarks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      bookmark_id TEXT NOT NULL UNIQUE,
      page_number INTEGER NOT NULL,
      chapter_title TEXT NOT NULL,
      chapter_position TEXT,
      note TEXT,
      selected_text TEXT,
      bookmark_type INTEGER NOT NULL DEFAULT 0,
      created_date INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
    );
  ''';

  /// 笔记表
  static const String createNotesTable = '''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      note_id TEXT NOT NULL UNIQUE,
      page_number INTEGER NOT NULL,
      chapter_title TEXT NOT NULL,
      chapter_position TEXT,
      content TEXT NOT NULL,
      selected_text TEXT,
      note_type INTEGER NOT NULL DEFAULT 0,
      created_date INTEGER NOT NULL,
      modified_date INTEGER,
      FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
    );
  ''';

  /// 标签表
  static const String createTagsTable = '''
    CREATE TABLE tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      color TEXT,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
    );
  ''';

  /// 书籍标签关联表
  static const String createBookTagsTable = '''
    CREATE TABLE book_tags (
      book_id INTEGER NOT NULL,
      tag_id INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      PRIMARY KEY (book_id, tag_id),
      FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
      FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
    );
  ''';

  /// 阅读会话表
  static const String createReadingSessionsTable = '''
    CREATE TABLE reading_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      start_time INTEGER NOT NULL,
      end_time INTEGER,
      start_page INTEGER NOT NULL,
      end_page INTEGER,
      duration_minutes INTEGER,
      pages_read INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
    );
  ''';

  /// 缓存元数据表
  static const String createCacheMetadataTable = '''
    CREATE TABLE cache_metadata (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cache_key TEXT NOT NULL UNIQUE,
      cache_type TEXT NOT NULL,
      data TEXT,
      data_size INTEGER NOT NULL DEFAULT 0,
      last_accessed INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      expires_at INTEGER,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
    );
  ''';

  /// 数据库升级脚本
  static List<String> getUpgradeStatements(int oldVersion, int newVersion) {
    final statements = <String>[];
    
    // 从版本1升级到版本2：添加缓存表的data列
    if (oldVersion < 2 && newVersion >= 2) {
      statements.addAll([
        'DROP TABLE IF EXISTS cache_metadata;',
        createCacheMetadataTable,
      ]);
    }
    
    return statements;
  }

  /// 清理过期缓存的SQL
  static const String cleanExpiredCache = '''
    DELETE FROM cache_metadata 
    WHERE expires_at IS NOT NULL 
    AND expires_at < strftime('%s', 'now');
  ''';

  /// 获取数据库大小的SQL
  static const String getDatabaseSize = '''
    SELECT page_count * page_size as size 
    FROM pragma_page_count(), pragma_page_size();
  ''';

  /// 获取表行数统计的SQL
  static const String getTableStats = '''
    SELECT 
      'books' as table_name, COUNT(*) as row_count FROM books
    UNION ALL
    SELECT 
      'book_contents' as table_name, COUNT(*) as row_count FROM book_contents
    UNION ALL
    SELECT 
      'chapters' as table_name, COUNT(*) as row_count FROM chapters
    UNION ALL
    SELECT 
      'bookmarks' as table_name, COUNT(*) as row_count FROM bookmarks
    UNION ALL
    SELECT 
      'notes' as table_name, COUNT(*) as row_count FROM notes
    UNION ALL
    SELECT 
      'reading_sessions' as table_name, COUNT(*) as row_count FROM reading_sessions;
  ''';

  /// 备份数据库的表
  static const List<String> backupTables = [
    'books',
    'chapters', 
    'bookmarks',
    'notes',
    'tags',
    'book_tags',
    'reading_progress',
    'reading_sessions',
  ];

  /// 创建数据库触发器
  static List<String> get createTriggers => [
    // 更新books表的updated_at字段
    '''
    CREATE TRIGGER update_books_timestamp 
    AFTER UPDATE ON books
    BEGIN
      UPDATE books SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
    END;
    ''',
    
    // 更新缓存元数据的最后访问时间
    '''
    CREATE TRIGGER update_cache_access 
    AFTER UPDATE ON cache_metadata
    BEGIN
      UPDATE cache_metadata 
      SET last_accessed = strftime('%s', 'now'), 
          updated_at = strftime('%s', 'now') 
      WHERE id = NEW.id;
    END;
    ''',
    
    // 自动清理关联的内容数据
    '''
    CREATE TRIGGER cleanup_book_data 
    AFTER DELETE ON books
    BEGIN
      DELETE FROM book_contents WHERE book_id = OLD.id;
      DELETE FROM chapters WHERE book_id = OLD.id;
      DELETE FROM reading_progress WHERE book_id = OLD.id;
      DELETE FROM bookmarks WHERE book_id = OLD.id;
      DELETE FROM notes WHERE book_id = OLD.id;
      DELETE FROM book_tags WHERE book_id = OLD.id;
      DELETE FROM reading_sessions WHERE book_id = OLD.id;
    END;
    ''',
  ];
}

/// 数据库常量
class DatabaseConstants {
  // 表名
  static const String booksTable = 'books';
  static const String bookContentsTable = 'book_contents';
  static const String chaptersTable = 'chapters';
  static const String readingProgressTable = 'reading_progress';
  static const String bookmarksTable = 'bookmarks';
  static const String notesTable = 'notes';
  static const String tagsTable = 'tags';
  static const String bookTagsTable = 'book_tags';
  static const String readingSessionsTable = 'reading_sessions';
  static const String cacheMetadataTable = 'cache_metadata';
  
  // 缓存类型
  static const String cacheTypePageContent = 'page_content';
  static const String cacheTypeChapterList = 'chapter_list';
  static const String cacheTypeBookList = 'book_list';
  static const String cacheTypeSearchResult = 'search_result';
  
  // 缓存过期时间（秒）
  static const int cacheExpiryPageContent = 24 * 60 * 60; // 24小时
  static const int cacheExpiryChapterList = 7 * 24 * 60 * 60; // 7天
  static const int cacheExpiryBookList = 60 * 60; // 1小时
  static const int cacheExpirySearchResult = 30 * 60; // 30分钟
  
  // 分页大小
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // 批处理大小
  static const int batchSize = 50;
  
  // 最大缓存大小（字节）
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
}
