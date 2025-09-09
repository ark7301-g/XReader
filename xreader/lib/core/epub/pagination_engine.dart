import 'dart:async';
import 'dart:math' as math;
import 'models/epub_book.dart';
import 'epub_parser.dart';

/// 分页引擎
/// 
/// 负责将处理后的EPUB内容进行智能分页，特点：
/// - 自适应分页算法
/// - 保持段落完整性  
/// - 避免孤行和寡行
/// - 页面长度动态优化
class PaginationEngine {
  final EpubParsingConfig config;
  
  PaginationEngine(this.config);

  /// 对内容进行分页
  Future<PaginationResult> paginateContent(
    List<EpubContentFile> contentFiles,
    List<EpubChapterModel> chapters,
  ) async {
    print('📄 开始智能分页处理');
    
    if (contentFiles.isEmpty) {
      return PaginationResult(
        pages: ['内容为空'],
        totalPages: 1,
        averagePageLength: 0,
        metadata: PaginationMetadata.empty(),
      );
    }
    
    final stopwatch = Stopwatch()..start();
    final allPages = <String>[];
    final pageMetadata = <PageMetadata>[];
    int totalCharacters = 0;
    
    print('   处理${contentFiles.length}个内容文件');
    
    // 用于跟踪每个文件的更新版本
    final List<EpubContentFile> updatedContentFiles = [];
    
    for (int i = 0; i < contentFiles.length; i++) {
      final contentFile = contentFiles[i];
      
      if (contentFile.content == null || contentFile.content!.isEmpty) {
        print('     ⚠️  跳过空内容文件: ${contentFile.id}');
        // 保持原文件但确保pages为空
        updatedContentFiles.add(contentFile);
        continue;
      }
      
      print('     📖 分页文件${i + 1}/${contentFiles.length}: ${contentFile.id}');
      
      final filePages = await _paginateContentFile(contentFile, allPages.length);
      allPages.addAll(filePages.pages);
      pageMetadata.addAll(filePages.metadata);
      totalCharacters += contentFile.content!.length;
      
      // 创建带有分页内容的新EpubContentFile
      final updatedContentFile = EpubContentFile(
        id: contentFile.id,
        href: contentFile.href,
        mediaType: contentFile.mediaType,
        content: contentFile.content,
        rawContent: contentFile.rawContent,
        contentLength: contentFile.contentLength,
        pages: filePages.pages,  // 设置分页内容
        processingInfo: contentFile.processingInfo,
      );
      updatedContentFiles.add(updatedContentFile);
      
      print('       ✅ 生成${filePages.pages.length}页');
    }
    
    // 更新原始contentFiles列表
    contentFiles.clear();
    contentFiles.addAll(updatedContentFiles);
    
    stopwatch.stop();
    
    // 计算统计信息
    final averagePageLength = allPages.isNotEmpty 
        ? allPages.map((p) => p.length).reduce((a, b) => a + b) ~/ allPages.length
        : 0;
    
    final metadata = PaginationMetadata(
      totalContentFiles: contentFiles.length,
      totalCharacters: totalCharacters,
      averagePageLength: averagePageLength,
      processingTime: stopwatch.elapsed,
      paginationStrategy: 'adaptive',
      qualityScore: _calculatePaginationQuality(allPages, pageMetadata),
    );
    
    print('   ✅ 分页完成');
    print('     📊 总页数: ${allPages.length}');
    print('     📏 平均页长: $averagePageLength字符');
    print('     ⏱️  处理时间: ${stopwatch.elapsed.inMilliseconds}ms');
    print('     🎯 质量评分: ${metadata.qualityScore.toStringAsFixed(2)}');
    
    return PaginationResult(
      pages: allPages,
      totalPages: allPages.length,
      averagePageLength: averagePageLength,
      metadata: metadata,
      pageMetadata: pageMetadata,
    );
  }

  /// 对单个内容文件进行分页
  Future<FilePaginationResult> _paginateContentFile(
    EpubContentFile contentFile, 
    int startPageIndex,
  ) async {
    final content = contentFile.content!;
    final strategy = _selectPaginationStrategy(content);
    
    return await strategy.paginate(content, contentFile, startPageIndex);
  }

  /// 选择分页策略
  PaginationStrategy _selectPaginationStrategy(String content) {
    // 根据内容特点选择最适合的分页策略
    
    if (content.length <= config.maxCharsPerPage) {
      // 内容很短，直接作为一页
      return SinglePageStrategy(config);
    }
    
    // 检查是否有明显的段落结构
    final paragraphCount = '\n\n'.allMatches(content).length;
    final averageParagraphLength = paragraphCount > 0 ? content.length / paragraphCount : content.length;
    
    if (paragraphCount > 0 && averageParagraphLength < config.maxCharsPerPage * 2) {
      // 有良好的段落结构，使用段落分页
      return ParagraphBasedStrategy(config);
    }
    
    // 内容长且结构不明显，使用句子分页
    if (_hasSentenceStructure(content)) {
      return SentenceBasedStrategy(config);
    }
    
    // 最后降级为强制分页
    return ForceBreakStrategy(config);
  }

