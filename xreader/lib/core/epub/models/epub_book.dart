/// Enhanced EPUB Book Model
/// 增强的EPUB书籍模型，包含完整的元数据和结构信息
class EpubBookModel {
  // 基本信息
  final String title;
  final String? author;
  final String? language;
  final String? publisher;
  final String? description;
  final String? isbn;
  final DateTime? publishDate;
  final String? rights;
  final String? subject;
  
  // 文件信息
  final String filePath;
  final int fileSize;
  final String? identifier;
  final String? version; // EPUB版本 (2.0, 3.0, etc.)
  
  // 结构信息
  final List<EpubChapterModel> chapters;
  final List<EpubContentFile> contentFiles;
  final List<EpubImageFile> images;
  final List<EpubStyleFile> styles;
  final EpubNavigationModel? navigation;
  final EpubManifestModel manifest;
  final EpubSpineModel spine;
  
  // 处理信息
  final EpubParsingMetadata parsingMetadata;
  final String? coverImagePath;
  final DateTime parsedAt;
  
  const EpubBookModel({
    required this.title,
    this.author,
    this.language,
    this.publisher,
    this.description,
    this.isbn,
    this.publishDate,
    this.rights,
    this.subject,
    required this.filePath,
    required this.fileSize,
    this.identifier,
    this.version,
    this.chapters = const [],
    this.contentFiles = const [],
    this.images = const [],
    this.styles = const [],
    this.navigation,
    required this.manifest,
    required this.spine,
    required this.parsingMetadata,
    this.coverImagePath,
    required this.parsedAt,
  });

  /// 获取总页数估算
  int get estimatedPageCount => parsingMetadata.estimatedPages;
  
  /// 获取章节数量
  int get chapterCount => chapters.length;
  
  /// 获取内容文件数量
  int get contentFileCount => contentFiles.length;
  
  /// 是否有导航信息
  bool get hasNavigation => navigation != null;
  
  /// 是否有封面
  bool get hasCover => coverImagePath != null;
  
  /// 获取主要作者
  String get primaryAuthor => author ?? '未知作者';
  
  /// 获取格式化的文件大小
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
  
  /// 复制并更新部分字段
  EpubBookModel copyWith({
    String? title,
    String? author,
    String? language,
    String? publisher,
    String? description,
    String? isbn,
    DateTime? publishDate,
    String? rights,
    String? subject,
    String? filePath,
    int? fileSize,
    String? identifier,
    String? version,
    List<EpubChapterModel>? chapters,
    List<EpubContentFile>? contentFiles,
    List<EpubImageFile>? images,
    List<EpubStyleFile>? styles,
    EpubNavigationModel? navigation,
    EpubManifestModel? manifest,
    EpubSpineModel? spine,
    EpubParsingMetadata? parsingMetadata,
    String? coverImagePath,
    DateTime? parsedAt,
  }) {
    return EpubBookModel(
      title: title ?? this.title,
      author: author ?? this.author,
      language: language ?? this.language,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      publishDate: publishDate ?? this.publishDate,
      rights: rights ?? this.rights,
      subject: subject ?? this.subject,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      identifier: identifier ?? this.identifier,
      version: version ?? this.version,
      chapters: chapters ?? this.chapters,
      contentFiles: contentFiles ?? this.contentFiles,
      images: images ?? this.images,
      styles: styles ?? this.styles,
      navigation: navigation ?? this.navigation,
      manifest: manifest ?? this.manifest,
      spine: spine ?? this.spine,
      parsingMetadata: parsingMetadata ?? this.parsingMetadata,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      parsedAt: parsedAt ?? this.parsedAt,
    );
  }
}

/// EPUB章节模型
class EpubChapterModel {
  final String id;
  final String title;
  final int level; // 章节层级，1为一级标题，2为二级标题等
  final String? href; // 源文件链接
  final int startPage;
  final int endPage;
  final List<EpubChapterModel> subChapters; // 子章节
  final String? anchor; // 锚点位置
  final EpubContentFile? contentFile; // 关联的内容文件
  
  const EpubChapterModel({
    required this.id,
    required this.title,
    this.level = 1,
    this.href,
    required this.startPage,
    required this.endPage,
    this.subChapters = const [],
    this.anchor,
    this.contentFile,
  });

  /// 章节包含的页数
  int get pageCount => endPage - startPage + 1;
  
