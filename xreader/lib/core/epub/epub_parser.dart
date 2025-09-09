import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'models/epub_book.dart';
import 'epub_validator.dart';
import 'content_extractor.dart';
import 'html_processor.dart';
import 'chapter_analyzer.dart';
import 'pagination_engine.dart';

/// 增强的EPUB解析器
/// 
/// 这是新的EPUB解析器实现，提供了以下改进：
/// - 更好的兼容性和容错能力
/// - 多策略内容提取
/// - 智能HTML处理
/// - 准确的章节分析
/// - 优化的分页算法
class EpubParser {
  static const String version = '2.0.0';
  
  final EpubParsingConfig config;
  final EpubValidator _validator;
  final ContentExtractor _contentExtractor;
  final HtmlProcessor _htmlProcessor;
  final ChapterAnalyzer _chapterAnalyzer;
  final PaginationEngine _paginationEngine;
  
  EpubParser({
    EpubParsingConfig? config,
  }) : config = config ?? EpubParsingConfig.defaultConfig(),
        _validator = EpubValidator(),
        _contentExtractor = ContentExtractor(config ?? EpubParsingConfig.defaultConfig()),
        _htmlProcessor = HtmlProcessor(config ?? EpubParsingConfig.defaultConfig()),
        _chapterAnalyzer = ChapterAnalyzer(config ?? EpubParsingConfig.defaultConfig()),
        _paginationEngine = PaginationEngine(config ?? EpubParsingConfig.defaultConfig());

  /// 解析EPUB文件
  /// 
  /// [filePath] EPUB文件路径
  /// 返回解析结果，包含书籍信息或错误信息
  Future<EpubParsingResult> parseFile(String filePath) async {
    final stopwatch = Stopwatch()..start();
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    final strategiesUsed = <String>[];
    
    try {
      print('📚 开始解析EPUB文件: ${_getFileName(filePath)}');
      
      // 阶段1: 文件验证
      print('🔍 阶段1: 文件验证');
      final validationResult = await _validator.validateFile(filePath);
      if (!validationResult.isValid) {
        return EpubParsingResult.failure(
          errors: validationResult.errors,
          warnings: validationResult.warnings,
          processingTime: stopwatch.elapsed,
        );
      }
      
      errors.addAll(validationResult.errors);
      warnings.addAll(validationResult.warnings);
      
      // 阶段2: 文件读取和ZIP解压
      print('📁 阶段2: 文件读取和解压');
      final archive = await _readAndExtractFile(filePath);
      strategiesUsed.add('zip_extraction');
      
      // 阶段3: EPUB结构解析
      print('🔍 阶段3: EPUB结构解析');
      final epubStructure = await _parseEpubStructure(archive);
      strategiesUsed.add('structure_parsing');
      
      // 阶段4: 内容提取
      print('📄 阶段4: 内容提取');
      final extractionResult = await _contentExtractor.extractContent(archive, epubStructure);
      errors.addAll(extractionResult.errors);
      warnings.addAll(extractionResult.warnings);
      strategiesUsed.addAll(extractionResult.strategiesUsed);
      
      // 阶段5: HTML处理
      print('🧹 阶段5: HTML内容处理');
      final processedContent = await _htmlProcessor.processContent(extractionResult.contentFiles);
      errors.addAll(processedContent.errors);
      warnings.addAll(processedContent.warnings);
      
      // 阶段6: 章节分析
      print('📖 阶段6: 章节结构分析');
      final chapters = await _chapterAnalyzer.analyzeChapters(
        epubStructure, 
        processedContent.contentFiles,
      );
      
      // 阶段7: 内容分页
      print('📄 阶段7: 内容分页');
      final paginationResult = await _paginationEngine.paginateContent(
        processedContent.contentFiles,
        chapters,
      );
      
      // 阶段8: 构建最终结果
      print('🔨 阶段8: 构建最终书籍模型');
      final book = await _buildBookModel(
        filePath: filePath,
        structure: epubStructure,
        contentFiles: processedContent.contentFiles,
        chapters: chapters,
        paginationResult: paginationResult,
        processingTime: stopwatch.elapsed,
        strategiesUsed: strategiesUsed,
        errors: errors,
        warnings: warnings,
      );
      
      stopwatch.stop();
      
      print('✅ EPUB解析完成');
      print('   📊 总耗时: ${stopwatch.elapsed.inMilliseconds}ms');
      print('   📄 总页数: ${paginationResult.totalPages}');
      print('   📖 章节数: ${chapters.length}');
      print('   ⚠️  警告数: ${warnings.length}');
      print('   ❌ 错误数: ${errors.length}');
      
      return EpubParsingResult.success(
        book: book,
        processingTime: stopwatch.elapsed,
        strategiesUsed: strategiesUsed,
        errors: errors,
        warnings: warnings,
      );
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      
      final error = EpubParsingError(
        level: EpubParsingErrorLevel.fatal,
        message: '解析过程中发生未预期错误: ${e.toString()}',
        suggestion: '请检查文件是否损坏或联系开发者',
        originalException: e is Exception ? e : Exception(e.toString()),
        timestamp: DateTime.now(),
      );
      
      print('❌ EPUB解析失败: ${e.toString()}');
      print('🔧 错误堆栈: $stackTrace');
      
      return EpubParsingResult.failure(
        errors: [error, ...errors],
        warnings: warnings,
        processingTime: stopwatch.elapsed,
        strategiesUsed: strategiesUsed,
      );
    }
  }

