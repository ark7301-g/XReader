import 'dart:async';
import 'models/epub_book.dart';
import 'epub_parser.dart';

/// HTML处理器
/// 
/// 负责处理从EPUB中提取的HTML内容，包括：
/// - 智能标签清理
/// - 文本结构保持
/// - HTML实体解码
/// - 内容质量评估
class HtmlProcessor {
  final EpubParsingConfig config;
  final List<HtmlProcessingFilter> _filters;
  
  HtmlProcessor(this.config) : _filters = [
    HtmlEntityDecoder(),
    ScriptStyleRemover(),
    StructurePreserver(config),
    TextNormalizer(),
    WhitespaceOptimizer(),
    QualityValidator(config),
  ];

  /// 处理内容文件列表
  Future<HtmlProcessingResult> processContent(List<EpubContentFile> contentFiles) async {
    final processedFiles = <EpubContentFile>[];
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    
    print('🧹 开始HTML内容处理，共${contentFiles.length}个文件');
    
    int processedCount = 0;
    int failedCount = 0;
    
    for (int i = 0; i < contentFiles.length; i++) {
      final contentFile = contentFiles[i];
      
      try {
        print('   📄 处理文件${i + 1}/${contentFiles.length}: ${contentFile.id}');
        
        final result = await _processContentFile(contentFile);
        
        if (result.isSuccess) {
          processedFiles.add(result.processedFile!);
          processedCount++;
          
          if (result.warnings.isNotEmpty) {
            warnings.addAll(result.warnings);
          }
        } else {
          failedCount++;
          errors.addAll(result.errors);
          warnings.addAll(result.warnings);
          
          // 添加原始文件作为降级处理
          processedFiles.add(contentFile);
        }
        
      } catch (e) {
        failedCount++;
        
        errors.add(EpubParsingError(
          level: EpubParsingErrorLevel.error,
          message: '处理HTML文件失败: ${contentFile.id} - ${e.toString()}',
          location: contentFile.href,
          originalException: e is Exception ? e : Exception(e.toString()),
          timestamp: DateTime.now(),
        ));
        
        print('   ❌ 处理失败: ${contentFile.id} - $e');
        
        // 添加原始文件作为降级处理
        processedFiles.add(contentFile);
      }
    }
    
    print('   ✅ HTML处理完成: $processedCount个成功, $failedCount个失败');
    
    return HtmlProcessingResult(
      contentFiles: processedFiles,
      errors: errors,
      warnings: warnings,
      processingMetadata: HtmlProcessingMetadata(
        totalFiles: contentFiles.length,
        processedFiles: processedCount,
        failedFiles: failedCount,
        totalOriginalSize: contentFiles.fold(0, (sum, file) => sum + (file.contentLength ?? 0)),
        totalProcessedSize: processedFiles.fold(0, (sum, file) => sum + (file.content?.length ?? 0)),
        processingTime: Duration.zero, // TODO: 实际计算时间
      ),
    );
  }

