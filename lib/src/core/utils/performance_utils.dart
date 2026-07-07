import 'package:flutter/scheduler.dart';

/// Performance optimization utilities.
class PerformanceUtils {
  PerformanceUtils._();

  /// Debounce function - tez-tez chaqirilgan funksiyalarni optimallashtirish uchun
  static final Map<String, DateTime> _lastCallTimes = {};

  static bool shouldThrottle(
    String key, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final now = DateTime.now();
    final lastCall = _lastCallTimes[key];

    if (lastCall == null || now.difference(lastCall) > duration) {
      _lastCallTimes[key] = now;
      return false;
    }
    return true;
  }

  /// Frame callback optimization
  static void runAfterBuild(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// Memory cleanup
  static void clearThrottleCache() {
    _lastCallTimes.clear();
  }
}

/// Optimized Memoization for expensive computations
class Memoizer<T, R> {
  final Map<T, R> _cache = {};
  final R Function(T) _computation;

  Memoizer(this._computation);

  R call(T input) {
    if (_cache.containsKey(input)) {
      return _cache[input] as R;
    }
    final result = _computation(input);
    _cache[input] = result;
    return result;
  }

  void clear() => _cache.clear();
}
