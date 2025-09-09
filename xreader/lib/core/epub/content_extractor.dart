import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'models/epub_book.dart';
import 'epub_parser.dart';

/// 内容提取器
/// 
/// 负责从EPUB文件中提取文本内容，采用多策略方式确保兼容性：
/// 1. 基于Spine的标准提取策略
/// 2. 基于Manifest的备选策略  
/// 3. 目录遍历策略
/// 4. 兜底策略
class ContentExtractor {
  final EpubParsingConfig config;
  final List<ContentExtractionStrategy> _strategies;
  
  ContentExtractor(this.config) : _strategies = [
    SpineBasedStrategy(config),
    ManifestBasedStrategy(config),
    DirectoryTraversalStrategy(config),
    FallbackStrategy(config),
  ];

  /// 提取内容
  Future<ContentExtractionResult> extractContent(
    Archive archive, 
    EpubStructure structure,
  ) async {
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    final strategiesUsed = <String>[];
    
    print('📄 开始内容提取，共${_strategies.length}种策略');
    
    for (int i = 0; i < _strategies.length; i++) {
      final strategy = _strategies[i];
      final strategyName = strategy.runtimeType.toString();
      
      try {
        print('   🔄 尝试策略${i + 1}: $strategyName');
        
        final result = await strategy.extractContent(archive, structure);
        strategiesUsed.add(strategyName);
        
        if (result.isValid) {
          print('   ✅ 策略${i + 1}成功，提取到${result.contentFiles.length}个内容文件');
          
          // 合并错误和警告
          errors.addAll(result.errors);
          warnings.addAll(result.warnings);
          
          return ContentExtractionResult(
            contentFiles: result.contentFiles,
            strategiesUsed: strategiesUsed,
            errors: errors,
            warnings: warnings,
            extractionMetadata: result.extractionMetadata,
          );
        } else {
          print('   ❌ 策略${i + 1}失败: ${result.errors.length}个错误');
          errors.addAll(result.errors);
          warnings.addAll(result.warnings);
        }
        
      } catch (e) {
        print('   💥 策略${i + 1}异常: $e');
        
        errors.add(EpubParsingError(
          level: EpubParsingErrorLevel.error,
          message: '内容提取策略失败: $strategyName - ${e.toString()}',
          location: strategyName,
          originalException: e is Exception ? e : Exception(e.toString()),
          timestamp: DateTime.now(),
        ));
        
        strategiesUsed.add('${strategyName}_failed');
      }
    }
    
    print('   ❌ 所有内容提取策略都失败了');
    
    return ContentExtractionResult(
      contentFiles: [],
      strategiesUsed: strategiesUsed,
      errors: errors,
      warnings: warnings,
      extractionMetadata: ContentExtractionMetadata.failed(),
    );
  }
}

/// 内容提取策略接口
abstract class ContentExtractionStrategy {
  final EpubParsingConfig config;
  
  const ContentExtractionStrategy(this.config);
  
  /// 提取内容
  Future<StrategyExtractionResult> extractContent(
    Archive archive, 
    EpubStructure structure,
  );
  
  /// 策略名称
  String get strategyName;
  
  /// 策略优先级（数字越小优先级越高）
  int get priority;
}

/// 基于Spine的标准提取策略
class SpineBasedStrategy extends ContentExtractionStrategy {
  const SpineBasedStrategy(super.config);
  
  @override
  String get strategyName => 'SpineBased';
  
  @override
  int get priority => 1;

