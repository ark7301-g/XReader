import 'dart:io';
import 'package:epubx/epubx.dart';
import '../providers/reader_state.dart';
import '../providers/reader_provider.dart';

class EpubReaderService {
  EpubBook? _epubBook;
  List<String>? _pageContents;
  List<Chapter>? _chapters;

  /// 加载EPUB书籍 (增强版，带详细日志)
  Future<EpubReaderResult> loadBook(String filePath) async {
    print('📚 EpubReaderService: 开始加载EPUB书籍');
    print('   文件路径: $filePath');
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final fileSize = await file.length();
      print('   文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      final bytes = await file.readAsBytes();
      print('   字节读取完成: ${bytes.length} bytes');
      
      // 尝试解析EPUB，增加错误处理
      try {
        print('🔄 开始解析EPUB结构...');
        _epubBook = await EpubReader.readBook(bytes);
        print('✅ EPUB解析成功！');
      } catch (epubError) {
        print('❌ EPUB标准解析失败: $epubError');
        print('🔧 错误类型: ${epubError.runtimeType}');
        // 尝试创建一个基本的结果
        return _createFallbackResult(filePath);
      }

      if (_epubBook == null) {
        print('❌ EPUB对象为空');
        return _createFallbackResult(filePath);
      }

      print('✅ EPUB对象创建成功，开始深度分析...');
      
      // 详细分析EPUB结构
      await _debugEpubStructureInReader();

      print('🔍 开始提取章节信息...');
      // 提取章节信息（增强处理）
      _chapters = await _extractChaptersEnhanced();
      print('✅ 章节提取完成: ${_chapters?.length ?? 0} 个章节');
      
      print('🔍 开始提取和分页内容...');
      // 提取和分页内容（增强处理）
      _pageContents = await _extractAndPaginateContentEnhanced();
      print('✅ 内容提取完成: ${_pageContents?.length ?? 0} 页');

      print('🔍 尝试提取封面...');
      final coverPath = await _extractCoverImage();
      print('封面提取结果: ${coverPath ?? "无封面"}');

      final result = EpubReaderResult(
        pages: _pageContents ?? [],
        chapters: _chapters ?? [],
        coverImagePath: coverPath,
      );

      print('🎉 EPUB内容提取完全成功!');
      print('   📄 总页数: ${result.pages.length}');
      print('   📖 章节数: ${result.chapters.length}');
      print('   🖼️  封面: ${result.coverImagePath != null ? "有" : "无"}');
      
      return result;
    } catch (e) {
      print('❌ EPUB加载最终失败: $e');
      print('🔧 错误堆栈: ${StackTrace.current}');
      return _createFallbackResult(filePath);
    }
  }

  /// 创建降级结果
  EpubReaderResult _createFallbackResult(String filePath) {
    print('创建EPUB降级结果');
    
    _chapters = [
      const Chapter(
        id: 'fallback_chapter',
        title: '文档内容',
        startPage: 0,
        endPage: 0,
        href: '',
        level: 1,
      )
    ];
    
    _pageContents = [
      '''
EPUB文件加载

文件：${filePath.split('/').last}

很抱歉，这个EPUB文件无法正常解析。
可能的原因：
• 文件格式不标准
• 文件损坏
• 不支持的EPUB版本

您可以尝试：
• 使用其他EPUB文件
• 检查文件是否完整
• 联系开发者报告问题

这是一个简化的阅读界面，
部分功能可能无法正常使用。
      '''
    ];

    return EpubReaderResult(
      pages: _pageContents!,
      chapters: _chapters!,
      coverImagePath: null,
    );
  }