  /// 读取并解压EPUB文件
  Future<Archive> _readAndExtractFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      print('   ✅ ZIP解压成功，包含${archive.length}个文件');
      return archive;
    } catch (e) {
      throw EpubParsingException('ZIP文件解压失败: ${e.toString()}');
    }
  }

  /// 解析EPUB结构
  Future<EpubStructure> _parseEpubStructure(Archive archive) async {
    try {
      // 1. 查找并解析container.xml
      final containerFile = archive.findFile('META-INF/container.xml');
      if (containerFile == null) {
        throw const EpubParsingException('找不到META-INF/container.xml文件');
      }
      
      final containerXml = utf8.decode(containerFile.content as List<int>, allowMalformed: true);
      final containerDoc = XmlDocument.parse(containerXml);
      
      // 2. 获取OPF文件路径
      final rootFileElement = containerDoc
          .findAllElements('rootfile')
                .where((element) => element.getAttribute('media-type') == 'application/oebps-package+xml')
      .cast<XmlElement?>()
      .firstWhere((element) => element != null, orElse: () => null);
      
      if (rootFileElement == null) {
        throw const EpubParsingException('在container.xml中找不到有效的rootfile');
      }
      
      final opfPath = rootFileElement.getAttribute('full-path');
      if (opfPath == null) {
        throw const EpubParsingException('rootfile缺少full-path属性');
      }
      
      print('   📄 找到OPF文件: $opfPath');
      
      // 3. 解析OPF文件
      final opfFile = archive.findFile(opfPath);
      if (opfFile == null) {
        throw EpubParsingException('找不到OPF文件: $opfPath');
      }
      
      final opfXml = utf8.decode(opfFile.content as List<int>, allowMalformed: true);
      final opfDoc = XmlDocument.parse(opfXml);
      
      // 4. 解析各个部分
      final metadata = _parseMetadata(opfDoc);
      final manifest = _parseManifest(opfDoc, opfPath);
      final spine = _parseSpine(opfDoc);
      final navigation = await _parseNavigation(archive, manifest);
      
      return EpubStructure(
        opfPath: opfPath,
        metadata: metadata,
        manifest: manifest,
        spine: spine,
        navigation: navigation,
        archive: archive,
      );
      
    } catch (e) {
      if (e is EpubParsingException) rethrow;
      throw EpubParsingException('解析EPUB结构失败: ${e.toString()}');
    }
  }

  /// 解析元数据
  EpubMetadata _parseMetadata(XmlDocument opfDoc) {
    final metadataElement = opfDoc.findAllElements('metadata').isEmpty 
        ? null 
        : opfDoc.findAllElements('metadata').first;
    if (metadataElement == null) {
      return const EpubMetadata(title: '未知标题');
    }
    
    String? getElementText(String tagName) {
      return metadataElement.findElements(tagName).isEmpty 
          ? null 
          : metadataElement.findElements(tagName).first.text;
    }
    
    List<String> getElementTexts(String tagName) {
      return metadataElement.findElements(tagName).map((e) => e.text).toList();
    }
    
    return EpubMetadata(
      title: getElementText('title') ?? getElementText('dc:title') ?? '未知标题',
      author: getElementText('creator') ?? getElementText('dc:creator'),
      language: getElementText('language') ?? getElementText('dc:language'),
      publisher: getElementText('publisher') ?? getElementText('dc:publisher'),
      description: getElementText('description') ?? getElementText('dc:description'),
      identifier: getElementText('identifier') ?? getElementText('dc:identifier'),
      rights: getElementText('rights') ?? getElementText('dc:rights'),
      subject: getElementText('subject') ?? getElementText('dc:subject'),
      contributors: getElementTexts('contributor') + getElementTexts('dc:contributor'),
    );
  }

  /// 解析清单
  EpubManifestModel _parseManifest(XmlDocument opfDoc, String opfPath) {
    final manifestElement = opfDoc.findAllElements('manifest').isEmpty 
        ? null 
        : opfDoc.findAllElements('manifest').first;
    if (manifestElement == null) {
      return const EpubManifestModel(items: []);
    }
    
    final items = <EpubManifestItem>[];
    final basePath = _getDirectoryPath(opfPath);
    
    for (final itemElement in manifestElement.findElements('item')) {
      final id = itemElement.getAttribute('id');
      final href = itemElement.getAttribute('href');
      final mediaType = itemElement.getAttribute('media-type');
      
      if (id != null && href != null && mediaType != null) {
        final fullHref = basePath.isNotEmpty ? '$basePath/$href' : href;
        
        final properties = <String, String>{};
        final propertiesAttr = itemElement.getAttribute('properties');
        if (propertiesAttr != null) {
          for (final prop in propertiesAttr.split(' ')) {
            properties[prop.trim()] = '';
          }
        }
        
        items.add(EpubManifestItem(
          id: id,
          href: fullHref,
          mediaType: mediaType,
          properties: properties,
        ));
      }
    }
    
    print('   📄 解析清单完成，包含${items.length}个项目');
    return EpubManifestModel(items: items, sourceFile: opfPath);
  }

  /// 解析脊柱
  EpubSpineModel _parseSpine(XmlDocument opfDoc) {
    final spineElement = opfDoc.findAllElements('spine').isEmpty 
        ? null 
        : opfDoc.findAllElements('spine').first;
    if (spineElement == null) {
      return const EpubSpineModel(items: []);
    }
    
    final items = <EpubSpineItem>[];
    final toc = spineElement.getAttribute('toc');
    
    for (final itemRefElement in spineElement.findElements('itemref')) {
      final idRef = itemRefElement.getAttribute('idref');
      if (idRef != null) {
        final linear = itemRefElement.getAttribute('linear');
        final isLinear = linear == null || linear.toLowerCase() != 'no';
        
        final properties = <String, String>{};
        final propertiesAttr = itemRefElement.getAttribute('properties');
        if (propertiesAttr != null) {
          for (final prop in propertiesAttr.split(' ')) {
            properties[prop.trim()] = '';
          }
        }
        
        items.add(EpubSpineItem(
          idRef: idRef,
          isLinear: isLinear,
          properties: properties,
        ));
      }
    }
    
    print('   📚 解析脊柱完成，包含${items.length}个项目');
    return EpubSpineModel(items: items, toc: toc);
  }

  /// 解析导航
  Future<EpubNavigationModel?> _parseNavigation(Archive archive, EpubManifestModel manifest) async {
    try {
      // 先尝试EPUB3的Navigation文档
      final navItem = manifest.items.where((item) => item.isNav).isEmpty 
          ? null 
          : manifest.items.where((item) => item.isNav).first;
      if (navItem != null) {
        return await _parseNavDocument(archive, navItem.href);
      }
      
      // 然后尝试NCX文件
      final ncxItems = manifest.findByMediaType('application/x-dtbncx+xml');
      for (final ncxItem in ncxItems) {
        final navigation = await _parseNcxDocument(archive, ncxItem.href);
        if (navigation != null) return navigation;
      }
      
      print('   ⚠️  未找到导航文档');
      return null;
    } catch (e) {
      print('   ❌ 解析导航失败: $e');
      return null;
    }
  }

  /// 解析EPUB3 Navigation文档
  Future<EpubNavigationModel?> _parseNavDocument(Archive archive, String href) async {
    try {
      final navFile = archive.findFile(href);
      if (navFile == null) return null;
      
      final navXml = utf8.decode(navFile.content as List<int>, allowMalformed: true);
      final navDoc = XmlDocument.parse(navXml);
      
      final tocNavs = navDoc.findAllElements('nav')
          .where((nav) => nav.getAttribute('epub:type') == 'toc');
      final tocNav = tocNavs.isEmpty ? null : tocNavs.first;
      
      if (tocNav == null) return null;
      
      final olElements = tocNav.findElements('ol');
      final points = _parseNavPoints(olElements.isEmpty ? null : olElements.first, 1);
      
      return EpubNavigationModel(
        points: points,
        sourceFile: href,
        type: EpubNavigationType.nav,
      );
    } catch (e) {
      print('   ❌ 解析Navigation文档失败: $e');
      return null;
    }
  }

  /// 解析NCX文档
  Future<EpubNavigationModel?> _parseNcxDocument(Archive archive, String href) async {
    try {
      final ncxFile = archive.findFile(href);
      if (ncxFile == null) return null;
      
      final ncxXml = utf8.decode(ncxFile.content as List<int>, allowMalformed: true);
      final ncxDoc = XmlDocument.parse(ncxXml);
      
      final navMapElements = ncxDoc.findAllElements('navMap');
      final navMapElement = navMapElements.isEmpty ? null : navMapElements.first;
      if (navMapElement == null) return null;
      
      final points = <EpubNavigationPoint>[];
      for (final navPointElement in navMapElement.findElements('navPoint')) {
        final point = _parseNavPoint(navPointElement, 1);
        if (point != null) points.add(point);
      }
      
      final docTitleElements = ncxDoc.findAllElements('docTitle');
      final docTitle = docTitleElements.isEmpty 
          ? null 
          : (docTitleElements.first.findElements('text').isEmpty 
              ? null 
              : docTitleElements.first.findElements('text').first.text);
      
      return EpubNavigationModel(
        points: points,
        docTitle: docTitle,
        sourceFile: href,
        type: EpubNavigationType.ncx,
      );
    } catch (e) {
      print('   ❌ 解析NCX文档失败: $e');
      return null;
    }
  }

  /// 解析导航点（NCX）
  EpubNavigationPoint? _parseNavPoint(XmlElement navPointElement, int level) {
    final id = navPointElement.getAttribute('id') ?? 'nav_${DateTime.now().millisecondsSinceEpoch}';
    final playOrder = int.tryParse(navPointElement.getAttribute('playOrder') ?? '');
    
    final labelElements = navPointElement.findElements('navLabel');
    final labelElement = labelElements.isEmpty ? null : labelElements.first;
    final label = labelElement == null 
        ? '未知章节'
        : (labelElement.findElements('text').isEmpty 
            ? '未知章节' 
            : labelElement.findElements('text').first.text);
    
    final contentElements = navPointElement.findElements('content');
    final contentElement = contentElements.isEmpty ? null : contentElements.first;
    final href = contentElement?.getAttribute('src');
    
    final children = <EpubNavigationPoint>[];
    for (final childElement in navPointElement.findElements('navPoint')) {
      final child = _parseNavPoint(childElement, level + 1);
      if (child != null) children.add(child);
    }
    
    return EpubNavigationPoint(
      id: id,
      label: label,
      href: href,
      playOrder: playOrder,
      children: children,
      level: level,
    );
  }

  /// 解析Navigation列表点
  List<EpubNavigationPoint> _parseNavPoints(XmlElement? olElement, int level) {
    if (olElement == null) return [];
    
    final points = <EpubNavigationPoint>[];
    
    for (final liElement in olElement.findElements('li')) {
      final aElements = liElement.findElements('a');
      final aElement = aElements.isEmpty ? null : aElements.first;
      if (aElement == null) continue;
      
      final href = aElement.getAttribute('href');
      final label = aElement.text.trim();
      final id = 'nav_${points.length}_$level';
      
      final subOlElements = liElement.findElements('ol');
      final subOl = subOlElements.isEmpty ? null : subOlElements.first;
      final children = _parseNavPoints(subOl, level + 1);
      
      points.add(EpubNavigationPoint(
        id: id,
        label: label.isNotEmpty ? label : '未知章节',
        href: href,
        children: children,
        level: level,
      ));
    }
    
    return points;
  }

  /// 构建最终的书籍模型
  Future<EpubBookModel> _buildBookModel({
    required String filePath,
    required EpubStructure structure,
    required List<EpubContentFile> contentFiles,
    required List<EpubChapterModel> chapters,
    required PaginationResult paginationResult,
    required Duration processingTime,
    required List<String> strategiesUsed,
    required List<EpubParsingError> errors,
    required List<EpubParsingWarning> warnings,
  }) async {
    final file = File(filePath);
    final fileSize = await file.length();
    
    final parsingMetadata = EpubParsingMetadata(
      processingTime: processingTime,
      strategiesUsed: strategiesUsed,
      errors: errors,
      warnings: warnings,
      estimatedPages: paginationResult.totalPages,
      parsingVersion: version,
      diagnostics: {
        'file_size': fileSize,
        'content_files': contentFiles.length,
        'chapters': chapters.length,
        'total_pages': paginationResult.totalPages,
        'has_navigation': structure.navigation != null,
        'epub_version': _detectEpubVersion(structure),
      },
    );
    
    return EpubBookModel(
      title: structure.metadata.title,
      author: structure.metadata.author,
      language: structure.metadata.language,
      publisher: structure.metadata.publisher,
      description: structure.metadata.description,
      identifier: structure.metadata.identifier,
      rights: structure.metadata.rights,
      subject: structure.metadata.subject,
      filePath: filePath,
      fileSize: fileSize,
      version: _detectEpubVersion(structure),
      chapters: chapters,
      contentFiles: contentFiles,
      images: [], // TODO: 实现图片提取
      styles: [], // TODO: 实现样式提取
      navigation: structure.navigation,
      manifest: structure.manifest,
      spine: structure.spine,
      parsingMetadata: parsingMetadata,
      coverImagePath: null, // TODO: 实现封面提取
      parsedAt: DateTime.now(),
    );
  }

  /// 检测EPUB版本
  String _detectEpubVersion(EpubStructure structure) {
    // 简单的版本检测逻辑
    if (structure.navigation?.type == EpubNavigationType.nav) {
      return '3.0+';
    }
    return '2.0';
  }

  /// 获取文件名
  String _getFileName(String filePath) {
    return filePath.split('/').last.split(r'\').last;
  }

  /// 获取目录路径
  String _getDirectoryPath(String filePath) {
    final parts = filePath.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }
}

