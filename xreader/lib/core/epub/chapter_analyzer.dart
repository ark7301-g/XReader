import 'dart:async';
import 'models/epub_book.dart';
import 'epub_parser.dart';

/// 章节分析器
/// 
/// 负责分析EPUB文件的章节结构，采用多源信息合并的方式：
/// 1. TOC分析器 - 从导航文件提取章节信息
/// 2. 标题分析器 - 从HTML内容中识别标题
/// 3. Spine分析器 - 基于Spine顺序生成章节
/// 4. 智能合并器 - 合并多源信息
class ChapterAnalyzer {
  final EpubParsingConfig config;
  final List<ChapterAnalysisStrategy> _analyzers;
  
  ChapterAnalyzer(this.config) : _analyzers = [
    TocAnalyzer(config),
    HeadingAnalyzer(config),
    SpineAnalyzer(config),
  ];

  /// 分析章节结构
  Future<List<EpubChapterModel>> analyzeChapters(
    EpubStructure structure,
    List<EpubContentFile> contentFiles,
  ) async {
    print('📖 开始章节结构分析');
    
    final analysisResults = <ChapterAnalysisResult>[];
    
    // 运行所有分析器
    for (final analyzer in _analyzers) {
      try {
        print('   🔍 运行${analyzer.analyzerName}分析器');
        
        final result = await analyzer.analyzeChapters(structure, contentFiles);
        analysisResults.add(result);
        
        print('      ✅ 找到${result.chapters.length}个章节');
        
      } catch (e) {
        print('      ❌ 分析器失败: $e');
        
        analysisResults.add(ChapterAnalysisResult(
          analyzerName: analyzer.analyzerName,
          chapters: [],
          confidence: 0.0,
          errors: [
            EpubParsingError(
              level: EpubParsingErrorLevel.error,
              message: '章节分析器失败: ${analyzer.analyzerName} - ${e.toString()}',
              timestamp: DateTime.now(),
            ),
          ],
        ));
      }
    }
    
    // 合并分析结果
    print('   🔄 合并章节分析结果');
    final mergedChapters = await _mergeAnalysisResults(
      analysisResults, 
      contentFiles.length,
    );
    
    // 分配页码
    print('   📄 分配页码');
    final chaptersWithPages = _assignPageNumbers(mergedChapters);
    
    print('   ✅ 章节分析完成，最终生成${chaptersWithPages.length}个章节');
    
    return chaptersWithPages;
  }

  /// 合并分析结果
  Future<List<EpubChapterModel>> _mergeAnalysisResults(
    List<ChapterAnalysisResult> results,
    int totalContentFiles,
  ) async {
    if (results.isEmpty) {
      return _generateFallbackChapters(totalContentFiles);
    }
    
    // 按置信度排序
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // 选择最佳结果
    final bestResult = results.first;
    
    if (bestResult.chapters.isNotEmpty && bestResult.confidence > 0.5) {
      print('      使用${bestResult.analyzerName}的结果 (置信度: ${bestResult.confidence.toStringAsFixed(2)})');
      return bestResult.chapters;
    }
    
    // 如果最佳结果不够好，尝试合并多个结果
    print('      尝试合并多个分析结果');
    
    final mergedChapters = <EpubChapterModel>[];
    final usedTitles = <String>{};
    
    // 从所有结果中收集章节
    for (final result in results) {
      for (final chapter in result.chapters) {
        // 避免重复的章节标题
        if (!usedTitles.contains(chapter.title)) {
          mergedChapters.add(chapter);
          usedTitles.add(chapter.title);
        }
      }
    }
    
    if (mergedChapters.isNotEmpty) {
      print('      合并结果：${mergedChapters.length}个章节');
      return mergedChapters;
    }
    
    // 如果所有分析都失败，生成默认章节
    print('      所有分析失败，生成默认章节结构');
    return _generateFallbackChapters(totalContentFiles);
  }