  /// 详细分析EPUB结构（在阅读器中）
  Future<void> _debugEpubStructureInReader() async {
    try {
      print('📋 阅读器中的EPUB结构分析:');
      
      if (_epubBook == null) {
        print('❌ EPUB对象为空');
        return;
      }
      
      // 基本信息
      print('   📖 标题: ${_epubBook!.Title ?? "无"}');
      print('   👤 作者: ${_epubBook!.Author ?? "无"}');
      print('   👥 作者列表: ${_epubBook!.AuthorList ?? "无"}');
      
      // Schema分析
      final schema = _epubBook!.Schema;
      if (schema != null) {
        print('   📄 Schema存在');
        
        // Package分析
        final package = schema.Package;
        if (package != null) {
          print('   📦 Package存在');
          
          // Spine分析（重要：决定阅读顺序）
          final spine = package.Spine;
          if (spine?.Items != null) {
            print('   📚 Spine项目数: ${spine!.Items!.length}');
            for (int i = 0; i < spine.Items!.length && i < 5; i++) {
              final item = spine.Items![i];
              print('      Spine[$i]: ${item.IdRef} (Linear: ${item.IsLinear})');
            }
          }
          
          // Manifest分析（包含所有文件）
          final manifest = package.Manifest;
          if (manifest?.Items != null) {
            print('   📄 Manifest项目数: ${manifest!.Items!.length}');
            
            // 统计文件类型
            int htmlCount = 0, imageCount = 0, cssCount = 0, ncxCount = 0;
            for (final item in manifest.Items!) {
              final mediaType = item.MediaType?.toLowerCase() ?? '';
              if (mediaType.contains('html') || mediaType.contains('xhtml')) {
                htmlCount++;
              } else if (mediaType.contains('image')) {
                imageCount++;
              } else if (mediaType.contains('css')) {
                cssCount++;
              } else if (mediaType.contains('ncx')) {
                ncxCount++;
              }
            }
            
            print('      HTML/XHTML文件: $htmlCount');
            print('      图片文件: $imageCount');
            print('      CSS文件: $cssCount');
            print('      NCX文件: $ncxCount');
          }
        }
      }
      
      // Content分析
      if (_epubBook!.Content != null) {
        print('   📁 Content存在');
        print('      Content类型: ${_epubBook!.Content.runtimeType}');
        
        try {
          final content = _epubBook!.Content;
          
          // 分析Html内容
          if (content?.Html != null) {
            final htmlFiles = content!.Html!;
            print('      Html文件数: ${htmlFiles.length}');
            
            int count = 0;
            for (final entry in htmlFiles.entries) {
              if (count < 3) {
                final key = entry.key;
                final value = entry.value;
                final contentLength = value.Content?.length ?? 0;
                print('      Html[$count]: $key');
                print('         类型: ${value.ContentType}');
                print('         大小: $contentLength 字符');
                if (contentLength > 0 && contentLength < 500) {
                  final preview = value.Content!.length > 100 
                      ? '${value.Content!.substring(0, 100)}...'
                      : value.Content!;
                  print('         预览: ${preview.replaceAll('\n', '\\n')}');
                }
                count++;
              }
            }
          }
          
          // 分析Images内容
          if (content?.Images != null) {
            final imageFiles = content!.Images!;
            print('      图片文件数: ${imageFiles.length}');
          }
          
          // 分析Css内容
          if (content?.Css != null) {
            final cssFiles = content!.Css!;
            print('      CSS文件数: ${cssFiles.length}');
          }
          
        } catch (e) {
          print('      Content分析错误: $e');
        }
      }
      
    } catch (e) {
      print('❌ 阅读器EPUB结构分析失败: $e');
    }
  }