  /// 检查是否有句子结构
  bool _hasSentenceStructure(String content) {
    final sentenceEnders = ['。', '！', '？', '.', '!', '?'];
    int sentenceCount = 0;
    
    for (final ender in sentenceEnders) {
      sentenceCount += ender.allMatches(content).length;
    }
    
    // 如果有合理数量的句子结束符，认为有句子结构
    return sentenceCount > content.length / 500; // 大约每500字符一个句子
  }

  /// 计算分页质量
  double _calculatePaginationQuality(List<String> pages, List<PageMetadata> metadata) {
    if (pages.isEmpty) return 0.0;
    
    double qualityScore = 1.0;
    
    // 1. 页面长度一致性评分
    final lengths = pages.map((p) => p.length).toList();
    final averageLength = lengths.reduce((a, b) => a + b) / lengths.length;
    final lengthVariance = lengths.map((l) => math.pow(l - averageLength, 2)).reduce((a, b) => a + b) / lengths.length;
    final lengthConsistency = 1.0 - (math.sqrt(lengthVariance) / averageLength).clamp(0.0, 1.0);
    
    qualityScore *= lengthConsistency * 0.3; // 30%权重
    
    // 2. 目标长度达成率
    final targetLength = config.targetCharsPerPage.toDouble();
    final targetAchievement = 1.0 - (averageLength - targetLength).abs() / targetLength;
    qualityScore *= targetAchievement.clamp(0.0, 1.0) * 0.4; // 40%权重
    
    // 3. 分页策略质量（基于metadata）
    double strategyQuality = 0.8; // 默认质量
    if (metadata.isNotEmpty) {
      final strategyQualities = metadata.map((m) => m.qualityScore);
      strategyQuality = strategyQualities.reduce((a, b) => a + b) / strategyQualities.length;
    }
    qualityScore *= strategyQuality * 0.3; // 30%权重
    
    return qualityScore.clamp(0.0, 1.0);
  }
}

/// 分页策略接口
abstract class PaginationStrategy {
  final EpubParsingConfig config;
  
  const PaginationStrategy(this.config);
  
  /// 执行分页
  Future<FilePaginationResult> paginate(
    String content, 
    EpubContentFile contentFile, 
    int startPageIndex,
  );
  
  /// 策略名称
  String get strategyName;
  
  /// 格式化页面内容
  String formatPageContent(String content, int pageNumber, String? chapterTitle) {
    final formattedContent = content.trim();
    
    if (formattedContent.isEmpty) {
      return '(空页面)';
    }
    
    return formattedContent;
  }
}

/// 单页策略（内容很短时使用）
class SinglePageStrategy extends PaginationStrategy {
  const SinglePageStrategy(super.config);
  
  @override
  String get strategyName => 'SinglePage';

  @override
  Future<FilePaginationResult> paginate(
    String content, 
    EpubContentFile contentFile, 
    int startPageIndex,
  ) async {
    final page = formatPageContent(content, startPageIndex + 1, null);
    
    return FilePaginationResult(
      pages: [page],
      metadata: [
        PageMetadata(
          pageIndex: startPageIndex,
          characterCount: content.length,
          strategy: strategyName,
          qualityScore: 1.0,
          hasLineBreaks: false,
        ),
      ],
    );
  }
}

/// 段落分页策略
class ParagraphBasedStrategy extends PaginationStrategy {
  const ParagraphBasedStrategy(super.config);
  
  @override
  String get strategyName => 'ParagraphBased';

  @override
  Future<FilePaginationResult> paginate(
    String content, 
    EpubContentFile contentFile, 
    int startPageIndex,
  ) async {
    final pages = <String>[];
    final metadata = <PageMetadata>[];
    
    // 按双换行符分割段落
    final paragraphs = content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    if (paragraphs.isEmpty) {
      return const FilePaginationResult(pages: [], metadata: []);
    }
    
    String currentPageContent = '';
    int currentPageIndex = startPageIndex;
    
    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      final potentialContent = currentPageContent.isEmpty 
          ? paragraph 
          : '$currentPageContent\n\n$paragraph';
      
      if (potentialContent.length > config.maxCharsPerPage && currentPageContent.isNotEmpty) {
        // 当前页已满，保存并开始新页
        final page = formatPageContent(currentPageContent, currentPageIndex + 1, null);
        pages.add(page);
        
        metadata.add(PageMetadata(
          pageIndex: currentPageIndex,
          characterCount: currentPageContent.length,
          strategy: strategyName,
          qualityScore: _calculatePageQuality(currentPageContent),
          hasLineBreaks: false,
        ));
        
        currentPageIndex++;
        currentPageContent = paragraph;
      } else {
        currentPageContent = potentialContent;
      }
    }
    