/// EPUB解析配置
class EpubParsingConfig {
  // 文件验证配置
  final int maxFileSize;
  final List<String> supportedEncodings;
  
  // 内容提取配置
  final bool enableFallbackStrategies;
  final int maxRetryAttempts;
  final bool enableParallelProcessing;
  
  // HTML处理配置
  final bool preserveFormatting;
  final bool aggressiveCleanup;
  final double minQualityScore;
  
  // 分页配置
  final int targetCharsPerPage;
  final int minCharsPerPage;
  final int maxCharsPerPage;
  final bool preserveParagraphs;
  
  // 性能配置
  final bool enableCaching;
  final int maxMemoryUsage;
  final Duration processingTimeout;
  
  const EpubParsingConfig({
    this.maxFileSize = 50 * 1024 * 1024, // 50MB
    this.supportedEncodings = const ['utf-8', 'utf-16', 'iso-8859-1'],
    this.enableFallbackStrategies = true,
    this.maxRetryAttempts = 3,
    this.enableParallelProcessing = true,
    this.preserveFormatting = true,
    this.aggressiveCleanup = false,
    this.minQualityScore = 0.3,
    this.targetCharsPerPage = 1200,
    this.minCharsPerPage = 800,
    this.maxCharsPerPage = 1800,
    this.preserveParagraphs = true,
    this.enableCaching = true,
    this.maxMemoryUsage = 100 * 1024 * 1024, // 100MB
    this.processingTimeout = const Duration(minutes: 5),
  });