  /// 尝试提取封面图片
  Future<String?> _extractCoverImage() async {
    try {
      if (_epubBook?.Content == null) {
        print('   无Content，跳过封面提取');
        return null;
      }
      
      print('   开始查找封面图片...');
      
      final content = _epubBook!.Content;
      String? coverImageKey;
      
      // 查找Images中的封面
      if (content?.Images != null) {
        final imageFiles = content!.Images!;
        print('   在${imageFiles.length}个图片文件中查找封面...');
        
        // 策略1: 查找明确标记为封面的图片
        for (final entry in imageFiles.entries) {
          final key = entry.key;
          final fileName = key.toLowerCase();
          
          if (fileName.contains('cover') || fileName.contains('front')) {
            coverImageKey = key;
            print('   找到封面候选: $key (策略1: 文件名匹配)');
            break;
          }
        }
        
        // 策略2: 如果没找到，使用第一个图片
        if (coverImageKey == null && imageFiles.isNotEmpty) {
          final firstEntry = imageFiles.entries.first;
          coverImageKey = firstEntry.key;
          print('   找到图片候选: $coverImageKey (策略2: 第一个图片)');
        }
      }
      
      if (coverImageKey != null) {
        print('   ✅ 选定封面: $coverImageKey');
        return coverImageKey;
      } else {
        print('   ⚠️  未找到合适的封面图片');
      }
    } catch (e) {
      print('❌ 提取封面失败: $e');
    }
    return null;
  }

  /// 提取章节信息（增强版本）
  Future<List<Chapter>> _extractChaptersEnhanced() async {
    if (_epubBook == null) return [];

    try {
      // 优先尝试从TOC(目录)获取章节信息
      final tocChapters = await _extractFromTOC();
      if (tocChapters.isNotEmpty) {
        print('从TOC提取到${tocChapters.length}个章节');
        return _assignPageNumbers(tocChapters);
      }

      // 回退到从Navigation Document获取
      final navChapters = await _extractFromNavigation();
      if (navChapters.isNotEmpty) {
        print('从Navigation提取到${navChapters.length}个章节');
        return _assignPageNumbers(navChapters);
      }

      // 最后回退到从Spine生成章节
      return await _extractFromSpine();
    } catch (e) {
      print('章节提取失败: $e');
      return await _extractFromSpine(); // 降级处理
    }
  }

  /// 从TOC提取章节
  Future<List<Chapter>> _extractFromTOC() async {
    final chapters = <Chapter>[];
    
    try {
      final navigation = _epubBook?.Schema?.Navigation;
      if (navigation != null) {
        print('📍 开始从Navigation提取章节信息');
        
        // 尝试从NavMap获取章节
        if (navigation.NavMap?.Points != null) {
          final navPoints = navigation.NavMap!.Points!;
          print('   找到${navPoints.length}个导航点');
          
          for (int i = 0; i < navPoints.length; i++) {
            final navPoint = navPoints[i];
            final chapter = _createChapterFromNavPoint(navPoint, i);
            if (chapter != null) {
              chapters.add(chapter);
              print('   ✅ 提取章节: ${chapter.title}');
            }
          }
        }
        
        // 如果Navigation没有足够信息，尝试从其他地方获取
        if (chapters.isEmpty && navigation.DocTitle != null) {
          print('   💡 尝试从DocTitle构建简单章节结构');
          // DocTitle是一个对象，尝试提取其文本内容
          String docTitleText = '文档标题';
          try {
            if (navigation.DocTitle!.toString().isNotEmpty) {
              docTitleText = navigation.DocTitle!.toString();
      }
    } catch (e) {
            print('   ⚠️  无法提取DocTitle文本: $e');
          }
          chapters.add(Chapter(
            id: 'doc_title',
            title: docTitleText,
            startPage: 0,
            endPage: 0,
            href: '',
            level: 1,
          ));
        }
      }
    } catch (e) {
      print('❌ TOC提取失败: $e');
    }

    return chapters;
  }
  
  /// 从NavPoint创建章节对象
  Chapter? _createChapterFromNavPoint(dynamic navPoint, int index) {
    try {
      // 获取章节标题
      String title = 'Chapter ${index + 1}';
      if (navPoint.NavigationLabels?.isNotEmpty == true) {
        final label = navPoint.NavigationLabels!.first;
        if (label.Text?.isNotEmpty == true) {
          title = label.Text!;
        }
      }
      
      // 获取章节链接
      String? href;
      if (navPoint.Content?.Source != null) {
        href = navPoint.Content!.Source!;
      }
      
      // 获取播放顺序（用于确定层级）
      int level = 1;
      if (navPoint.PlayOrder != null) {
        level = navPoint.PlayOrder! > 0 ? 1 : 2; // 简化的层级判断
      }
      
      return Chapter(
        id: 'nav_$index',
        title: title,
        startPage: 0, // 稍后分配
        endPage: 0,   // 稍后分配
        href: href,
        level: level,
      );
    } catch (e) {
      print('   ❌ NavPoint解析失败: $e');
      return null;
    }
  }

