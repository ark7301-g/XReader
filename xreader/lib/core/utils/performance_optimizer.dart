import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 性能优化工具�?
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  static const int _maxCacheSize = 50; // 最大缓�?0张图�?

  // 防抖计时�?
  final Map<String, Timer> _debounceTimers = {};

  /// 图片缓存管理
  Future<Uint8List?> getCachedImage(String key) async {
    return _imageCache[key];
  }

  void cacheImage(String key, Uint8List imageData) {
    // 检查缓存大小，清理旧缓�?
    if (_imageCache.length >= _maxCacheSize) {
      final firstKey = _imageCache.keys.first;
      _imageCache.remove(firstKey);
    }
    _imageCache[key] = imageData;
  }

  void clearImageCache() {
    _imageCache.clear();
  }

  /// 防抖功能
  void debounce(String key, VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// 节流功能
  static Timer? _throttleTimer;
  static void throttle(VoidCallback callback, {Duration delay = const Duration(milliseconds: 100)}) {
    if (_throttleTimer?.isActive ?? false) return;
    
    callback();
    _throttleTimer = Timer(delay, () {
      _throttleTimer = null;
    });
  }

  /// 内存使用监控
  void logMemoryUsage([String? tag]) {
    if (kDebugMode) {
      print('Memory Usage ${tag ?? ''}: ${_getMemoryInfo()}');
    }
  }

  String _getMemoryInfo() {
    // 这里可以添加更详细的内存信息获取逻辑
    return 'Image Cache: ${_imageCache.length} items';
  }

  /// 清理资源
  void dispose() {
    _imageCache.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _throttleTimer?.cancel();
  }
}

/// 分页加载助手
class PaginationHelper<T> {
  final List<T> _allItems = [];
  final List<T> _currentItems = [];
  final int pageSize;
  int _currentPage = 0;

  PaginationHelper({this.pageSize = 20});

  List<T> get currentItems => List.unmodifiable(_currentItems);
  bool get hasMore => _currentPage * pageSize < _allItems.length;
  int get totalItems => _allItems.length;
  int get currentPage => _currentPage;

  void setAllItems(List<T> items) {
    _allItems.clear();
    _allItems.addAll(items);
    _currentItems.clear();
    _currentPage = 0;
    _loadNextPage();
  }

  void loadNextPage() {
    if (hasMore) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    final startIndex = _currentPage * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _allItems.length);
    
    if (startIndex < _allItems.length) {
      _currentItems.addAll(_allItems.sublist(startIndex, endIndex));
      _currentPage++;
    }
  }

  void reset() {
    _currentItems.clear();
    _currentPage = 0;
    if (_allItems.isNotEmpty) {
      _loadNextPage();
    }
  }

  void clear() {
    _allItems.clear();
    _currentItems.clear();
    _currentPage = 0;
  }
}

/// 懒加载助�?
class LazyLoader<T> {
  final Future<T> Function() _loader;
  Future<T>? _future;
  T? _cachedValue;
  bool _isLoading = false;

  LazyLoader(this._loader);

  Future<T> get value {
    if (_cachedValue != null) {
      return Future.value(_cachedValue!);
    }
    
    if (_future != null) {
      return _future!;
    }

    _isLoading = true;
    _future = _loader().then((value) {
      _cachedValue = value;
      _isLoading = false;
      return value;
    }).catchError((error) {
      _isLoading = false;
      _future = null;
      throw error;
    });

    return _future!;
  }

  bool get isLoaded => _cachedValue != null;
  bool get isLoading => _isLoading;

  void invalidate() {
    _cachedValue = null;
    _future = null;
    _isLoading = false;
  }
}

/// 性能监测�?
class PerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};

  static void startTimer(String name) {
    _stopwatches[name] = Stopwatch()..start();
  }

  static void endTimer(String name) {
    final stopwatch = _stopwatches[name];
    if (stopwatch != null) {
      stopwatch.stop();
      if (kDebugMode) {
        print('Performance [$name]: ${stopwatch.elapsedMilliseconds}ms');
      }
      _stopwatches.remove(name);
    }
  }

  static void measure(String name, VoidCallback callback) {
    startTimer(name);
    try {
      callback();
    } finally {
      endTimer(name);
    }
  }

  static Future<T> measureAsync<T>(String name, Future<T> Function() callback) async {
    startTimer(name);
    try {
      return await callback();
    } finally {
      endTimer(name);
    }
  }
}

/// 内存池管�?
class ObjectPool<T> {
  final List<T> _pool = [];
  final T Function() _factory;
  final void Function(T)? _reset;
  final int maxSize;

  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    this.maxSize = 10,
  }) : _factory = factory, _reset = reset;

  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    return _factory();
  }

  void release(T object) {
    if (_pool.length < maxSize) {
      _reset?.call(object);
      _pool.add(object);
    }
  }

  void clear() {
    _pool.clear();
  }

  int get poolSize => _pool.length;
}

/// 批量操作助手
class BatchProcessor<T> {
  final List<T> _batch = [];
  final Future<void> Function(List<T>) _processor;
  final int batchSize;
  final Duration flushInterval;
  Timer? _flushTimer;

  BatchProcessor({
    required Future<void> Function(List<T>) processor,
    this.batchSize = 50,
    this.flushInterval = const Duration(seconds: 5),
  }) : _processor = processor;

  void add(T item) {
    _batch.add(item);
    
    if (_batch.length >= batchSize) {
      flush();
    } else {
      _scheduleFlush();
    }
  }

  void addAll(List<T> items) {
    _batch.addAll(items);
    
    if (_batch.length >= batchSize) {
      flush();
    } else {
      _scheduleFlush();
    }
  }

  Future<void> flush() async {
    if (_batch.isEmpty) return;

    _flushTimer?.cancel();
    _flushTimer = null;

    final currentBatch = List<T>.from(_batch);
    _batch.clear();

    try {
      await _processor(currentBatch);
    } catch (e) {
      // 处理失败时，可以选择重新加入队列或记录错�?
      if (kDebugMode) {
        print('Batch processing failed: $e');
      }
    }
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(flushInterval, flush);
  }

  Future<void> dispose() async {
    await flush();
    _flushTimer?.cancel();
  }

  int get pendingCount => _batch.length;
}

/// 预加载管理器
class PreloadManager {
  final Map<String, Future<dynamic>> _preloadTasks = {};
  final int maxConcurrentTasks;
  int _runningTasks = 0;

  PreloadManager({this.maxConcurrentTasks = 3});

  Future<T> preload<T>(String key, Future<T> Function() loader) {
    if (_preloadTasks.containsKey(key)) {
      return _preloadTasks[key] as Future<T>;
    }

    if (_runningTasks >= maxConcurrentTasks) {
      // 如果任务太多，延迟执�?
      return Future.delayed(const Duration(milliseconds: 100))
          .then((_) => preload(key, loader));
    }

    _runningTasks++;
    final future = loader().whenComplete(() {
      _runningTasks--;
      _preloadTasks.remove(key);
    });

    _preloadTasks[key] = future;
    return future;
  }

  void cancelPreload(String key) {
    _preloadTasks.remove(key);
  }

  void cancelAll() {
    _preloadTasks.clear();
    _runningTasks = 0;
  }

  int get runningTasksCount => _runningTasks;
  int get pendingTasksCount => _preloadTasks.length;
}