  factory EpubParsingConfig.defaultConfig() => const EpubParsingConfig();
  
  factory EpubParsingConfig.performance() => const EpubParsingConfig(
    enableParallelProcessing: true,
    enableCaching: true,
    aggressiveCleanup: true,
    maxRetryAttempts: 1,
  );
  
  factory EpubParsingConfig.quality() => const EpubParsingConfig(
    preserveFormatting: true,
    aggressiveCleanup: false,
    minQualityScore: 0.7,
    maxRetryAttempts: 5,
  );
}

/// EPUB解析结果
class EpubParsingResult {
  final EpubBookModel? book;
  final bool isSuccess;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final Duration processingTime;
  final List<String> strategiesUsed;
  
  const EpubParsingResult._({
    this.book,
    required this.isSuccess,
    this.errors = const [],
    this.warnings = const [],
    required this.processingTime,
    this.strategiesUsed = const [],
  });

  factory EpubParsingResult.success({
    required EpubBookModel book,
    required Duration processingTime,
    List<String> strategiesUsed = const [],
    List<EpubParsingError> errors = const [],
    List<EpubParsingWarning> warnings = const [],
  }) {
    return EpubParsingResult._(
      book: book,
      isSuccess: true,
      errors: errors,
      warnings: warnings,
      processingTime: processingTime,
      strategiesUsed: strategiesUsed,
    );
  }