  @override
  Future<StrategyExtractionResult> extractContent(
    Archive archive, 
    EpubStructure structure,
  ) async {
    final contentFiles = <EpubContentFile>[];
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    
    if (structure.spine.items.isEmpty) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: 'Spine为空，无法提取内容',
        timestamp: DateTime.now(),
      ));
      return StrategyExtractionResult(
        contentFiles: contentFiles,
        errors: errors,
        warnings: warnings,
        extractionMetadata: ContentExtractionMetadata.empty(),
      );
    }
    
    print('      📚 处理Spine，包含${structure.spine.items.length}个项目');
    
    final basePath = _getBasePath(structure.opfPath);
    int processedCount = 0;
    int skippedCount = 0;
    
    for (final spineItem in structure.spine.items) {
      try {
        // 查找对应的manifest项目
        final manifestItem = structure.manifest.findById(spineItem.idRef);
        if (manifestItem == null) {
          warnings.add(EpubParsingWarning(
            message: '在Manifest中找不到Spine项目: ${spineItem.idRef}',
            timestamp: DateTime.now(),
          ));
          skippedCount++;
          continue;
        }
        
        // 只处理HTML/XHTML内容
        if (!_isHtmlContent(manifestItem.mediaType)) {
          skippedCount++;
          continue;
        }
        
        // 构建完整路径
        final fullPath = _buildContentPath(basePath, manifestItem.href);
        
        // 从archive中读取文件内容
        final archiveFile = archive.findFile(fullPath);
        if (archiveFile == null) {
          warnings.add(EpubParsingWarning(
            message: '找不到内容文件: $fullPath',
            suggestion: '文件可能被移动或删除',
            location: fullPath,
            timestamp: DateTime.now(),
          ));
          skippedCount++;
          continue;
        }
        
        // 读取并处理内容，使用UTF-8解码
        final rawContent = utf8.decode(archiveFile.content as List<int>, allowMalformed: true);
        
        final contentFile = EpubContentFile(
          id: manifestItem.id,
          href: manifestItem.href,
          mediaType: manifestItem.mediaType,
          rawContent: rawContent,
          contentLength: rawContent.length,
          processingInfo: EpubContentProcessingInfo(
            strategy: strategyName,
            processingTime: Duration.zero, // 将在HTML处理阶段设置
            originalLength: rawContent.length,
            processedLength: 0, // 将在HTML处理阶段设置
            qualityScore: 1.0, // 初始质量分数
          ),
        );
        
        contentFiles.add(contentFile);
        processedCount++;
        
      } catch (e) {
        warnings.add(EpubParsingWarning(
          message: '处理Spine项目失败: ${spineItem.idRef} - ${e.toString()}',
          timestamp: DateTime.now(),
        ));
        skippedCount++;
      }
    }
    
    print('      ✅ Spine处理完成: $processedCount个成功, $skippedCount个跳过');
    
    final metadata = ContentExtractionMetadata(
      strategy: strategyName,
      totalFiles: structure.spine.items.length,
      processedFiles: processedCount,
      skippedFiles: skippedCount,
      totalSize: contentFiles.fold(0, (sum, file) => sum + (file.contentLength ?? 0)),
      processingTime: Duration.zero,
    );
    
    return StrategyExtractionResult(
      contentFiles: contentFiles,
      errors: errors,
      warnings: warnings,
      extractionMetadata: metadata,
    );
  }
  
  /// 判断是否为HTML内容
  bool _isHtmlContent(String mediaType) {
    return mediaType.contains('html') || 
           mediaType.contains('xhtml') ||
           mediaType == 'text/html' ||
           mediaType == 'application/xhtml+xml';
  }
  
  /// 获取基础路径
  String _getBasePath(String opfPath) {
    final parts = opfPath.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }
  
  /// 构建内容路径
  String _buildContentPath(String basePath, String href) {
    if (basePath.isEmpty) return href;
    return '$basePath/$href';
  }
}

/// 基于Manifest的备选策略
class ManifestBasedStrategy extends ContentExtractionStrategy {
  const ManifestBasedStrategy(super.config);
  
  @override
  String get strategyName => 'ManifestBased';
  
  @override
  int get priority => 2;

  @override
  Future<StrategyExtractionResult> extractContent(
    Archive archive, 
    EpubStructure structure,
  ) async {
    final contentFiles = <EpubContentFile>[];
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    
    print('      📄 处理Manifest，包含${structure.manifest.items.length}个项目');
    
    final htmlItems = structure.manifest.htmlItems;
    if (htmlItems.isEmpty) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: 'Manifest中没有HTML内容项目',
        timestamp: DateTime.now(),
      ));
      return StrategyExtractionResult(
        contentFiles: contentFiles,
        errors: errors,
        warnings: warnings,
        extractionMetadata: ContentExtractionMetadata.empty(),
      );
    }
    
    int processedCount = 0;
    int skippedCount = 0;
    
    for (final manifestItem in htmlItems) {
      try {
        // 从archive中读取文件内容
        final archiveFile = archive.findFile(manifestItem.href);
        if (archiveFile == null) {
          warnings.add(EpubParsingWarning(
            message: '找不到Manifest项目文件: ${manifestItem.href}',
            timestamp: DateTime.now(),
          ));
          skippedCount++;
          continue;
        }
        
        // 读取内容
        final rawContent = utf8.decode(archiveFile.content as List<int>, allowMalformed: true);
        
        final contentFile = EpubContentFile(
          id: manifestItem.id,
          href: manifestItem.href,
          mediaType: manifestItem.mediaType,
          rawContent: rawContent,
          contentLength: rawContent.length,
          processingInfo: EpubContentProcessingInfo(
            strategy: strategyName,
            processingTime: Duration.zero,
            originalLength: rawContent.length,
            processedLength: 0,
            qualityScore: 0.8, // Manifest策略质量分数稍低
          ),
        );
        
        contentFiles.add(contentFile);
        processedCount++;
        
      } catch (e) {
        warnings.add(EpubParsingWarning(
          message: '处理Manifest项目失败: ${manifestItem.id} - ${e.toString()}',
          timestamp: DateTime.now(),
        ));
        skippedCount++;
      }
    }
    
    print('      ✅ Manifest处理完成: $processedCount个成功, $skippedCount个跳过');
    
    final metadata = ContentExtractionMetadata(
      strategy: strategyName,
      totalFiles: htmlItems.length,
      processedFiles: processedCount,
      skippedFiles: skippedCount,
      totalSize: contentFiles.fold(0, (sum, file) => sum + (file.contentLength ?? 0)),
      processingTime: Duration.zero,
    );
    
    return StrategyExtractionResult(
      contentFiles: contentFiles,
      errors: errors,
      warnings: warnings,
      extractionMetadata: metadata,
    );
  }
}