  /// 是否包含指定页面
  bool containsPage(int page) => page >= startPage && page <= endPage;
  
  /// 是否有子章节
  bool get hasSubChapters => subChapters.isNotEmpty;
  
  /// 获取所有子章节（递归）
  List<EpubChapterModel> get allSubChapters {
    final result = <EpubChapterModel>[];
    for (final sub in subChapters) {
      result.add(sub);
      result.addAll(sub.allSubChapters);
    }
    return result;
  }
}

/// EPUB内容文件
class EpubContentFile {
  final String id;
  final String href;
  final String mediaType;
  final String? content; // 处理后的文本内容
  final String? rawContent; // 原始HTML内容
  final int? contentLength;
  final List<String> pages; // 分页后的内容
  final EpubContentProcessingInfo processingInfo;
  
  const EpubContentFile({
    required this.id,
    required this.href,
    required this.mediaType,
    this.content,
    this.rawContent,
    this.contentLength,
    this.pages = const [],
    required this.processingInfo,
  });

  /// 是否为HTML内容
  bool get isHtml => mediaType.contains('html') || mediaType.contains('xhtml');
  
  /// 是否有有效内容
  bool get hasContent => content != null && content!.isNotEmpty;
  
  /// 获取页数
  int get pageCount => pages.length;
  
  /// 获取内容预览
  String get preview {
    if (content == null || content!.isEmpty) return '无内容';
    const maxLength = 100;
    return content!.length > maxLength 
        ? '${content!.substring(0, maxLength)}...'
        : content!;
  }
}

/// EPUB图片文件
class EpubImageFile {
  final String id;
  final String href;
  final String mediaType;
  final List<int>? data; // 图片数据
  final int? size;
  final String? alt; // 替代文本
  final bool isCover; // 是否为封面图片
  
  const EpubImageFile({
    required this.id,
    required this.href,
    required this.mediaType,
    this.data,
    this.size,
    this.alt,
    this.isCover = false,
  });

  /// 获取文件扩展名
  String get extension {
    final parts = href.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }
  
  /// 是否为支持的图片格式
  bool get isSupported {
    const supportedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];
    return supportedTypes.contains(mediaType.toLowerCase());
  }
}

/// EPUB样式文件
class EpubStyleFile {
  final String id;
  final String href;
  final String? content;
  final int? size;
  
  const EpubStyleFile({
    required this.id,
    required this.href,
    this.content,
    this.size,
  });
}

/// EPUB导航模型
class EpubNavigationModel {
  final List<EpubNavigationPoint> points;
  final String? docTitle;
  final List<String> docAuthors;
  final String? sourceFile; // NCX或Navigation文档路径
  final EpubNavigationType type;
  
  const EpubNavigationModel({
    required this.points,
    this.docTitle,
    this.docAuthors = const [],
    this.sourceFile,
    this.type = EpubNavigationType.ncx,
  });

  /// 是否有导航点
  bool get hasNavigation => points.isNotEmpty;
  
  /// 获取所有导航点（扁平化）
  List<EpubNavigationPoint> get flattenedPoints {
    final result = <EpubNavigationPoint>[];
    void addPoints(List<EpubNavigationPoint> points) {
      for (final point in points) {
        result.add(point);
        if (point.children.isNotEmpty) {
          addPoints(point.children);
        }
      }
    }
    addPoints(points);
    return result;
  }
}

/// EPUB导航点
class EpubNavigationPoint {
  final String id;
  final String label;
  final String? href;
  final int? playOrder;
  final List<EpubNavigationPoint> children;
  final int level;
  
  const EpubNavigationPoint({
    required this.id,
    required this.label,
    this.href,
    this.playOrder,
    this.children = const [],
    this.level = 1,
  });

  /// 是否有子导航点
  bool get hasChildren => children.isNotEmpty;
}

/// EPUB清单模型
class EpubManifestModel {
  final List<EpubManifestItem> items;
  final String? sourceFile; // OPF文件路径
  
  const EpubManifestModel({
    required this.items,
    this.sourceFile,
  });

  /// 根据ID查找项目
  EpubManifestItem? findById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 根据媒体类型筛选项目
  List<EpubManifestItem> findByMediaType(String mediaType) {
    return items.where((item) => item.mediaType == mediaType).toList();
  }
  