    // 保存最后一页
    if (currentPageContent.isNotEmpty) {
      final page = formatPageContent(currentPageContent, currentPageIndex + 1, null);
      pages.add(page);
      
      metadata.add(PageMetadata(
        pageIndex: currentPageIndex,
        characterCount: currentPageContent.length,
        strategy: strategyName,
        qualityScore: _calculatePageQuality(currentPageContent),
        hasLineBreaks: false,
      ));
    }
    
    return FilePaginationResult(pages: pages, metadata: metadata);
  }
  
  /// 计算页面质量
  double _calculatePageQuality(String pageContent) {
    final length = pageContent.length;
    final targetLength = config.targetCharsPerPage;
    
    // 基于长度的质量评分
    if (length < config.minCharsPerPage) {
      return 0.3; // 太短
    } else if (length > config.maxCharsPerPage) {
      return 0.5; // 太长
    } else {
      // 接近目标长度的质量更高
      final deviation = (length - targetLength).abs() / targetLength;
      return (1.0 - deviation).clamp(0.0, 1.0);
    }
  }
}

/// 句子分页策略
class SentenceBasedStrategy extends PaginationStrategy {
  const SentenceBasedStrategy(super.config);
  
  @override
  String get strategyName => 'SentenceBased';

  @override
  Future<FilePaginationResult> paginate(
    String content, 
    EpubContentFile contentFile, 
    int startPageIndex,
  ) async {
    final pages = <String>[];
    final metadata = <PageMetadata>[];
    
    // 按句子分割（简化版本）
    final sentences = _splitIntoSentences(content);
    
    if (sentences.isEmpty) {
      return const FilePaginationResult(pages: [], metadata: []);
    }
    
    String currentPageContent = '';
    int currentPageIndex = startPageIndex;
    
    for (final sentence in sentences) {
      final potentialContent = currentPageContent.isEmpty 
          ? sentence 
          : '$currentPageContent $sentence';
      
      if (potentialContent.length > config.maxCharsPerPage && currentPageContent.isNotEmpty) {
        // 当前页已满，保存并开始新页
        final page = formatPageContent(currentPageContent, currentPageIndex + 1, null);
        pages.add(page);
        
        metadata.add(PageMetadata(
          pageIndex: currentPageIndex,
          characterCount: currentPageContent.length,
          strategy: strategyName,
          qualityScore: _calculateSentencePageQuality(currentPageContent),
          hasLineBreaks: false,
        ));
        
        currentPageIndex++;
        currentPageContent = sentence;
      } else {
        currentPageContent = potentialContent;
      }
    }
    
    // 保存最后一页
    if (currentPageContent.isNotEmpty) {
      final page = formatPageContent(currentPageContent, currentPageIndex + 1, null);
      pages.add(page);
      
      metadata.add(PageMetadata(
        pageIndex: currentPageIndex,
        characterCount: currentPageContent.length,
        strategy: strategyName,
        qualityScore: _calculateSentencePageQuality(currentPageContent),
        hasLineBreaks: false,
      ));
    }
    
    return FilePaginationResult(pages: pages, metadata: metadata);
  }
  
  /// 分割句子
  List<String> _splitIntoSentences(String content) {
    final sentences = <String>[];
    
    // 简化的句子分割，基于常见的句子结束符
    final sentenceEnders = ['。', '！', '？', '.', '!', '?'];
    
    int start = 0;
    for (int i = 0; i < content.length; i++) {
      if (sentenceEnders.contains(content[i])) {
        final sentence = content.substring(start, i + 1).trim();
        if (sentence.isNotEmpty) {
          sentences.add(sentence);
        }
        start = i + 1;
      }
    }
    
    // 处理最后一个句子（如果没有结束符）
    if (start < content.length) {
      final sentence = content.substring(start).trim();
      if (sentence.isNotEmpty) {
        sentences.add(sentence);
      }
    }
    
    return sentences;
  }
  
  /// 计算句子页面质量
  double _calculateSentencePageQuality(String pageContent) {
    final length = pageContent.length;
    final targetLength = config.targetCharsPerPage;
    
    // 句子分页的质量评分稍低，因为可能会在句子中间断开
    double baseQuality = 0.7;
    
    if (length >= config.minCharsPerPage && length <= config.maxCharsPerPage) {
      final deviation = (length - targetLength).abs() / targetLength;
      baseQuality = (0.7 + 0.3 * (1.0 - deviation)).clamp(0.0, 1.0);
    }
    
    return baseQuality;
  }
}