  /// 处理单个内容文件
  Future<SingleFileProcessingResult> _processContentFile(EpubContentFile contentFile) async {
    final stopwatch = Stopwatch()..start();
    final warnings = <EpubParsingWarning>[];
    final errors = <EpubParsingError>[];
    
    if (contentFile.rawContent == null || contentFile.rawContent!.isEmpty) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: '内容文件为空或未读取',
        location: contentFile.href,
        timestamp: DateTime.now(),
      ));
      
      return SingleFileProcessingResult(
        isSuccess: false,
        errors: errors,
        warnings: warnings,
      );
    }
    
    try {
      String processedContent = contentFile.rawContent!;
      final appliedFilters = <String>[];
      
      // 依次应用所有过滤器
      for (final filter in _filters) {
        try {
          final filterResult = await filter.process(processedContent, contentFile);
          processedContent = filterResult.processedContent;
          appliedFilters.add(filter.runtimeType.toString());
          
          if (filterResult.warnings.isNotEmpty) {
            warnings.addAll(filterResult.warnings);
          }
          
          if (filterResult.errors.isNotEmpty) {
            errors.addAll(filterResult.errors);
          }
          
        } catch (e) {
          warnings.add(EpubParsingWarning(
            message: 'HTML过滤器失败: ${filter.runtimeType} - ${e.toString()}',
            location: contentFile.href,
            timestamp: DateTime.now(),
          ));
        }
      }
      
      stopwatch.stop();
      
      // 评估处理质量
      final qualityScore = _evaluateQuality(
        original: contentFile.rawContent!,
        processed: processedContent,
      );
      
      // 如果质量太低，使用简单清理作为降级
      if (qualityScore < config.minQualityScore) {
        warnings.add(EpubParsingWarning(
          message: '内容质量评分过低 ($qualityScore)，使用简单清理',
          location: contentFile.href,
          timestamp: DateTime.now(),
        ));
        
        processedContent = _simpleCleanup(contentFile.rawContent!);
        appliedFilters.add('SimpleCleanup');
      }
      
      final processedFile = EpubContentFile(
        id: contentFile.id,
        href: contentFile.href,
        mediaType: contentFile.mediaType,
        content: processedContent,
        rawContent: contentFile.rawContent,
        contentLength: contentFile.contentLength,
        processingInfo: EpubContentProcessingInfo(
          strategy: contentFile.processingInfo.strategy,
          processingTime: stopwatch.elapsed,
          originalLength: contentFile.rawContent!.length,
          processedLength: processedContent.length,
          appliedFilters: appliedFilters,
          qualityScore: qualityScore,
        ),
      );
      
      print('      ✅ 处理完成 (${stopwatch.elapsed.inMilliseconds}ms)');
      print('         原始长度: ${contentFile.rawContent!.length}');
      print('         处理后长度: ${processedContent.length}');
      print('         质量评分: ${qualityScore.toStringAsFixed(2)}');
      print('         应用过滤器: ${appliedFilters.join(', ')}');
      
      return SingleFileProcessingResult(
        isSuccess: true,
        processedFile: processedFile,
        errors: errors,
        warnings: warnings,
      );
      
    } catch (e) {
      stopwatch.stop();
      
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.error,
        message: 'HTML处理过程中发生错误: ${e.toString()}',
        location: contentFile.href,
        originalException: e is Exception ? e : Exception(e.toString()),
        timestamp: DateTime.now(),
      ));
      
      return SingleFileProcessingResult(
        isSuccess: false,
        errors: errors,
        warnings: warnings,
      );
    }
  }

  /// 评估内容质量
  double _evaluateQuality({required String original, required String processed}) {
    if (original.isEmpty) return 0.0;
    if (processed.isEmpty) return 0.0;
    
    // 基本指标
    final lengthRatio = processed.length / original.length;
    
    // 检查是否保留了基本的文本内容
    final originalTextLength = _extractTextLength(original);
    final processedTextLength = _extractTextLength(processed);
    
    final textRetentionRatio = originalTextLength > 0 ? processedTextLength / originalTextLength : 0.0;
    
    // 检查是否有明显的内容结构
    final hasStructure = _hasContentStructure(processed);
    
    // 综合评分
    double score = 0.0;
    score += lengthRatio.clamp(0.0, 1.0) * 0.3; // 长度保留率权重30%
    score += textRetentionRatio.clamp(0.0, 1.0) * 0.5; // 文本保留率权重50%
    score += hasStructure ? 0.2 : 0.0; // 结构完整性权重20%
    
    return score.clamp(0.0, 1.0);
  }
  
  /// 提取文本长度（去除HTML标签）
  int _extractTextLength(String content) {
    final textOnly = content
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return textOnly.length;
  }
  
  /// 检查是否有内容结构
  bool _hasContentStructure(String content) {
    // 检查是否有段落、标题或其他结构元素
    return content.contains('\n\n') || // 有段落分隔
           content.contains('。') || // 有句号
           content.contains('？') || // 有问号
           content.contains('！') || // 有感叹号
           content.length > 100; // 内容足够长
  }
  
  /// 简单清理（降级处理）
  String _simpleCleanup(String htmlContent) {
    return htmlContent
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// HTML处理过滤器接口
abstract class HtmlProcessingFilter {
  /// 处理内容
  Future<FilterProcessingResult> process(String content, EpubContentFile contentFile);
  
  /// 过滤器名称
  String get filterName;
  
  /// 过滤器优先级
  int get priority;
}

/// HTML实体解码器
class HtmlEntityDecoder extends HtmlProcessingFilter {
  @override
  String get filterName => 'HtmlEntityDecoder';
  
  @override
  int get priority => 1;

  @override
  Future<FilterProcessingResult> process(String content, EpubContentFile contentFile) async {
    final processedContent = _decodeHtmlEntities(content);
    
    return FilterProcessingResult(
      processedContent: processedContent,
      errors: [],
      warnings: [],
    );
  }
  
  /// 解码HTML实体
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        .replaceAll('&deg;', '°')
        .replaceAll('&plusmn;', '±')
        .replaceAll('&micro;', 'μ')
        .replaceAll('&para;', '¶')
        .replaceAll('&sect;', '§')
        .replaceAll('&middot;', '·')
        .replaceAll('&laquo;', '«')
        .replaceAll('&raquo;', '»')
        // 数字实体解码
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
          final code = int.tryParse(match.group(1)!);
          return code != null ? String.fromCharCode(code) : match.group(0)!;
        })
        // 十六进制实体解码
        .replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
          final code = int.tryParse(match.group(1)!, radix: 16);
          return code != null ? String.fromCharCode(code) : match.group(0)!;
        });
  }
}