  /// 从Navigation Document提取章节
  Future<List<Chapter>> _extractFromNavigation() async {
    final chapters = <Chapter>[];
    
    try {
      // 暂时简化导航文件查找
      // 后续可以根据实际的epubx API进行调整
    } catch (e) {
      print('Navigation提取失败: $e');
    }

    return chapters;
  }

  /// 从Spine提取章节（降级方案）
  Future<List<Chapter>> _extractFromSpine() async {
    final chapters = <Chapter>[];
    
    try {
      final spineItems = _epubBook?.Schema?.Package?.Spine?.Items;
      if (spineItems != null && spineItems.isNotEmpty) {
        print('从Spine提取${spineItems.length}个章节');
        
        for (int i = 0; i < spineItems.length; i++) {
          final spineItem = spineItems[i];
          
          // 尝试获取更好的章节标题
          String chapterTitle = _getChapterTitle(spineItem, i + 1);
          
          chapters.add(Chapter(
            id: spineItem.IdRef ?? 'chapter_${i + 1}',
            title: chapterTitle,
            startPage: 0, // 稍后分配
            endPage: 0,   // 稍后分配
            href: spineItem.IdRef,
            level: 1,
          ));
        }
      }
    } catch (e) {
      print('Spine提取失败: $e');
    }

    return chapters;
  }