/// 强制分页策略（最后的降级方案）
class ForceBreakStrategy extends PaginationStrategy {
  const ForceBreakStrategy(super.config);
  
  @override
  String get strategyName => 'ForceBreak';

  @override
  Future<FilePaginationResult> paginate(
    String content, 
    EpubContentFile contentFile, 
    int startPageIndex,
  ) async {
    final pages = <String>[];
    final metadata = <PageMetadata>[];
    
    int currentPageIndex = startPageIndex;
    int charsPerPage = config.targetCharsPerPage;
    
    for (int i = 0; i < content.length; i += charsPerPage) {
      final endIndex = math.min(i + charsPerPage, content.length);
      String pageContent = content.substring(i, endIndex);
      
      // 尝试在合适的位置分页（避免在单词中间）
      if (endIndex < content.length) {
        final lastSpaceIndex = pageContent.lastIndexOf(' ');
        final lastNewlineIndex = pageContent.lastIndexOf('\n');
        final breakIndex = math.max(lastSpaceIndex, lastNewlineIndex);
        
        if (breakIndex > charsPerPage * 0.8) { // 至少保持80%的页面利用率
          pageContent = content.substring(i, i + breakIndex);
          i = i + breakIndex - charsPerPage; // 调整下次开始位置
        }
      }
      
      final page = formatPageContent(pageContent, currentPageIndex + 1, null);
      pages.add(page);
      
      metadata.add(PageMetadata(
        pageIndex: currentPageIndex,
        characterCount: pageContent.length,
        strategy: strategyName,
        qualityScore: 0.4, // 强制分页质量较低
        hasLineBreaks: true,
      ));
      
      currentPageIndex++;
    }
    
    return FilePaginationResult(pages: pages, metadata: metadata);
  }
}

/// 分页结果
class PaginationResult {
  final List<String> pages;
  final int totalPages;
  final int averagePageLength;
  final PaginationMetadata metadata;
  final List<PageMetadata> pageMetadata;
  
  const PaginationResult({
    required this.pages,
    required this.totalPages,
    required this.averagePageLength,
    required this.metadata,
    this.pageMetadata = const [],
  });

  /// 获取指定页面内容
  String? getPage(int pageIndex) {
    return pageIndex >= 0 && pageIndex < pages.length ? pages[pageIndex] : null;
  }
  
  /// 获取页面范围
  List<String> getPageRange(int startIndex, int endIndex) {
    final start = math.max(0, startIndex);
    final end = math.min(pages.length, endIndex + 1);
    return pages.sublist(start, end);
  }
}

/// 文件分页结果
class FilePaginationResult {
  final List<String> pages;
  final List<PageMetadata> metadata;
  
  const FilePaginationResult({
    required this.pages,
    required this.metadata,
  });
}

/// 分页元数据
class PaginationMetadata {
  final int totalContentFiles;
  final int totalCharacters;
  final int averagePageLength;
  final Duration processingTime;
  final String paginationStrategy;
  final double qualityScore;
  
  const PaginationMetadata({
    required this.totalContentFiles,
    required this.totalCharacters,
    required this.averagePageLength,
    required this.processingTime,
    required this.paginationStrategy,
    required this.qualityScore,
  });

  factory PaginationMetadata.empty() {
    return const PaginationMetadata(
      totalContentFiles: 0,
      totalCharacters: 0,
      averagePageLength: 0,
      processingTime: Duration.zero,
      paginationStrategy: 'none',
      qualityScore: 0.0,
    );
  }

  /// 获取处理速度（字符/秒）
  double get processingSpeed {
    if (processingTime.inMilliseconds == 0) return 0.0;
    return totalCharacters / (processingTime.inMilliseconds / 1000.0);
  }
  
  /// 获取格式化的处理速度
  String get formattedProcessingSpeed {
    final speed = processingSpeed;
    if (speed < 1000) {
      return '${speed.toStringAsFixed(0)} 字符/秒';
    } else {
      return '${(speed / 1000).toStringAsFixed(1)}K 字符/秒';
    }
  }
}

/// 页面元数据
class PageMetadata {
  final int pageIndex;
  final int characterCount;
  final String strategy;
  final double qualityScore;
  final bool hasLineBreaks;
  final String? chapterTitle;
  
  const PageMetadata({
    required this.pageIndex,
    required this.characterCount,
    required this.strategy,
    required this.qualityScore,
    this.hasLineBreaks = false,
    this.chapterTitle,
  });

  /// 是否为高质量页面
  bool get isHighQuality => qualityScore >= 0.7;
  
  /// 页面大小类别
  String get sizeCategory {
    if (characterCount < 800) return '短页';
    if (characterCount < 1500) return '标准页';
    if (characterCount < 2000) return '长页';
    return '超长页';
  }
}
