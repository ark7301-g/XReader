import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'models/epub_book.dart';

/// EPUB文件验证器
/// 
/// 负责验证EPUB文件的有效性，包括：
/// - 文件存在性和大小检查
/// - ZIP文件结构验证
/// - 必要文件存在性检查
/// - 编码格式检测
class EpubValidator {
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<int> zipMagicNumbers = [0x50, 0x4B]; // PK

  /// 验证EPUB文件
  Future<ValidationResult> validateFile(String filePath) async {
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    final diagnostics = <String, dynamic>{};
    
    try {
      print('🔍 开始验证EPUB文件: ${_getFileName(filePath)}');
      
      // 1. 文件存在性检查
      final file = File(filePath);
      if (!await file.exists()) {
        errors.add(EpubParsingError(
          level: EpubParsingErrorLevel.fatal,
          message: '文件不存在',
          location: filePath,
          timestamp: DateTime.now(),
        ));
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          diagnostics: diagnostics,
        );
      }
      
      // 2. 文件大小检查
      final fileSize = await file.length();
      diagnostics['file_size'] = fileSize;
      
      if (fileSize == 0) {
        errors.add(EpubParsingError(
          level: EpubParsingErrorLevel.fatal,
          message: '文件为空',
          location: filePath,
          timestamp: DateTime.now(),
        ));
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          diagnostics: diagnostics,
        );
      }
      
      if (fileSize > maxFileSize) {
        warnings.add(EpubParsingWarning(
          message: '文件过大 (${_formatFileSize(fileSize)})，可能影响性能',
          suggestion: '建议文件大小小于${_formatFileSize(maxFileSize)}',
          location: filePath,
          timestamp: DateTime.now(),
        ));
      }
      
      print('   📏 文件大小: ${_formatFileSize(fileSize)}');
      
      // 3. 文件扩展名检查
      if (!filePath.toLowerCase().endsWith('.epub')) {
        warnings.add(EpubParsingWarning(
          message: '文件扩展名不是.epub',
          suggestion: '确保文件是有效的EPUB格式',
          location: filePath,
          timestamp: DateTime.now(),
        ));
      }
      