  /// 生成默认章节结构
  List<EpubChapterModel> _generateFallbackChapters(int totalContentFiles) {
    if (totalContentFiles == 0) {
      return [
        const EpubChapterModel(
          id: 'fallback_chapter',
          title: '文档内容',
          startPage: 0,
          endPage: 0,
          level: 1,
        ),
      ];
    }
    
    // 为每个内容文件生成一个章节
    final chapters = <EpubChapterModel>[];
    for (int i = 0; i < totalContentFiles; i++) {
      chapters.add(EpubChapterModel(
        id: 'content_file_$i',
        title: '第${i + 1}部分',
        startPage: 0, // 将在分配页码时设置
        endPage: 0,   // 将在分配页码时设置
        level: 1,
      ));
    }
    
    return chapters;
  }

  /// 分配页码
  List<EpubChapterModel> _assignPageNumbers(List<EpubChapterModel> chapters) {
    if (chapters.isEmpty) return chapters;
    
    const estimatedPagesPerChapter = 10;
    int currentPage = 0;
    
    final chaptersWithPages = <EpubChapterModel>[];
    
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final startPage = currentPage;
      final endPage = currentPage + estimatedPagesPerChapter - 1;
      
      chaptersWithPages.add(EpubChapterModel(
        id: chapter.id,
        title: chapter.title,
        level: chapter.level,
        href: chapter.href,
        startPage: startPage,
        endPage: endPage,
        subChapters: chapter.subChapters,
        anchor: chapter.anchor,
        contentFile: chapter.contentFile,
      ));
      
      currentPage += estimatedPagesPerChapter;
    }
    
    return chaptersWithPages;
  }
}

/// 章节分析策略接口
abstract class ChapterAnalysisStrategy {
  final EpubParsingConfig config;
  
  const ChapterAnalysisStrategy(this.config);
  
  /// 分析章节
  Future<ChapterAnalysisResult> analyzeChapters(
    EpubStructure structure,
    List<EpubContentFile> contentFiles,
  );
  
  /// 分析器名称
  String get analyzerName;
  
  /// 置信度（0.0-1.0）
  double get baseConfidence;
}

/// TOC分析器
class TocAnalyzer extends ChapterAnalysisStrategy {
  const TocAnalyzer(super.config);
  
  @override
  String get analyzerName => 'TOC';
  
  @override
  double get baseConfidence => 0.9;

  @override
  Future<ChapterAnalysisResult> analyzeChapters(
    EpubStructure structure,
    List<EpubContentFile> contentFiles,
  ) async {
    final chapters = <EpubChapterModel>[];
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    
    if (structure.navigation == null) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: '没有找到导航信息',
        timestamp: DateTime.now(),
      ));
      
      return ChapterAnalysisResult(
        analyzerName: analyzerName,
        chapters: chapters,
        confidence: 0.0,
        errors: errors,
        warnings: warnings,
      );
    }
    
    final navigation = structure.navigation!;
    
    if (navigation.points.isEmpty) {
      warnings.add(EpubParsingWarning(
        message: '导航文档中没有章节信息',
        timestamp: DateTime.now(),
      ));
      
      return ChapterAnalysisResult(
        analyzerName: analyzerName,
        chapters: chapters,
        confidence: 0.0,
        errors: errors,
        warnings: warnings,
      );
    }
    
    print('      处理${navigation.points.length}个导航点');
    
    int chapterIndex = 0;
    for (final navPoint in navigation.points) {
      final chapter = _convertNavPointToChapter(navPoint, chapterIndex);
      if (chapter != null) {
        chapters.add(chapter);
        chapterIndex++;
      }
    }
    
    // 处理子章节
    final flatChapters = _flattenChapters(chapters);
    
    double confidence = baseConfidence;
    
    // 根据章节质量调整置信度
    if (chapters.isEmpty) {
      confidence = 0.0;
    } else if (chapters.length < 3) {
      confidence *= 0.7; // 章节太少，降低置信度
    } else if (_hasGoodChapterTitles(chapters)) {
      confidence = (confidence * 1.1).clamp(0.0, 1.0); // 有好的标题，提高置信度
    }
    
    return ChapterAnalysisResult(
      analyzerName: analyzerName,
      chapters: flatChapters,
      confidence: confidence,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// 将导航点转换为章节
  EpubChapterModel? _convertNavPointToChapter(EpubNavigationPoint navPoint, int index) {
    if (navPoint.label.trim().isEmpty) return null;
    
    return EpubChapterModel(
      id: navPoint.id.isNotEmpty ? navPoint.id : 'nav_chapter_$index',
      title: navPoint.label.trim(),
      level: navPoint.level,
      href: navPoint.href,
      startPage: 0, // 稍后分配
      endPage: 0,   // 稍后分配
      subChapters: navPoint.children
          .map((child) => _convertNavPointToChapter(child, index))
          .where((chapter) => chapter != null)
          .cast<EpubChapterModel>()
          .toList(),
    );
  }
  
  /// 扁平化章节列表
  List<EpubChapterModel> _flattenChapters(List<EpubChapterModel> chapters) {
    final flatChapters = <EpubChapterModel>[];
    
    void addChapter(EpubChapterModel chapter) {
      flatChapters.add(chapter);
      for (final subChapter in chapter.subChapters) {
        addChapter(subChapter);
      }
    }
    
    for (final chapter in chapters) {
      addChapter(chapter);
    }
    
    return flatChapters;
  }
  
  /// 检查是否有好的章节标题
  bool _hasGoodChapterTitles(List<EpubChapterModel> chapters) {
    if (chapters.isEmpty) return false;
    
    int goodTitles = 0;
    for (final chapter in chapters) {
      final title = chapter.title.trim();
      if (title.length > 3 && 
          !title.startsWith('第') && 
          !title.startsWith('Chapter') &&
          !RegExp(r'^\d+$').hasMatch(title)) {
        goodTitles++;
      }
    }
    
    return goodTitles / chapters.length > 0.6; // 60%以上是好标题
  }
}