  factory EpubParsingResult.failure({
    required List<EpubParsingError> errors,
    List<EpubParsingWarning> warnings = const [],
    required Duration processingTime,
    List<String> strategiesUsed = const [],
  }) {
    return EpubParsingResult._(
      isSuccess: false,
      errors: errors,
      warnings: warnings,
      processingTime: processingTime,
      strategiesUsed: strategiesUsed,
    );
  }

  /// 是否有致命错误
  bool get hasFatalErrors => errors.any((e) => e.level == EpubParsingErrorLevel.fatal);
  
  /// 获取错误摘要
  String get errorSummary {
    if (errors.isEmpty) return '无错误';
    return errors.map((e) => e.message).join('; ');
  }
  
  /// 获取警告摘要
  String get warningSummary {
    if (warnings.isEmpty) return '无警告';
    return warnings.map((w) => w.message).join('; ');
  }
}

/// EPUB结构信息
class EpubStructure {
  final String opfPath;
  final EpubMetadata metadata;
  final EpubManifestModel manifest;
  final EpubSpineModel spine;
  final EpubNavigationModel? navigation;
  final Archive archive;
  
  const EpubStructure({
    required this.opfPath,
    required this.metadata,
    required this.manifest,
    required this.spine,
    this.navigation,
    required this.archive,
  });
}