      // 4. 文件头魔数检查
      final bytes = await _readFileHeader(file, 4);
      if (!_hasValidZipHeader(bytes)) {
        errors.add(EpubParsingError(
          level: EpubParsingErrorLevel.fatal,
          message: '文件不是有效的ZIP格式',
          suggestion: '确保文件是有效的EPUB文件（EPUB是ZIP格式的容器）',
          location: filePath,
          timestamp: DateTime.now(),
        ));
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          diagnostics: diagnostics,
        );
      }
      
      print('   ✅ ZIP文件头验证通过');
      
      // 5. ZIP文件结构验证
      final zipValidation = await _validateZipStructure(file);
      errors.addAll(zipValidation.errors);
      warnings.addAll(zipValidation.warnings);
      diagnostics.addAll(zipValidation.diagnostics);
      
      if (zipValidation.errors.isNotEmpty) {
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          diagnostics: diagnostics,
        );
      }
      
      // 6. EPUB必要文件检查
      final epubValidation = await _validateEpubStructure(zipValidation.archive!);
      errors.addAll(epubValidation.errors);
      warnings.addAll(epubValidation.warnings);
      diagnostics.addAll(epubValidation.diagnostics);
      
      // 7. 编码检测
      final encoding = await _detectEncoding(zipValidation.archive!);
      diagnostics['encoding'] = encoding;
      if (encoding != null) {
        print('   🔤 检测到编码: $encoding');
      }
      
      final isValid = errors.isEmpty || errors.every((e) => e.level != EpubParsingErrorLevel.fatal);
      
      if (isValid) {
        print('   ✅ EPUB文件验证通过');
      } else {
        print('   ❌ EPUB文件验证失败');
        for (final error in errors) {
          print('      - ${error.message}');
        }
      }
      
      return ValidationResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        diagnostics: diagnostics,
      );
      
    } catch (e) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.fatal,
        message: '验证过程中发生错误: ${e.toString()}',
        originalException: e is Exception ? e : Exception(e.toString()),
        location: filePath,
        timestamp: DateTime.now(),
      ));
      
      print('   ❌ 验证过程中发生错误: $e');
      
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        diagnostics: diagnostics,
      );
    }
  }

  /// 读取文件头
  Future<Uint8List> _readFileHeader(File file, int length) async {
    final randomAccessFile = await file.open();
    try {
      final bytes = await randomAccessFile.read(length);
      return Uint8List.fromList(bytes);
    } finally {
      await randomAccessFile.close();
    }
  }

  /// 检查ZIP文件头
  bool _hasValidZipHeader(Uint8List bytes) {
    if (bytes.length < 2) return false;
    return bytes[0] == zipMagicNumbers[0] && bytes[1] == zipMagicNumbers[1];
  }

  /// 验证ZIP文件结构
  Future<ZipValidationResult> _validateZipStructure(File file) async {
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    final diagnostics = <String, dynamic>{};
    
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      diagnostics['zip_files_count'] = archive.length;
      print('   📁 ZIP解压成功，包含${archive.length}个文件');
      
      // 检查文件数量合理性
      if (archive.isEmpty) {
        errors.add(EpubParsingError(
          level: EpubParsingErrorLevel.fatal,
          message: 'ZIP文件为空',
          timestamp: DateTime.now(),
        ));
        return ZipValidationResult(errors: errors, warnings: warnings, diagnostics: diagnostics);
      }
      
      if (archive.length > 10000) {
        warnings.add(EpubParsingWarning(
          message: 'ZIP文件包含过多文件 (${archive.length})，可能影响性能',
          timestamp: DateTime.now(),
        ));
      }
      
      // 检查是否有损坏的文件
      var corruptedFiles = 0;
      for (final file in archive.files) {
        if (file.content == null || (file.content is List && (file.content as List).isEmpty)) {
          corruptedFiles++;
        }
      }
      
      if (corruptedFiles > 0) {
        warnings.add(EpubParsingWarning(
          message: '发现$corruptedFiles个可能损坏的文件',
          suggestion: '这可能会影响内容提取',
          timestamp: DateTime.now(),
        ));
      }
      
      diagnostics['corrupted_files'] = corruptedFiles;
      
      return ZipValidationResult(
        archive: archive,
        errors: errors,
        warnings: warnings,
        diagnostics: diagnostics,
      );
      
    } catch (e) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.fatal,
        message: 'ZIP文件解压失败: ${e.toString()}',
        suggestion: '文件可能损坏或不是有效的ZIP格式',
        originalException: e is Exception ? e : Exception(e.toString()),
        timestamp: DateTime.now(),
      ));
      
      return ZipValidationResult(errors: errors, warnings: warnings, diagnostics: diagnostics);
    }
  }

  /// 验证EPUB文件结构
  Future<EpubStructureValidationResult> _validateEpubStructure(Archive archive) async {
    final errors = <EpubParsingError>[];
    final warnings = <EpubParsingWarning>[];
    final diagnostics = <String, dynamic>{};
    
    // 1. 检查mimetype文件
    final mimetypeFile = archive.findFile('mimetype');
    if (mimetypeFile == null) {
      warnings.add(EpubParsingWarning(
        message: '缺少mimetype文件',
        suggestion: '这不符合EPUB标准，但可能仍然可以解析',
        timestamp: DateTime.now(),
      ));
    } else {
      final mimetypeContent = utf8.decode(mimetypeFile.content as List<int>, allowMalformed: true);
      if (mimetypeContent.trim() != 'application/epub+zip') {
        warnings.add(EpubParsingWarning(
          message: 'mimetype文件内容不正确: $mimetypeContent',
          suggestion: '期望内容为application/epub+zip',
          timestamp: DateTime.now(),
        ));
      } else {
        print('   ✅ mimetype文件验证通过');
      }
    }
    
    // 2. 检查META-INF目录
    final metaInfFiles = archive.files.where((file) => file.name.startsWith('META-INF/')).toList();
    if (metaInfFiles.isEmpty) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.fatal,
        message: '缺少META-INF目录',
        suggestion: 'EPUB文件必须包含META-INF目录',
        timestamp: DateTime.now(),
      ));
    } else {
      print('   ✅ 找到META-INF目录，包含${metaInfFiles.length}个文件');
    }
    
    // 3. 检查container.xml文件
    final containerFile = archive.findFile('META-INF/container.xml');
    if (containerFile == null) {
      errors.add(EpubParsingError(
        level: EpubParsingErrorLevel.fatal,
        message: '缺少META-INF/container.xml文件',
        suggestion: '这是EPUB的核心配置文件',
        timestamp: DateTime.now(),
      ));
    } else {
      print('   ✅ 找到container.xml文件');
      
      // 简单检查container.xml内容
      try {
        final containerContent = utf8.decode(containerFile.content as List<int>, allowMalformed: true);
        if (!containerContent.contains('rootfile')) {
          warnings.add(EpubParsingWarning(
            message: 'container.xml可能格式不正确',
            suggestion: '缺少rootfile元素',
            timestamp: DateTime.now(),
          ));
        }
      } catch (e) {
        warnings.add(EpubParsingWarning(
          message: '无法解析container.xml内容',
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // 4. 统计文件类型
    var htmlFiles = 0;
    var imageFiles = 0;
    var cssFiles = 0;
    var xmlFiles = 0;
    var otherFiles = 0;
    
    for (final file in archive.files) {
      if (file.isFile) {
        final fileName = file.name.toLowerCase();
        if (fileName.endsWith('.html') || fileName.endsWith('.xhtml') || fileName.endsWith('.htm')) {
          htmlFiles++;
        } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png') || 
                   fileName.endsWith('.gif') || fileName.endsWith('.svg') || fileName.endsWith('.webp')) {
          imageFiles++;
        } else if (fileName.endsWith('.css')) {
          cssFiles++;
        } else if (fileName.endsWith('.xml') || fileName.endsWith('.ncx') || fileName.endsWith('.opf')) {
          xmlFiles++;
        } else {
          otherFiles++;
        }
      }
    }
    
    diagnostics['html_files'] = htmlFiles;
    diagnostics['image_files'] = imageFiles;
    diagnostics['css_files'] = cssFiles;
    diagnostics['xml_files'] = xmlFiles;
    diagnostics['other_files'] = otherFiles;
    
    print('   📊 文件类型统计:');
    print('      HTML/XHTML: $htmlFiles');
    print('      图片: $imageFiles');
    print('      CSS: $cssFiles');
    print('      XML: $xmlFiles');
    print('      其他: $otherFiles');
    
    // 5. 基本合理性检查
    if (htmlFiles == 0) {
      warnings.add(EpubParsingWarning(
        message: '未找到HTML/XHTML内容文件',
        suggestion: 'EPUB应该包含HTML格式的内容',
        timestamp: DateTime.now(),
      ));
    }
    
    if (xmlFiles == 0) {
      warnings.add(EpubParsingWarning(
        message: '未找到XML配置文件',
        suggestion: 'EPUB需要OPF等XML配置文件',
        timestamp: DateTime.now(),
      ));
    }
    
    return EpubStructureValidationResult(
      errors: errors,
      warnings: warnings,
      diagnostics: diagnostics,
    );
  }

  /// 检测文件编码
  Future<String?> _detectEncoding(Archive archive) async {
    try {
      // 检查几个关键XML文件的编码
      final filesToCheck = ['META-INF/container.xml'];
      
      // 添加可能的OPF文件
      for (final file in archive.files) {
        if (file.name.endsWith('.opf')) {
          filesToCheck.add(file.name);
          break;
        }
      }
      
      for (final fileName in filesToCheck) {
        final file = archive.findFile(fileName);
        if (file != null) {
          final content = utf8.decode(file.content as List<int>, allowMalformed: true);
          final encoding = _extractEncodingFromXml(content);
          if (encoding != null) {
            return encoding;
          }
        }
      }
      
      // 默认返回UTF-8
      return 'utf-8';
    } catch (e) {
      print('   ⚠️  编码检测失败: $e');
      return null;
    }
  }

  /// 从XML内容中提取编码信息
  String? _extractEncodingFromXml(String content) {
    // 查找XML声明中的编码
    final startIndex = content.indexOf('encoding=');
    if (startIndex == -1) return null;
    
    final afterEquals = content.substring(startIndex + 9);
    final quoteChar = afterEquals.startsWith('"') ? '"' : "'";
    final quoteIndex = afterEquals.indexOf(quoteChar);
    if (quoteIndex == -1) return null;
    
    final endQuoteIndex = afterEquals.indexOf(quoteChar, quoteIndex + 1);
    if (endQuoteIndex == -1) return null;
    
    return afterEquals.substring(quoteIndex + 1, endQuoteIndex).toLowerCase();
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取文件名
  String _getFileName(String filePath) {
    return filePath.split('/').last.split(r'\').last;
  }
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final Map<String, dynamic> diagnostics;
  
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.diagnostics = const {},
  });

  /// 是否有致命错误
  bool get hasFatalErrors => errors.any((e) => e.level == EpubParsingErrorLevel.fatal);
  
  /// 获取摘要信息
  String get summary {
    final parts = <String>[];
    if (isValid) {
      parts.add('验证通过');
    } else {
      parts.add('验证失败');
    }
    
    if (errors.isNotEmpty) {
      parts.add('${errors.length}个错误');
    }
    
    if (warnings.isNotEmpty) {
      parts.add('${warnings.length}个警告');
    }
    
    return parts.join(', ');
  }
}

/// ZIP验证结果
class ZipValidationResult {
  final Archive? archive;
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final Map<String, dynamic> diagnostics;
  
  const ZipValidationResult({
    this.archive,
    this.errors = const [],
    this.warnings = const [],
    this.diagnostics = const {},
  });
}

/// EPUB结构验证结果
class EpubStructureValidationResult {
  final List<EpubParsingError> errors;
  final List<EpubParsingWarning> warnings;
  final Map<String, dynamic> diagnostics;
  
  const EpubStructureValidationResult({
    this.errors = const [],
    this.warnings = const [],
    this.diagnostics = const {},
  });
}

/// Archive扩展
extension ArchiveValidationExtensions on Archive {
  /// 查找文件（支持大小写不敏感）
  ArchiveFile? findFile(String path) {
    // 先尝试精确匹配
    for (final file in files) {
      if (file.name == path) return file;
    }
    
    // 再尝试大小写不敏感匹配
    final lowerPath = path.toLowerCase();
    for (final file in files) {
      if (file.name.toLowerCase() == lowerPath) return file;
    }
    
    return null;
  }
}