  /// 获取HTML内容项目
  List<EpubManifestItem> get htmlItems {
    return items.where((item) => 
        item.mediaType.contains('html') || item.mediaType.contains('xhtml')
    ).toList();
  }
  
  /// 获取图片项目
  List<EpubManifestItem> get imageItems {
    return items.where((item) => item.mediaType.startsWith('image/')).toList();
  }
}

/// EPUB清单项目
class EpubManifestItem {
  final String id;
  final String href;
  final String mediaType;
  final Map<String, String> properties;
  
  const EpubManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    this.properties = const {},
  });

  /// 是否为导航文档
  bool get isNav => properties.containsKey('nav');
  
  /// 是否为封面图片
  bool get isCoverImage => properties.containsKey('cover-image');
  
  /// 是否为线性内容
  bool get isLinear => !properties.containsKey('non-linear');
}

/// EPUB脊柱模型
class EpubSpineModel {
  final List<EpubSpineItem> items;
  final String? toc; // TOC引用
  final String direction; // 阅读方向
  
  const EpubSpineModel({
    required this.items,
    this.toc,
    this.direction = 'ltr',
  });

  /// 获取线性项目
  List<EpubSpineItem> get linearItems {
    return items.where((item) => item.isLinear).toList();
  }
  
  /// 根据索引获取项目
  EpubSpineItem? getItem(int index) {
    return index >= 0 && index < items.length ? items[index] : null;
  }
}

/// EPUB脊柱项目
class EpubSpineItem {
  final String idRef;
  final bool isLinear;
  final Map<String, String> properties;
  
  const EpubSpineItem({
    required this.idRef,
    this.isLinear = true,
    this.properties = const {},
  });
}

/// EPUB解析元数据
class EpubParsingMetadata {
  final Duration processingTime;
  final List<String> strategiesUsed;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final int estimatedPages;
  final String parsingVersion;
  final Map<String, dynamic> diagnostics;
  
  const EpubParsingMetadata({
    required this.processingTime,
    this.strategiesUsed = const [],
    this.errors = const [],
    this.warnings = const [],
    required this.estimatedPages,
    required this.parsingVersion,
    this.diagnostics = const {},
  });

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;
  
  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;
  
  /// 解析是否成功
  bool get isSuccessful => !hasErrors;
  
  /// 获取错误摘要
  String get errorSummary {
    if (errors.isEmpty) return '无错误';
    return '${errors.length}个错误: ${errors.map((e) => e.message).join(', ')}';
  }
}

/// EPUB解析错误
class EpubParsingError {
  final EpubParsingErrorLevel level;
  final String message;
  final String? suggestion;
  final String? location;
  final Exception? originalException;
  final DateTime timestamp;
  
  const EpubParsingError({
    required this.level,
    required this.message,
    this.suggestion,
    this.location,
    this.originalException,
    required this.timestamp,
  });
}

/// EPUB解析警告
class EpubParsingWarning {
  final String message;
  final String? suggestion;
  final String? location;
  final DateTime timestamp;
  
  const EpubParsingWarning({
    required this.message,
    this.suggestion,
    this.location,
    required this.timestamp,
  });
}

/// EPUB内容处理信息
class EpubContentProcessingInfo {
  final String strategy; // 使用的处理策略
  final Duration processingTime;
  final int originalLength;
  final int processedLength;
  final List<String> appliedFilters;
  final double qualityScore; // 内容质量评分 0.0-1.0
  
  const EpubContentProcessingInfo({
    required this.strategy,
    required this.processingTime,
    required this.originalLength,
    required this.processedLength,
    this.appliedFilters = const [],
    required this.qualityScore,
  });

  /// 处理效率（保留内容比例）
  double get retentionRatio => originalLength > 0 ? processedLength / originalLength : 0.0;
  
  /// 是否处理成功
  bool get isSuccessful => qualityScore >= 0.5 && processedLength > 0;
}

/// 枚举定义
enum EpubParsingErrorLevel {
  warning,
  error,
  fatal,
}

enum EpubNavigationType {
  ncx,        // NCX文件
  nav,        // EPUB3 Navigation文档
  generated,  // 程序生成
}

enum EpubContentStrategy {
  spine,          // 基于Spine的标准策略
  manifest,       // 基于Manifest的策略
  directory,      // 目录遍历策略
  fallback,       // 兜底策略
}
