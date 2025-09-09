import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 错误类型枚举
enum ErrorType {
  network('网络错误'),
  fileSystem('文件系统错误'),
  database('数据库错误'),
  parsing('解析错误'),
  permission('权限错误'),
  storage('存储错误'),
  unknown('未知错误');

  const ErrorType(this.message);
  final String message;
}

/// 自定义异常类
class AppException implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalException;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  const AppException({
    required this.message,
    required this.type,
    this.originalException,
    this.stackTrace,
    this.metadata,
  });

  @override
  String toString() {
    return 'AppException: $message (${type.message})';
  }

  /// 获取用户友好的错误信息
  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return '网络连接异常，请检查网络设置';
      case ErrorType.fileSystem:
        return '文件操作失败，请检查文件是否存在或权限是否正确';
      case ErrorType.database:
        return '数据保存失败，请重试';
      case ErrorType.parsing:
        return '文件格式不正确或已损坏';
      case ErrorType.permission:
        return '没有访问权限，请在设置中开启相关权限';
      case ErrorType.storage:
        return '存储空间不足或存储异常';
      case ErrorType.unknown:
        return '操作失败，请重试';
    }
  }
}

/// 错误处理器
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// 错误回调
  static Function(AppException)? onError;

  /// 处理异常并转换为AppException
  static AppException handleException(dynamic exception, [StackTrace? stackTrace]) {
    AppException appException;

    if (exception is AppException) {
      appException = exception;
    } else {
      appException = _convertToAppException(exception, stackTrace);
    }

    // 记录错误日志
    _logError(appException);

    // 调用错误回调
    onError?.call(appException);

    return appException;
  }

  /// 将系统异常转换为AppException
  static AppException _convertToAppException(dynamic exception, StackTrace? stackTrace) {
    if (exception is FileSystemException) {
      return AppException(
        message: exception.message,
        type: ErrorType.fileSystem,
        originalException: exception,
        stackTrace: stackTrace,
        metadata: {
          'path': exception.path,
          'osError': exception.osError?.toString(),
        },
      );
    }

    if (exception is FormatException) {
      return AppException(
        message: exception.message,
        type: ErrorType.parsing,
        originalException: exception,
        stackTrace: stackTrace,
        metadata: {
          'source': exception.source,
          'offset': exception.offset,
        },
      );
    }

    if (exception is PlatformException) {
      ErrorType type = ErrorType.unknown;
      if (exception.code.contains('permission')) {
        type = ErrorType.permission;
      } else if (exception.code.contains('storage')) {
        type = ErrorType.storage;
      }

      return AppException(
        message: exception.message ?? exception.code,
        type: type,
        originalException: exception,
        stackTrace: stackTrace,
        metadata: {
          'code': exception.code,
          'details': exception.details,
        },
      );
    }

    if (exception is SocketException) {
      return AppException(
        message: exception.message,
        type: ErrorType.network,
        originalException: exception,
        stackTrace: stackTrace,
        metadata: {
          'address': exception.address?.toString(),
          'port': exception.port,
        },
      );
    }

    // 默认未知错误
    return AppException(
      message: exception.toString(),
      type: ErrorType.unknown,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  /// 记录错误日志
  static void _logError(AppException exception) {
    if (kDebugMode) {
      print('=== Error Log ===');
      print('Type: ${exception.type}');
      print('Message: ${exception.message}');
      print('User Message: ${exception.userFriendlyMessage}');
      if (exception.metadata != null) {
        print('Metadata: ${exception.metadata}');
      }
      if (exception.stackTrace != null) {
        print('Stack Trace:');
        print(exception.stackTrace);
      }
      print('================');
    }
  }

  /// 安全执行异步操作
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    T? defaultValue,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      final appException = handleException(exception, stackTrace);
      
      if (showError && onError != null) {
        onError!(appException);
      }
      
      return defaultValue;
    }
  }

  /// 安全执行同步操作
  static T? safeExecuteSync<T>(
    T Function() operation, {
    T? defaultValue,
    bool showError = true,
  }) {
    try {
      return operation();
    } catch (exception, stackTrace) {
      final appException = handleException(exception, stackTrace);
      
      if (showError && onError != null) {
        onError!(appException);
      }
      
      return defaultValue;
    }
  }

  /// 重试机制
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Exception)? retryCondition,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (exception) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // 检查是否满足重试条件
        if (retryCondition != null && !retryCondition(exception as Exception)) {
          rethrow;
        }
        
        await Future.delayed(delay * attempts);
      }
    }
    
    throw StateError('重试次数已达上限');
  }

  /// 检查网络连接
  static Future<bool> checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 检查存储空间
  static Future<bool> checkStorageSpace({int requiredSpaceMB = 100}) async {
    try {
      // 这里可以添加实际的存储空间检查逻辑
      // 目前返回true作为默认值
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 检查文件权限
  static Future<bool> checkFilePermission(String filePath) async {
    try {
      final file = File(filePath);
      await file.stat();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 错误恢复策略
class ErrorRecoveryStrategy {
  static final Map<ErrorType, Future<bool> Function()> _strategies = {
    ErrorType.network: () => ErrorHandler.checkNetworkConnection(),
    ErrorType.storage: () => ErrorHandler.checkStorageSpace(),
    ErrorType.fileSystem: () async => true, // 默认策略
  };

  /// 注册恢复策略
  static void registerStrategy(ErrorType type, Future<bool> Function() strategy) {
    _strategies[type] = strategy;
  }

  /// 尝试恢复
  static Future<bool> attemptRecovery(ErrorType type) async {
    final strategy = _strategies[type];
    if (strategy != null) {
      try {
        return await strategy();
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}

/// 错误统计
class ErrorStatistics {
  static final Map<ErrorType, int> _errorCounts = {};
  static final List<AppException> _recentErrors = [];
  static const int maxRecentErrors = 50;

  /// 记录错误
  static void recordError(AppException exception) {
    _errorCounts[exception.type] = (_errorCounts[exception.type] ?? 0) + 1;
    
    _recentErrors.add(exception);
    if (_recentErrors.length > maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
  }

  /// 获取错误统计
  static Map<ErrorType, int> getErrorCounts() {
    return Map.unmodifiable(_errorCounts);
  }

  /// 获取最近错误
  static List<AppException> getRecentErrors() {
    return List.unmodifiable(_recentErrors);
  }

  /// 获取最常见的错误类型
  static ErrorType? getMostCommonErrorType() {
    if (_errorCounts.isEmpty) return null;
    
    return _errorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 清除统计
  static void clearStatistics() {
    _errorCounts.clear();
    _recentErrors.clear();
  }
}

/// 断路器模式实现
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  final Duration recoveryTimeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.recoveryTimeout = const Duration(minutes: 1),
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
      } else {
        throw AppException(
          message: 'Circuit breaker is open for $name',
          type: ErrorType.unknown,
        );
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (exception) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _lastFailureTime = null;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
           DateTime.now().difference(_lastFailureTime!) > recoveryTimeout;
  }

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;
}

enum CircuitBreakerState { closed, open, halfOpen }