/// 脚本和样式移除器
class ScriptStyleRemover extends HtmlProcessingFilter {
  @override
  String get filterName => 'ScriptStyleRemover';
  
  @override
  int get priority => 2;

  @override
  Future<FilterProcessingResult> process(String content, EpubContentFile contentFile) async {
    String processedContent = content;
    
    // 移除脚本
    processedContent = processedContent.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false),
      '',
    );
    
    // 移除样式
    processedContent = processedContent.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false),
      '',
    );
    
    // 移除注释
    processedContent = processedContent.replaceAll(
      RegExp(r'<!--.*?-->', dotAll: true),
      '',
    );
    
    return FilterProcessingResult(
      processedContent: processedContent,
      errors: [],
      warnings: [],
    );
  }
}

/// 结构保持器
class StructurePreserver extends HtmlProcessingFilter {
  final EpubParsingConfig config;
  
  StructurePreserver(this.config);
  
  @override
  String get filterName => 'StructurePreserver';
  
  @override
  int get priority => 3;

  @override
  Future<FilterProcessingResult> process(String content, EpubContentFile contentFile) async {
    if (!config.preserveFormatting) {
      // 如果不保持格式，直接移除所有标签
      final processedContent = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
      return FilterProcessingResult(
        processedContent: processedContent,
        errors: [],
        warnings: [],
      );
    }
    
    String processedContent = content;
    
    // 处理块级元素（保持段落结构）
    processedContent = processedContent
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<hr[^>]*>', caseSensitive: false), '\n───────────\n');
    
    // 处理标题元素
    for (int i = 1; i <= 6; i++) {
      processedContent = processedContent
          .replaceAll(RegExp(r'<h$i[^>]*>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'</h$i>', caseSensitive: false), '\n');
    }
    
    // 处理列表
    processedContent = processedContent
        .replaceAll(RegExp(r'<ul[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ul>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<ol[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ol>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '');
    
    // 处理表格（简化）
    processedContent = processedContent
        .replaceAll(RegExp(r'<table[^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</table>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<tr[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</tr>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<t[hd][^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</t[hd]>', caseSensitive: false), '\t');
    
    // 移除剩余的行内元素标签
    processedContent = processedContent
        .replaceAll(RegExp(r'<(strong|b)[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</(strong|b)>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<(em|i)[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</(em|i)>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<(u|span|a)[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</(u|span|a)>', caseSensitive: false), '');
    
    // 移除所有剩余的HTML标签
    processedContent = processedContent.replaceAll(RegExp(r'<[^>]*>'), '');
    
    return FilterProcessingResult(
      processedContent: processedContent,
      errors: [],
      warnings: [],
    );
  }
}

/// 文本标准化器
class TextNormalizer extends HtmlProcessingFilter {
  @override
  String get filterName => 'TextNormalizer';
  
  @override
  int get priority => 4;

  @override
  Future<FilterProcessingResult> process(String content, EpubContentFile contentFile) async {
    String processedContent = content;
    
    // 标准化引号
    processedContent = processedContent
        .replaceAll(RegExp(r'[""]'), '"')
        .replaceAll(RegExp(r'['']'), "'");
    
    // 标准化破折号
    processedContent = processedContent
        .replaceAll('—', '——')
        .replaceAll('–', '-');
    
    // 标准化省略号
    processedContent = processedContent
        .replaceAll('…', '......')
        .replaceAll(RegExp(r'\.{3,}'), '......');
    
    return FilterProcessingResult(
      processedContent: processedContent,
      errors: [],
      warnings: [],
    );
  }
}

/// 空白字符优化器
class WhitespaceOptimizer extends HtmlProcessingFilter {
  @override
  String get filterName => 'WhitespaceOptimizer';
  
  @override
  int get priority => 5;

  @override
  Future<FilterProcessingResult> process(String content, EpubContentFile contentFile) async {
    String processedContent = content;
    
    // 标准化空白字符
    processedContent = processedContent
        .replaceAll(RegExp(r'[ \t]+'), ' ')  // 多个空格和制表符变一个空格
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')  // 多个换行变两个
        .replaceAll(RegExp(r'^\s+', multiLine: true), '')  // 删除行首空白
        .replaceAll(RegExp(r'\s+$', multiLine: true), '')  // 删除行尾空白
        .trim(); // 删除首尾空白
    
    return FilterProcessingResult(
      processedContent: processedContent,
      errors: [],
      warnings: [],
    );
  }
}

/// 质量验证器
class QualityValidator extends HtmlProcessingFilter {
  final EpubParsingConfig config;
  
  QualityValidator(this.config);
  
  @override
  String get filterName => 'QualityValidator';
  
  @override
  int get priority => 6;

  @override
  Future<FilterProcessingResult> process(String content, EpubContentFile contentFile) async {
    final warnings = <EpubParsingWarning>[];
    
    // 检查内容长度
    if (content.length < 20) {
      warnings.add(EpubParsingWarning(
        message: '处理后内容过短 (${content.length}字符)',
        suggestion: '可能需要检查HTML处理逻辑',
        location: contentFile.href,
        timestamp: DateTime.now(),
      ));
    }
    
    // 检查是否还有HTML标签残留
    final remainingTags = RegExp(r'<[^>]+>').allMatches(content).length;
    if (remainingTags > 0) {
      warnings.add(EpubParsingWarning(
        message: '发现$remainingTags个未处理的HTML标签',
        suggestion: '可能需要改进HTML清理逻辑',
        location: contentFile.href,
        timestamp: DateTime.now(),
      ));
    }
    
    // 检查是否有过多的空白
    final whiteSpaceRatio = content.isEmpty ? 0.0 : 
        (content.length - content.replaceAll(RegExp(r'\s'), '').length) / content.length;
    
    if (whiteSpaceRatio > 0.5) {
      warnings.add(EpubParsingWarning(
        message: '空白字符比例过高 (${(whiteSpaceRatio * 100).toStringAsFixed(1)}%)',
        suggestion: '可能需要优化空白字符处理',
        location: contentFile.href,
        timestamp: DateTime.now(),
      ));
    }
    
    return FilterProcessingResult(
      processedContent: content,
      errors: [],
      warnings: warnings,
    );
  }
}

/// HTML处理结果
class HtmlProcessingResult {
  final List<EpubContentFile> contentFiles;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final HtmlProcessingMetadata processingMetadata;
  
  const HtmlProcessingResult({
    required this.contentFiles,
    this.errors = const [],
    this.warnings = const [],
    required this.processingMetadata,
  });
}

/// 单文件处理结果
class SingleFileProcessingResult {
  final bool isSuccess;
  final EpubContentFile? processedFile;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  
  const SingleFileProcessingResult({
    required this.isSuccess,
    this.processedFile,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// 过滤器处理结果
class FilterProcessingResult {
  final String processedContent;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  
  const FilterProcessingResult({
    required this.processedContent,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// HTML处理元数据
class HtmlProcessingMetadata {
  final int totalFiles;
  final int processedFiles;
  final int failedFiles;
  final int totalOriginalSize;
  final int totalProcessedSize;
  final Duration processingTime;
  
  const HtmlProcessingMetadata({
    required this.totalFiles,
    required this.processedFiles,
    required this.failedFiles,
    required this.totalOriginalSize,
    required this.totalProcessedSize,
    required this.processingTime,
  });

  /// 成功率
  double get successRate => totalFiles > 0 ? processedFiles / totalFiles : 0.0;
  
  /// 内容保留率
  double get retentionRate => totalOriginalSize > 0 ? totalProcessedSize / totalOriginalSize : 0.0;
  
  /// 处理摘要
  String get summary => '处理了$totalFiles个文件，成功$processedFiles个，失败$failedFiles个';
}