/// 目录遍历策略
class DirectoryTraversalStrategy extends ContentExtractionStrategy {
  const DirectoryTraversalStrategy(super.config);
  
  @override
  String get strategyName => 'DirectoryTraversal';
  
  @override
  int get priority => 3;

  @override
  Future<StrategyExtractionResult> extractContent(
    Archive archive, 
    EpubStructure structure,
  ) async {
    final contentFiles = <EpubContentFile>[];
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    
    print('      📁 遍历目录寻找HTML文件');
    
    int processedCount = 0;
    int skippedCount = 0;
    
    for (final archiveFile in archive.files) {
      if (!archiveFile.isFile) continue;
      
      final fileName = archiveFile.name.toLowerCase();
      
      // 跳过META-INF目录
      if (archiveFile.name.startsWith('META-INF/')) continue;
      
      // 只处理HTML文件
      if (!_isHtmlFile(fileName)) continue;
      
      try {
        final rawContent = utf8.decode(archiveFile.content as List<int>, allowMalformed: true);
        
        final contentFile = EpubContentFile(
          id: 'dir_$processedCount',
          href: archiveFile.name,
          mediaType: _guessMediaType(fileName),
          rawContent: rawContent,
          contentLength: rawContent.length,
          processingInfo: EpubContentProcessingInfo(
            strategy: strategyName,
            processingTime: Duration.zero,
            originalLength: rawContent.length,
            processedLength: 0,
            qualityScore: 0.6, // 目录遍历策略质量分数较低
          ),
        );
        
        contentFiles.add(contentFile);
        processedCount++;
        
      } catch (e) {
        warnings.add(EpubParsingWarning(
          message: '处理目录文件失败: ${archiveFile.name} - ${e.toString()}',
          timestamp: DateTime.now(),
        ));
        skippedCount++;
      }
    }
    
    print('      ✅ 目录遍历完成: $processedCount个成功, $skippedCount个跳过');
    
    if (contentFiles.isEmpty) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: '目录遍历未找到任何HTML文件',
        timestamp: DateTime.now(),
      ));
    }
    
    final metadata = ContentExtractionMetadata(
      strategy: strategyName,
      totalFiles: archive.files.where((f) => f.isFile && _isHtmlFile(f.name.toLowerCase())).length,
      processedFiles: processedCount,
      skippedFiles: skippedCount,
      totalSize: contentFiles.fold(0, (sum, file) => sum + (file.contentLength ?? 0)),
      processingTime: Duration.zero,
    );
    
    return StrategyExtractionResult(
      contentFiles: contentFiles,
      errors: errors,
      warnings: warnings,
      extractionMetadata: metadata,
    );
  }
  
  /// 判断是否为HTML文件
  bool _isHtmlFile(String fileName) {
    return fileName.endsWith('.html') ||
           fileName.endsWith('.xhtml') ||
           fileName.endsWith('.htm');
  }
  
  /// 猜测媒体类型
  String _guessMediaType(String fileName) {
    if (fileName.endsWith('.xhtml')) {
      return 'application/xhtml+xml';
    }
    return 'text/html';
  }
}

/// 兜底策略
class FallbackStrategy extends ContentExtractionStrategy {
  const FallbackStrategy(super.config);
  
  @override
  String get strategyName => 'Fallback';
  
  @override
  int get priority => 4;