/// 标题分析器
class HeadingAnalyzer extends ChapterAnalysisStrategy {
  const HeadingAnalyzer(super.config);
  
  @override
  String get analyzerName => 'Heading';
  
  @override
  double get baseConfidence => 0.7;

  @override
  Future<ChapterAnalysisResult> analyzeChapters(
    EpubStructure structure,
    List<EpubContentFile> contentFiles,
  ) async {
    final chapters = <EpubChapterModel>[];
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    
    if (contentFiles.isEmpty) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: '没有内容文件可供分析',
        timestamp: DateTime.now(),
      ));
      
      return ChapterAnalysisResult(
        analyzerName: analyzerName,
        chapters: chapters,
        confidence: 0.0,
        errors: errors,
        warnings: warnings,
      );
    }
    
    print('      分析${contentFiles.length}个内容文件中的标题');
    
    int chapterIndex = 0;
    
    for (final contentFile in contentFiles) {
      if (contentFile.rawContent == null) continue;
      
      final headings = _extractHeadings(contentFile.rawContent!);
      
      for (final heading in headings) {
        chapters.add(EpubChapterModel(
          id: 'heading_chapter_$chapterIndex',
          title: heading.text,
          level: heading.level,
          href: contentFile.href,
          startPage: 0, // 稍后分配
          endPage: 0,   // 稍后分配
          contentFile: contentFile,
        ));
        chapterIndex++;
      }
    }
    
    double confidence = baseConfidence;
    
    if (chapters.isEmpty) {
      confidence = 0.0;
      warnings.add(EpubParsingWarning(
        message: '在内容中未找到标题元素',
        timestamp: DateTime.now(),
      ));
    } else if (chapters.length > contentFiles.length * 5) {
      // 如果标题太多，可能不是真正的章节标题
      confidence *= 0.5;
      warnings.add(EpubParsingWarning(
        message: '发现过多标题 (${chapters.length})，可能包含非章节标题',
        timestamp: DateTime.now(),
      ));
    }
    
    return ChapterAnalysisResult(
      analyzerName: analyzerName,
      chapters: chapters,
      confidence: confidence,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// 提取标题
  List<HeadingInfo> _extractHeadings(String htmlContent) {
    final headings = <HeadingInfo>[];
    
    // 匹配h1-h6标签
    final headingPattern = RegExp(
      r'<h([1-6])[^>]*>(.*?)</h[1-6]>',
      caseSensitive: false,
      dotAll: true,
    );
    
    final matches = headingPattern.allMatches(htmlContent);
    
    for (final match in matches) {
      final level = int.tryParse(match.group(1) ?? '') ?? 1;
      final rawText = match.group(2) ?? '';
      
      // 清理HTML标签
      final cleanText = rawText
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      if (cleanText.isNotEmpty && cleanText.length > 1) {
        headings.add(HeadingInfo(
          level: level,
          text: cleanText,
          position: match.start,
        ));
      }
    }
    
    return headings;
  }
}