/// EPUB元数据
class EpubMetadata {
  final String title;
  final String? author;
  final String? language;
  final String? publisher;
  final String? description;
  final String? identifier;
  final String? rights;
  final String? subject;
  final List<String> contributors;
  
  const EpubMetadata({
    required this.title,
    this.author,
    this.language,
    this.publisher,
    this.description,
    this.identifier,
    this.rights,
    this.subject,
    this.contributors = const [],
  });
}

/// EPUB解析异常
class EpubParsingException implements Exception {
  final String message;
  final Exception? originalException;
  
  const EpubParsingException(this.message, [this.originalException]);
  
  @override
  String toString() => 'EpubParsingException: $message';
}

/// Archive扩展方法
extension ArchiveExtensions on Archive {
  /// 查找文件（不区分大小写）
  ArchiveFile? findFile(String path) {
    // 先尝试精确匹配
    for (final file in files) {
      if (file.name == path) return file;
    }
    
    // 再尝试不区分大小写匹配
    final lowerPath = path.toLowerCase();
    for (final file in files) {
      if (file.name.toLowerCase() == lowerPath) return file;
    }
    
    return null;
  }
}

/// XmlElement扩展方法
extension XmlElementExtensions on XmlElement {
  /// 获取第一个匹配的元素或null
  XmlElement? get firstOrNull => this;
}