  @override
  Future<StrategyExtractionResult> extractContent(
    Archive archive, 
    EpubStructure structure,
  ) async {
    final contentFiles = <EpubContentFile>[];
    final warnings = <EpubParsingWarning>[];
    
    print('      🆘 使用兜底策略生成基本内容');
    
    // 生成基本的占位内容
    final placeholderContent = _generatePlaceholderContent(structure);
    
    final contentFile = EpubContentFile(
      id: 'fallback_content',
      href: 'fallback.html',
      mediaType: 'text/html',
      rawContent: placeholderContent,
      content: placeholderContent,
      contentLength: placeholderContent.length,
      processingInfo: EpubContentProcessingInfo(
        strategy: strategyName,
        processingTime: Duration.zero,
        originalLength: placeholderContent.length,
        processedLength: placeholderContent.length,
        qualityScore: 0.1, // 兜底策略质量分数很低
      ),
    );
    
    contentFiles.add(contentFile);
    
    warnings.add(EpubParsingWarning(
      message: '使用兜底策略生成内容',
      suggestion: '原始内容可能无法正确解析',
      timestamp: DateTime.now(),
    ));
    
    final metadata = ContentExtractionMetadata(
      strategy: strategyName,
      totalFiles: 1,
      processedFiles: 1,
      skippedFiles: 0,
      totalSize: placeholderContent.length,
      processingTime: Duration.zero,
    );
    
    return StrategyExtractionResult(
      contentFiles: contentFiles,
      errors: [],
      warnings: warnings,
      extractionMetadata: metadata,
    );
  }
  
  /// 生成占位内容
  String _generatePlaceholderContent(EpubStructure structure) {
    final title = structure.metadata.title;
    final author = structure.metadata.author ?? '未知作者';
    
    return '''
<html>
<head>
<title>$title</title>
</head>
<body>
<h1>EPUB内容加载失败</h1>

<h2>书籍信息</h2>
<p><strong>标题:</strong> $title</p>
<p><strong>作者:</strong> $author</p>

<h2>问题说明</h2>
<p>很抱歉，这个EPUB文件的内容无法正常解析。可能的原因包括：</p>
<ul>
<li>文件格式不标准或损坏</li>
<li>使用了不支持的EPUB功能</li>
<li>内部文件结构异常</li>
</ul>

<h2>建议</h2>
<ul>
<li>尝试使用其他EPUB文件</li>
<li>检查文件是否从可靠来源获得</li>
<li>联系开发者报告问题</li>
</ul>

<p><em>这是一个降级的阅读界面，基本的翻页和设置功能仍然可用。</em></p>
</body>
</html>
    ''';
  }
}

/// 内容提取结果
class ContentExtractionResult {
  final List<EpubContentFile> contentFiles;
  final List<String> strategiesUsed;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final ContentExtractionMetadata extractionMetadata;
  
  const ContentExtractionResult({
    required this.contentFiles,
    this.strategiesUsed = const [],
    this.errors = const [],
    this.warnings = const [],
    required this.extractionMetadata,
  });

  /// 是否有效（至少有一个内容文件）
  bool get isValid => contentFiles.isNotEmpty;
  
  /// 获取总内容大小
  int get totalContentSize => contentFiles.fold(0, (sum, file) => sum + (file.contentLength ?? 0));
}

/// 策略提取结果
class StrategyExtractionResult {
  final List<EpubContentFile> contentFiles;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final ContentExtractionMetadata extractionMetadata;
  
  const StrategyExtractionResult({
    required this.contentFiles,
    this.errors = const [],
    this.warnings = const [],
    required this.extractionMetadata,
  });

  /// 是否有效
  bool get isValid => contentFiles.isNotEmpty && !_hasFatalErrors;
  
  /// 是否有致命错误
  bool get _hasFatalErrors => errors.any((e) => e.level == EpubParsingErrorLevel.fatal);
}

/// 内容提取元数据
class ContentExtractionMetadata {
  final String strategy;
  final int totalFiles;
  final int processedFiles;
  final int skippedFiles;
  final int totalSize;
  final Duration processingTime;
  
  const ContentExtractionMetadata({
    required this.strategy,
    required this.totalFiles,
    required this.processedFiles,
    required this.skippedFiles,
    required this.totalSize,
    required this.processingTime,
  });

  factory ContentExtractionMetadata.empty() {
    return const ContentExtractionMetadata(
      strategy: 'none',
      totalFiles: 0,
      processedFiles: 0,
      skippedFiles: 0,
      totalSize: 0,
      processingTime: Duration.zero,
    );
  }
  
  factory ContentExtractionMetadata.failed() {
    return const ContentExtractionMetadata(
      strategy: 'failed',
      totalFiles: 0,
      processedFiles: 0,
      skippedFiles: 0,
      totalSize: 0,
      processingTime: Duration.zero,
    );
  }

  /// 成功率
  double get successRate => totalFiles > 0 ? processedFiles / totalFiles : 0.0;
  
  /// 格式化的文件大小
  String get formattedSize {
    if (totalSize < 1024) {
      return '${totalSize}B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