/// Spine分析器
class SpineAnalyzer extends ChapterAnalysisStrategy {
  const SpineAnalyzer(super.config);
  
  @override
  String get analyzerName => 'Spine';
  
  @override
  double get baseConfidence => 0.5;

  @override
  Future<ChapterAnalysisResult> analyzeChapters(
    EpubStructure structure,
    List<EpubContentFile> contentFiles,
  ) async {
    final chapters = <EpubChapterModel>[];
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    
    if (structure.spine.items.isEmpty) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: 'Spine为空，无法生成章节',
        timestamp: DateTime.now(),
      ));
      
      return ChapterAnalysisResult(
        analyzerName: analyzerName,
        chapters: chapters,
        confidence: 0.0,
        errors: errors,
        warnings: warnings,
      );
    }
    
    print('      基于Spine生成${structure.spine.items.length}个章节');
    
    for (int i = 0; i < structure.spine.items.length; i++) {
      final spineItem = structure.spine.items[i];
      
      // 查找对应的manifest项目
      final manifestItem = structure.manifest.findById(spineItem.idRef);
      
      String chapterTitle = _generateChapterTitle(manifestItem, i + 1);
      
      chapters.add(EpubChapterModel(
        id: spineItem.idRef,
        title: chapterTitle,
        level: 1,
        href: manifestItem?.href,
        startPage: 0, // 稍后分配
        endPage: 0,   // 稍后分配
      ));
    }
    
    double confidence = baseConfidence;
    
    // 如果章节数量合理，稍微提高置信度
    if (chapters.length >= 3 && chapters.length <= 50) {
      confidence *= 1.1;
    }
    
    return ChapterAnalysisResult(
      analyzerName: analyzerName,
      chapters: chapters,
      confidence: confidence.clamp(0.0, 1.0),
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// 生成章节标题
  String _generateChapterTitle(EpubManifestItem? manifestItem, int index) {
    if (manifestItem?.href != null) {
      // 尝试从文件名生成标题
      final fileName = manifestItem!.href.split('/').last;
      final baseName = fileName.split('.').first;
      
      if (baseName.isNotEmpty && baseName != manifestItem.id) {
        return _formatChapterTitle(baseName, index);
      }
    }
    
    return '第$index章';
  }
  
  /// 格式化章节标题
  String _formatChapterTitle(String rawTitle, int index) {
    String title = rawTitle
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    
    if (title.isEmpty) {
      return '第$index章';
    }
    
    // 如果是数字开头，可能是章节号
    if (RegExp(r'^\d+').hasMatch(title)) {
      return '第$title章';
    }
    
    // 首字母大写
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title;
  }
}

/// 章节分析结果
class ChapterAnalysisResult {
  final String analyzerName;
  final List<EpubChapterModel> chapters;
  final double confidence; // 0.0-1.0
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  
  const ChapterAnalysisResult({
    required this.analyzerName,
    required this.chapters,
    required this.confidence,
    this.errors = const [],
    this.warnings = const [],
  });

  /// 是否成功
  bool get isSuccessful => chapters.isNotEmpty && confidence > 0.0;
  
  /// 获取结果摘要
  String get summary => '$analyzerName: ${chapters.length}个章节 (置信度: ${confidence.toStringAsFixed(2)})';
}

/// 标题信息
class HeadingInfo {
  final int level;
  final String text;
  final int position;
  
  const HeadingInfo({
    required this.level,
    required this.text,
    required this.position,
  });
}
