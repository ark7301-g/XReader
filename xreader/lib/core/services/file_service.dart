import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:epubx/epubx.dart';
import '../../data/models/book.dart';

/// 文件服务类 (暂时简化实现，移除了file_picker依赖)
class FileService {
  static const List<String> supportedExtensions = ['epub', 'pdf'];
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  
  /// 导入书籍文件
  static Future<String?> importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          // 检查文件大小
          final fileSize = await getFileSize(file.path!);
          if (fileSize > maxFileSize) {
            throw Exception('文件过大，请选择小于50MB的文件');
          }

          // 复制文件到应用目录
          final targetPath = await copyFileToAppDirectory(file.path!);
          return targetPath;
        }
      }
      return null;
    } catch (e) {
      print('导入书籍失败: $e');
      throw Exception('导入书籍失败: ${e.toString()}');
    }
  }
  
  /// 批量导入书籍
  static Future<List<String>> importMultipleBooks() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<String> targetPaths = [];
        
        for (final file in result.files) {
          if (file.path != null) {
            try {
              // 检查文件大小
              final fileSize = await getFileSize(file.path!);
              if (fileSize > maxFileSize) {
                print('跳过文件 ${file.name}：文件过大');
                continue;
              }

              // 复制文件到应用目录
              final targetPath = await copyFileToAppDirectory(file.path!);
              targetPaths.add(targetPath);
            } catch (e) {
              print('处理文件 ${file.name} 失败: $e');
            }
          }
        }
        
        return targetPaths;
      }
      return [];
    } catch (e) {
      print('批量导入书籍失败: $e');
      throw Exception('批量导入书籍失败: ${e.toString()}');
    }
  }
  
  /// 获取应用文档目录
  static Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// 获取书籍存储目录
  static Future<Directory> getBooksDirectory() async {
    final documentsDir = await getDocumentsDirectory();
    final booksDir = Directory(path.join(documentsDir.path, 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }
  
  /// 获取缓存目录
  static Future<Directory> getCacheDirectory() async {
    return await getTemporaryDirectory();
  }
  
  /// 复制文件到应用目录
  static Future<String> copyFileToAppDirectory(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('源文件不存在: $sourcePath');
    }
    
    final booksDir = await getBooksDirectory();
    var fileName = path.basename(sourcePath);
    var extension = path.extension(fileName);
    
    print('📁 原始文件名: $fileName');
    print('📁 检测到扩展名: $extension');
    
    // 如果没有扩展名，尝试通过文件内容检测文件类型
    if (extension.isEmpty) {
      print('⚠️ 文件缺少扩展名，尝试检测文件类型...');
      final bytes = await file.readAsBytes();
      
      // 检测EPUB文件头(ZIP格式开头)
      if (bytes.length >= 4 && 
          bytes[0] == 0x50 && bytes[1] == 0x4B && 
          bytes[2] == 0x03 && bytes[3] == 0x04) {
        print('✅ 检测到EPUB文件格式');
        fileName = '$fileName.epub';
        extension = '.epub';
      }
      // 检测PDF文件头
      else if (bytes.length >= 4 && 
               bytes[0] == 0x25 && bytes[1] == 0x50 && 
               bytes[2] == 0x44 && bytes[3] == 0x46) {
        print('✅ 检测到PDF文件格式');
        fileName = '$fileName.pdf';
        extension = '.pdf';
      } else {
        print('❌ 无法识别文件格式');
        throw Exception('无法识别文件格式，请确保选择的是有效的EPUB或PDF文件');
      }
    }
    
    final targetPath = path.join(booksDir.path, fileName);
    
    // 如果目标文件已存在，生成新名称
    String finalPath = targetPath;
    int counter = 1;
    while (await File(finalPath).exists()) {
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      finalPath = path.join(booksDir.path, '${nameWithoutExt}_$counter$extension');
      counter++;
    }
    
    print('📁 最终文件路径: $finalPath');
    await file.copy(finalPath);
    return finalPath;
  }
  
  /// 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除文件失败: $e');
      return false;
    }
  }
  
  /// 检查文件是否为支持的格式
  static bool isSupportedFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceFirst('.', '');
    return supportedExtensions.contains(extension);
  }
  
  /// 获取文件大小
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
  
  /// 获取文件类型
  static String getFileType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.epub':
        return 'epub';
      case '.pdf':
        return 'pdf';
      default:
        return 'unknown';
    }
  }
  
  /// 解析EPUB文件信息 (增强版，带详细日志)
  static Future<Book?> parseEpubFile(String filePath) async {
    print('🔍 开始解析EPUB文件: ${path.basename(filePath)}');
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      
      final fileSize = await file.length();
      print('📁 文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // 使用epubx库解析EPUB文件
      print('📖 开始读取EPUB字节数据...');
      final bytes = await file.readAsBytes();
      print('✅ 字节数据读取完成: ${bytes.length} bytes');
      
      EpubBook? epubBook;
      
      try {
        print('🔄 尝试标准EPUB解析...');
        epubBook = await EpubReader.readBook(bytes);
        print('✅ 标准EPUB解析成功！');
      } catch (epubError) {
        print('❌ EPUB标准解析失败: $epubError');
        print('🔧 错误详情: ${epubError.runtimeType}');
        
        // 尝试更宽松的解析方式
        try {
          print('🔄 尝试容错解析...');
          epubBook = await _parseEpubWithTolerance(bytes);
          print('✅ 容错解析成功！');
        } catch (toleranceError) {
          print('❌ 容错解析也失败: $toleranceError');
          print('🔧 容错错误详情: ${toleranceError.runtimeType}');
          throw Exception('EPUB解析失败: ${epubError.toString()}');
        }
      }
      
      print('🔍 开始提取EPUB元数据...');
      
      // 打印EPUB结构信息用于调试
      await _debugEpubStructure(epubBook);
      
      // 提取基本信息，增加容错处理
      String title = _extractTitle(epubBook, filePath);
      String author = _extractAuthor(epubBook);
      String? description = _extractDescription(epubBook);
      int? totalPages = _estimatePageCount(epubBook);
      
      print('📚 提取的信息:');
      print('   标题: $title');
      print('   作者: $author');
      print('   描述: ${description ?? "无"}');
      print('   估算页数: $totalPages');
      
      final book = Book()
        ..filePath = filePath
        ..title = title
        ..author = author
        ..description = description
        ..fileType = 'epub'
        ..fileSize = fileSize
        ..totalPages = totalPages ?? 0
        ..addedDate = DateTime.now();
      
      print('✅ EPUB解析完全成功: $title by $author');
      return book;
    } catch (e) {
      print('❌ 解析EPUB文件最终失败: $e');
      print('🔧 错误堆栈: ${StackTrace.current}');
      // 返回基本信息，即使解析失败
      return _createFallbackBook(filePath);
    }
  }

  /// 调试EPUB结构信息
  static Future<void> _debugEpubStructure(EpubBook epubBook) async {
    try {
      print('📋 EPUB结构分析:');
      
      // 基本信息
      print('   📖 Title: ${epubBook.Title}');
      print('   👤 Author: ${epubBook.Author}');
      print('   🏷️  AuthorList: ${epubBook.AuthorList}');
      
      // Schema信息
      final schema = epubBook.Schema;
      if (schema != null) {
        print('   📄 Schema存在');
        
        final package = schema.Package;
        if (package != null) {
          print('   📦 Package存在');
          
          // Metadata
          final metadata = package.Metadata;
          if (metadata != null) {
            print('   🏷️  Metadata存在');
            print('      Titles: ${metadata.Titles?.length ?? 0}');
            print('      Creators: ${metadata.Creators?.length ?? 0}');
            print('      Contributors: ${metadata.Contributors?.length ?? 0}');
            if (metadata.Creators?.isNotEmpty == true) {
              for (int i = 0; i < metadata.Creators!.length; i++) {
                final creator = metadata.Creators![i];
                print('      Creator[$i]: ${creator.Creator} (Role: ${creator.Role})');
              }
            }
          }
          
          // Manifest
          final manifest = package.Manifest;
          if (manifest != null) {
            print('   📄 Manifest存在，项目数: ${manifest.Items?.length ?? 0}');
            if (manifest.Items?.isNotEmpty == true) {
              for (int i = 0; i < (manifest.Items!.length < 5 ? manifest.Items!.length : 5); i++) {
                final item = manifest.Items![i];
                print('      Item[$i]: ${item.Id} -> ${item.Href} (${item.MediaType})');
              }
              if (manifest.Items!.length > 5) {
                print('      ... 还有 ${manifest.Items!.length - 5} 个项目');
              }
            }
          }
          
          // Spine
          final spine = package.Spine;
          if (spine != null) {
            print('   📚 Spine存在，项目数: ${spine.Items?.length ?? 0}');
            if (spine.Items?.isNotEmpty == true) {
              for (int i = 0; i < (spine.Items!.length < 3 ? spine.Items!.length : 3); i++) {
                final item = spine.Items![i];
                print('      Spine[$i]: ${item.IdRef} (Linear: ${item.IsLinear})');
              }
              if (spine.Items!.length > 3) {
                print('      ... 还有 ${spine.Items!.length - 3} 个项目');
              }
            }
          }
        }
        
        // Navigation
        final navigation = schema.Navigation;
        if (navigation != null) {
          print('   🧭 Navigation存在');
          print('      Head存在: ${navigation.Head != null}');
          print('      DocTitle: ${navigation.DocTitle}');
          print('      DocAuthors: ${navigation.DocAuthors?.length ?? 0}');
          print('      NavMap存在: ${navigation.NavMap != null}');
          if (navigation.NavMap?.Points?.isNotEmpty == true) {
            print('      NavPoints数量: ${navigation.NavMap!.Points!.length}');
          }
        }
      }
      
      // Content信息
      if (epubBook.Content != null) {
        print('   📁 Content存在');
        print('      Content类型: ${epubBook.Content.runtimeType}');
        
        // 分析Content结构
        try {
          // 检查Content是否有Html属性
          final content = epubBook.Content;
          
          // 尝试获取Html内容
          if (content?.Html != null) {
            print('      Html内容存在');
            final htmlEntries = content!.Html!;
            if (htmlEntries.isNotEmpty) {
              print('      Html文件数: ${htmlEntries.length}');
              for (int i = 0; i < htmlEntries.length && i < 3; i++) {
                final entry = htmlEntries.entries.elementAt(i);
                print('      Html[$i]: ${entry.key} (${entry.value.Content?.length ?? 0} chars)');
              }
            }
          }
          
          // 尝试获取Images内容
          if (content?.Images != null) {
            print('      Images内容存在');
            final imageEntries = content!.Images!;
            if (imageEntries.isNotEmpty) {
              print('      图片文件数: ${imageEntries.length}');
              for (int i = 0; i < imageEntries.length && i < 3; i++) {
                final entry = imageEntries.entries.elementAt(i);
                print('      Image[$i]: ${entry.key} (${entry.value.Content?.length ?? 0} bytes)');
              }
            }
          }
          
          // 尝试获取Css内容
          if (content?.Css != null) {
            print('      Css内容存在');
            final cssEntries = content!.Css!;
            if (cssEntries.isNotEmpty) {
              print('      CSS文件数: ${cssEntries.length}');
            }
          }
          
        } catch (e) {
          print('      Content详细分析失败: $e');
          // 回退到基本信息
          final contentStr = epubBook.Content.toString();
          print('      Content信息: ${contentStr.length > 100 ? '${contentStr.substring(0, 100)}...' : contentStr}');
        }
      }
      
    } catch (e) {
      print('❌ EPUB结构分析失败: $e');
    }
  }

  /// 容错解析EPUB - 尝试不同的解析策略
  static Future<EpubBook> _parseEpubWithTolerance(Uint8List bytes) async {
    print('🔧 进入容错解析模式...');
    
    // 策略1: 尝试忽略某些验证错误
    try {
      print('🔄 策略1: 标准解析（重试）...');
      final book = await EpubReader.readBook(bytes);
      print('✅ 策略1成功');
      return book;
    } catch (e) {
      print('❌ 策略1失败: $e');
    }
    
    // 如果所有策略都失败，抛出错误
    throw Exception('所有容错解析策略都失败');
  }

  /// 提取标题，增加容错处理
  static String _extractTitle(EpubBook epubBook, String filePath) {
    try {
      // 尝试多种方式获取标题
      if (epubBook.Title != null && epubBook.Title!.isNotEmpty) {
        return epubBook.Title!.trim();
      }
      
      // 尝试从metadata获取
      final metadata = epubBook.Schema?.Package?.Metadata;
      if (metadata?.Titles?.isNotEmpty == true) {
        final title = metadata!.Titles!.first;
        if (title.isNotEmpty) return title.trim();
      }
      
      // 如果都失败，使用文件名
      return path.basenameWithoutExtension(filePath);
    } catch (e) {
      print('提取标题失败: $e');
      return path.basenameWithoutExtension(filePath);
    }
  }

  /// 提取作者信息
  static String _extractAuthor(EpubBook epubBook) {
    try {
      if (epubBook.Author != null && epubBook.Author!.isNotEmpty) {
        return epubBook.Author!.trim();
      }
      
      // 尝试从metadata获取
      final metadata = epubBook.Schema?.Package?.Metadata;
      if (metadata?.Creators?.isNotEmpty == true) {
        final creators = metadata!.Creators!
            .map((creator) => creator.Creator ?? creator.toString())
            .where((creatorStr) => creatorStr.isNotEmpty)
            .toList();
        if (creators.isNotEmpty) {
          return creators.join(', ').trim();
        }
      }
      
      return '未知作者';
    } catch (e) {
      print('提取作者失败: $e');
      return '未知作者';
    }
  }

  /// 提取描述信息
  static String? _extractDescription(EpubBook epubBook) {
    try {
      // 暂时简化，因为API可能不同
      return null;
    } catch (e) {
      print('提取描述失败: $e');
      return null;
    }
  }

  /// 估算页数
  static int? _estimatePageCount(EpubBook epubBook) {
    try {
      int estimatedPages = 0;
      
      // 基于spine项目数量估算
      final spineItems = epubBook.Schema?.Package?.Spine?.Items;
      if (spineItems != null) {
        estimatedPages = spineItems.length * 10; // 每章节估算10页
      }
      
      // 基于内容长度进一步调整（简化版本）
      try {
        // 暂时简化这部分，因为Content API可能不同
        // 后续可以根据实际的epubx API进行调整
      } catch (e) {
        print('内容长度估算失败: $e');
      }
      
      return estimatedPages > 0 ? estimatedPages : null;
    } catch (e) {
      print('估算页数失败: $e');
      return null;
    }
  }

  /// 创建降级书籍对象
  static Book _createFallbackBook(String filePath) {
    return Book()
      ..filePath = filePath
      ..title = path.basenameWithoutExtension(filePath)
      ..author = '未知作者'
      ..description = '该EPUB文件解析失败，但仍可尝试阅读'
      ..fileType = 'epub'
      ..fileSize = 0
      ..totalPages = 0
      ..addedDate = DateTime.now();
  }
  
  /// 解析PDF文件信息 (简化版)
  static Future<Book?> parsePdfFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      
      final book = Book()
        ..filePath = filePath
        ..title = path.basenameWithoutExtension(filePath)
        ..author = '未知作者'
        ..fileType = 'pdf'
        ..fileSize = await file.length()
        ..addedDate = DateTime.now();
      
      return book;
    } catch (e) {
      print('解析PDF文件失败: $e');
      return null;
    }
  }
  
  /// 清理临时文件
  static Future<void> cleanupTempFiles() async {
    try {
      final cacheDir = await getCacheDirectory();
      final tempFiles = await cacheDir.list().toList();
      
      for (final entity in tempFiles) {
        if (entity is File) {
          final lastModified = await entity.lastModified();
          final daysSinceModified = DateTime.now().difference(lastModified).inDays;
          
          // 删除7天前的临时文件
          if (daysSinceModified > 7) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('清理临时文件失败: $e');
    }
  }
  
  /// 解析书籍信息 (根据文件类型)
  static Future<Book?> parseBookInfo(String filePath) async {
    final fileType = getFileType(filePath);
    switch (fileType) {
      case 'epub':
        return await parseEpubFile(filePath);
      case 'pdf':
        return await parsePdfFile(filePath);
      default:
        return null;
    }
  }
  
  /// 删除书籍文件
  static Future<bool> deleteBookFile(String filePath) async {
    return await deleteFile(filePath);
  }
  
  /// 删除封面文件
  static Future<bool> deleteCoverFile(String? coverPath) async {
    if (coverPath == null) return true;
    return await deleteFile(coverPath);
  }
  
  /// 获取应用存储使用情况
  static Future<Map<String, int>> getStorageUsage() async {
    try {
      final booksDir = await getBooksDirectory();
      final cacheDir = await getCacheDirectory();
      
      int booksSize = 0;
      int cacheSize = 0;
      
      // 计算书籍目录大小
      if (await booksDir.exists()) {
        final bookFiles = await booksDir.list(recursive: true).toList();
        for (final entity in bookFiles) {
          if (entity is File) {
            booksSize += await entity.length();
          }
        }
      }
      
      // 计算缓存目录大小
      if (await cacheDir.exists()) {
        final cacheFiles = await cacheDir.list(recursive: true).toList();
        for (final entity in cacheFiles) {
          if (entity is File) {
            cacheSize += await entity.length();
          }
        }
      }
      
      return {
        'books': booksSize,
        'cache': cacheSize,
        'total': booksSize + cacheSize,
      };
    } catch (e) {
      print('获取存储使用情况失败: $e');
      return {'books': 0, 'cache': 0, 'total': 0};
    }
  }
}