  /// 获取章节标题
  String _getChapterTitle(dynamic spineItem, int index) {
    try {
      // 尝试从manifest获取标题
      final idRef = spineItem.IdRef;
      if (idRef != null) {
        final manifest = _epubBook?.Schema?.Package?.Manifest?.Items;
        if (manifest != null) {
          for (final item in manifest) {
            if (item.Id == idRef) {
              final href = item.Href;
              if (href != null) {
                // 从文件名推断标题
                final fileName = href.split('/').last.split('.').first;
                if (fileName.isNotEmpty && fileName != idRef) {
                  return _formatChapterTitle(fileName, index);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('获取章节标题失败: $e');
    }
    
    return '第$index章';
  }

  /// 格式化章节标题
  String _formatChapterTitle(String rawTitle, int index) {
    // 清理和格式化标题
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
    
    return title;
  }

  /// 为章节分配页码
  List<Chapter> _assignPageNumbers(List<Chapter> chapters) {
    int currentPage = 0;
    const pagesPerChapter = 10; // 估算每章页数
    
    for (int i = 0; i < chapters.length; i++) {
      chapters[i] = Chapter(
        id: chapters[i].id,
        title: chapters[i].title,
        startPage: currentPage,
        endPage: currentPage + pagesPerChapter - 1,
        href: chapters[i].href,
        level: chapters[i].level,
      );
      currentPage += pagesPerChapter;
    }
    
    return chapters;
  }

  /// 提取和分页内容（增强版）
  Future<List<String>> _extractAndPaginateContentEnhanced() async {
    if (_epubBook == null) return [];
    
    try {
      print('开始提取EPUB内容...');
      
      // 尝试提取真实内容
      final realContent = await _extractRealContent();
      if (realContent.isNotEmpty) {
        print('成功提取到真实内容，开始分页...');
        return _paginateContent(realContent);
      }
      
      // 降级到生成示例内容
      print('无法提取真实内容，使用示例内容');
      return _generateSampleContent();
      
    } catch (e) {
      print('内容提取出错: $e');
      return _generateFallbackContent();
    }
  }

  /// 提取真实EPUB内容
  Future<List<String>> _extractRealContent() async {
    final contents = <String>[];
    
    try {
      final spineItems = _epubBook?.Schema?.Package?.Spine?.Items;
      if (spineItems == null) return contents;
      
      for (final spineItem in spineItems) {
        final content = await _extractChapterContent(spineItem);
        if (content.isNotEmpty) {
          contents.add(content);
        }
      }
    } catch (e) {
      print('提取真实内容失败: $e');
    }
    
    return contents;
  }

  /// 提取单个章节内容（真实提取）
  Future<String> _extractChapterContent(dynamic spineItem) async {
    try {
      final idRef = spineItem.IdRef;
      if (idRef == null) {
        print('   章节IdRef为空');
        return '';
      }
      
      print('   🔍 提取章节内容: $idRef');
      
      // 从manifest中找到对应的文件信息
      final manifest = _epubBook?.Schema?.Package?.Manifest;
      if (manifest?.Items == null) {
        print('   ❌ Manifest不存在或为空');
        return _generateChapterPlaceholder(idRef);
      }
      
      // 找到对应的manifest项
      String? href;
      String? mediaType;
      for (final item in manifest!.Items!) {
        if (item.Id == idRef) {
          href = item.Href;
          mediaType = item.MediaType;
          print('   ✅ 找到manifest项: $href ($mediaType)');
          break;
        }
      }
      
      if (href == null) {
        print('   ❌ 未找到对应的href');
        return _generateChapterPlaceholder(idRef);
      }
      
      // 从Content中获取实际内容
      if (_epubBook?.Content == null) {
        print('   ❌ Content为空');
        return _generateChapterPlaceholder(idRef);
      }
      
      // 改进的内容提取策略
      String? actualContent = await _extractContentByHref(href);
      
      if (actualContent != null && actualContent.isNotEmpty) {
        print('   ✅ 成功提取内容: ${actualContent.length} 字符');
        
        // 改进的HTML清理
        final cleanedContent = _cleanHtmlContentEnhanced(actualContent);
        print('   ✅ 内容清理完成: ${cleanedContent.length} 字符');
        
        if (cleanedContent.isNotEmpty) {
          return cleanedContent;
        }
      }
      
      print('   ⚠️  未能提取到有效内容，使用占位符');
      return _generateChapterPlaceholder(idRef);
      
    } catch (e) {
      final safeIdRef = spineItem?.IdRef ?? 'unknown';
      print('   ❌ 提取章节内容失败: $e');
      return _generateChapterPlaceholder(safeIdRef);
    }
  }

  /// 生成章节占位内容
  String _generateChapterPlaceholder(String idRef) {
    return '''
章节内容

章节ID: $idRef

这是一个EPUB章节的内容预览。
由于技术限制，当前版本暂时无法
完全解析所有EPUB文件的内容。

正在改进中的功能：
• 完整的HTML内容解析
• 图片和样式支持
• 更准确的文本提取

感谢您的理解！

═══════════════════
    ''';
  }

  /// 改进的内容提取方法
  Future<String?> _extractContentByHref(String href) async {
      final content = _epubBook!.Content;
      
    if (content?.Html == null) {
      print('   ❌ Html content为空');
      return null;
    }
    
        final htmlFiles = content!.Html!;
        print('   🔍 在${htmlFiles.length}个Html文件中查找: $href');
    
    // 显示所有可用的key用于调试
    print('   📋 可用的HTML文件:');
    for (final key in htmlFiles.keys) {
      print('      - $key');
    }
    
    String? actualContent;
    String? matchedKey;
        
        // 策略1: 完全匹配
        if (htmlFiles.containsKey(href)) {
          actualContent = htmlFiles[href]?.Content;
          matchedKey = href;
          print('   ✅ 策略1成功: 完全匹配 $href');
        }
        
    // 策略2: 查找包含href的键（双向匹配）
        if (actualContent == null) {
          for (final key in htmlFiles.keys) {
        if (key.contains(href) || href.contains(key.split('/').last)) {
              actualContent = htmlFiles[key]?.Content;
              matchedKey = key;
              print('   ✅ 策略2成功: 部分匹配 $key');
              break;
            }
          }
        }
        
    // 策略3: 文件名匹配（忽略路径）
        if (actualContent == null) {
      final targetFileName = href.split('/').last.toLowerCase();
          for (final key in htmlFiles.keys) {
        final keyFileName = key.split('/').last.toLowerCase();
        if (keyFileName == targetFileName) {
              actualContent = htmlFiles[key]?.Content;
              matchedKey = key;
              print('   ✅ 策略3成功: 文件名匹配 $key');
              break;
            }
          }
        }
        
    // 策略4: 文件名去扩展名匹配
        if (actualContent == null) {
      final targetBaseName = href.split('/').last.toLowerCase().replaceAll(RegExp(r'\.[^.]*$'), '');
          for (final key in htmlFiles.keys) {
        final keyBaseName = key.split('/').last.toLowerCase().replaceAll(RegExp(r'\.[^.]*$'), '');
        if (keyBaseName == targetBaseName) {
              actualContent = htmlFiles[key]?.Content;
              matchedKey = key;
          print('   ✅ 策略4成功: 基本名匹配 $key');
              break;
            }
          }
        }
    
    // 策略5: 如果前面都失败，尝试模糊匹配
    if (actualContent == null && htmlFiles.isNotEmpty) {
      final sortedKeys = htmlFiles.keys.toList()..sort();
      final firstKey = sortedKeys.first;
      actualContent = htmlFiles[firstKey]?.Content;
      matchedKey = firstKey;
      print('   ⚠️  策略5: 使用第一个可用文件 $firstKey');
    }
    
    if (matchedKey != null) {
      print('   📄 最终选择: $matchedKey');
    }
    
    return actualContent;
  }
  
  /// 改进的HTML内容清理
  String _cleanHtmlContentEnhanced(String htmlContent) {
    try {
      print('   🧹 开始增强HTML清理: ${htmlContent.length} 字符');
      
      if (htmlContent.trim().isEmpty) {
        print('   ⚠️  HTML内容为空');
        return '';
      }
      
      String cleanContent = htmlContent;
      
      // 1. 先处理特殊HTML实体
      cleanContent = _decodeHtmlEntities(cleanContent);
      
      // 2. 移除脚本、样式和注释
      cleanContent = cleanContent
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false), '')
          .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false), '')
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      
      // 3. 处理块级元素（保持段落结构）
      cleanContent = cleanContent
          .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'</p>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</div>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<hr[^>]*>', caseSensitive: false), '\n───────────\n');
      
      // 4. 处理标题元素
      for (int i = 1; i <= 6; i++) {
        cleanContent = cleanContent
            .replaceAll(RegExp(r'<h$i[^>]*>', caseSensitive: false), '\n\n')
            .replaceAll(RegExp(r'</h$i>', caseSensitive: false), '\n');
      }
      
      // 5. 处理列表
      cleanContent = cleanContent
          .replaceAll(RegExp(r'<ul[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</ul>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<ol[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</ol>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
          .replaceAll(RegExp(r'</li>', caseSensitive: false), '');
      
      // 6. 处理其他行内元素
      cleanContent = cleanContent
          .replaceAll(RegExp(r'<strong[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'</strong>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<b[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'</b>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<em[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'</em>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<i[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'</i>', caseSensitive: false), '');
      
      // 7. 移除所有剩余的HTML标签
      cleanContent = cleanContent.replaceAll(RegExp(r'<[^>]*>'), '');
      
      // 8. 清理空白字符
      cleanContent = cleanContent
          .replaceAll(RegExp(r'[ \t]+'), ' ')  // 多个空格变一个
          .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')  // 多个换行变两个
          .replaceAll(RegExp(r'^\s+', multiLine: true), '')  // 行首空白
          .replaceAll(RegExp(r'\s+$', multiLine: true), '')  // 行尾空白
          .trim();
      
      // 9. 最后检查内容质量
      if (cleanContent.length < 20) {
        print('   ⚠️  清理后内容过短: ${cleanContent.length} 字符');
        // 如果内容太短，可能清理过度，返回原始内容的简单清理版本
        return _simpleHtmlClean(htmlContent);
      }
      
      print('   ✅ 增强HTML清理完成: ${cleanContent.length} 字符');
      
      // 显示清理后内容的预览
      if (cleanContent.isNotEmpty) {
        final preview = cleanContent.length > 150 
            ? '${cleanContent.substring(0, 150)}...'
            : cleanContent;
        print('   📝 内容预览: ${preview.replaceAll('\n', '\\n')}');
      }
      
      return cleanContent;
    } catch (e) {
      print('   ❌ 增强HTML清理失败: $e');
      return _simpleHtmlClean(htmlContent);
    }
  }
  
  /// 简单HTML清理（备用方案）
  String _simpleHtmlClean(String htmlContent) {
    return htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  
  /// HTML实体解码
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
        .replaceAll('&trade;', '™');
  }



  /// 改进的内容分页
  List<String> _paginateContent(List<String> contents) {
    final pages = <String>[];
    
    try {
      print('🔄 开始智能分页，总章节数: ${contents.length}');
      
      for (int chapterIndex = 0; chapterIndex < contents.length; chapterIndex++) {
        final chapterContent = contents[chapterIndex];
        print('   📖 处理第${chapterIndex + 1}章，内容长度: ${chapterContent.length}');
        
        if (chapterContent.trim().isEmpty) {
          print('   ⚠️  章节内容为空，跳过');
          continue;
        }
        
        // 根据内容长度动态调整分页策略
        final chapterPages = _paginateChapterContent(chapterContent, chapterIndex + 1);
        pages.addAll(chapterPages);
        
        print('   ✅ 第${chapterIndex + 1}章分页完成，生成${chapterPages.length}页');
      }
      
      print('📄 分页完成，总页数: ${pages.length}');
    } catch (e) {
      print('❌ 内容分页失败: $e');
      return _generateFallbackContent();
    }
    
    return pages.isNotEmpty ? pages : _generateFallbackContent();
  }
  
  /// 智能章节分页
  List<String> _paginateChapterContent(String content, int chapterNumber) {
    final pages = <String>[];
    
    // 根据内容长度确定分页策略
    const maxCharsPerPage = 1500;
    const idealCharsPerPage = 1200;
    
    if (content.length <= maxCharsPerPage) {
      // 内容不长，直接作为一页
      pages.add(_formatPageContent(content, chapterNumber, 1));
      return pages;
    }
    
    // 内容较长，需要智能分页
    final paragraphs = content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    if (paragraphs.isEmpty) {
      // 没有段落，按字符强制分页
      return _forcePageBreak(content, chapterNumber, idealCharsPerPage);
    }
    
    // 按段落智能分页
          String currentPageContent = '';
          int pageNumber = 1;
          
    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      final potentialContent = currentPageContent.isEmpty 
          ? paragraph 
          : '$currentPageContent\n\n$paragraph';
      
      if (potentialContent.length > maxCharsPerPage && currentPageContent.isNotEmpty) {
              // 当前页已满，保存并开始新页
        pages.add(_formatPageContent(currentPageContent.trim(), chapterNumber, pageNumber));
                pageNumber++;
        currentPageContent = paragraph;
            } else {
        currentPageContent = potentialContent;
            }
          }
          
          // 保存最后一页
          if (currentPageContent.isNotEmpty) {
      pages.add(_formatPageContent(currentPageContent.trim(), chapterNumber, pageNumber));
    }
    
    return pages;
  }
  
  /// 强制分页（当段落分页失败时使用）
  List<String> _forcePageBreak(String content, int chapterNumber, int charsPerPage) {
    final pages = <String>[];
    int pageNumber = 1;
    
    for (int i = 0; i < content.length; i += charsPerPage) {
      final endIndex = (i + charsPerPage).clamp(0, content.length);
      String pageContent = content.substring(i, endIndex);
      
      // 尝试在单词边界分页
      if (endIndex < content.length) {
        final lastSpaceIndex = pageContent.lastIndexOf(' ');
        if (lastSpaceIndex > charsPerPage * 0.8) { // 至少保持80%的页面利用率
          pageContent = content.substring(i, i + lastSpaceIndex);
          i = i + lastSpaceIndex - charsPerPage; // 调整下次开始位置
        }
      }
      
      pages.add(_formatPageContent(pageContent.trim(), chapterNumber, pageNumber));
      pageNumber++;
    }
    
    return pages;
  }

  /// 格式化页面内容
  String _formatPageContent(String content, int chapter, int page) {
    return '''
第$chapter章 - 第$page页

$content

───────────────────

''';
  }

  /// 生成示例内容（降级方案）
  List<String> _generateSampleContent() {
    final pages = <String>[];
    
    try {
      final spine = _epubBook!.Schema?.Package?.Spine?.Items;
      
      if (spine != null) {
        for (int i = 0; i < spine.length; i++) {
          for (int j = 0; j < 5; j++) { // 减少到每章5页
            pages.add('''
第${i + 1}章 第${j + 1}页

这是EPUB文档的内容预览。

虽然无法完全解析此EPUB文件的内容，
但您仍然可以使用阅读器的基本功能：

• 翻页浏览
• 章节导航  
• 书签功能
• 设置调整

当前位置：第${i + 1}章 / 第${j + 1}页

请尝试使用其他标准格式的EPUB文件
以获得更好的阅读体验。

───────────────────
            ''');
          }
        }
      }
    } catch (e) {
      print('生成示例内容失败: $e');
      return _generateFallbackContent();
    }

    return pages;
  }

  /// 生成备用内容（最后降级方案）
  List<String> _generateFallbackContent() {
    return [
      '''
EPUB阅读器

文档已加载，但内容解析遇到问题。

可能的原因：
• EPUB文件格式不标准
• 文件结构复杂
• 包含特殊编码

建议：
• 尝试其他EPUB文件
• 检查文件完整性
• 使用标准EPUB格式

这是一个简化的阅读界面，
部分功能可能受限。

───────────────────
      '''
    ];
  }

  /// 获取指定页面内容
  String? getPageContent(int pageIndex) {
    if (_pageContents == null || pageIndex < 0 || pageIndex >= _pageContents!.length) {
      return null;
    }
    return _pageContents![pageIndex];
  }

  /// 获取章节列表
  List<Chapter> getChapters() {
    return _chapters ?? [];
  }

  /// 获取总页数
  int getTotalPages() {
    return _pageContents?.length ?? 0;
  }

  /// 根据页码查找所属章节
  Chapter? getChapterByPage(int pageIndex) {
    if (_chapters == null) return null;
    
    for (final chapter in _chapters!) {
      if (chapter.containsPage(pageIndex)) {
        return chapter;
      }
    }
    
    return null;
  }

  /// 搜索文本
  List<SearchResult> searchText(String query) {
    if (_pageContents == null || query.isEmpty) return [];

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (int i = 0; i < _pageContents!.length; i++) {
      final content = _pageContents![i];
      final lowerContent = content.toLowerCase();
      
      int startIndex = 0;
      while (true) {
        final index = lowerContent.indexOf(lowerQuery, startIndex);
        if (index == -1) break;

        // 获取上下文
        final contextStart = (index - 50).clamp(0, content.length);
        final contextEnd = (index + query.length + 50).clamp(0, content.length);
        final context = content.substring(contextStart, contextEnd);

        results.add(SearchResult(
          pageIndex: i,
          position: index,
          context: context,
          matchStart: index - contextStart,
          matchEnd: index - contextStart + query.length,
        ));

        startIndex = index + 1;
        
        // 限制每页的搜索结果数量
        if (results.where((r) => r.pageIndex == i).length >= 10) break;
      }
    }

    return results;
  }

  /// 释放资源
  void dispose() {
    _epubBook = null;
    _pageContents = null;
    _chapters = null;
  }
}

// 辅助函数
int max(int a, int b) => a > b ? a : b;
int min(int a, int b) => a < b ? a : b;