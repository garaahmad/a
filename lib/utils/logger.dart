import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static bool _isDebugMode = kDebugMode;
  static LogLevel _minimumLevel = LogLevel.debug;

  static void configure({
    bool? isDebugMode,
    LogLevel? minimumLevel,
  }) {
    if (isDebugMode != null) _isDebugMode = isDebugMode;
    if (minimumLevel != null) _minimumLevel = minimumLevel;
  }

  static void debug(String message, [dynamic error]) {
    _log(LogLevel.debug, message, error);
  }

  static void info(String message, [dynamic error]) {
    _log(LogLevel.info, message, error);
  }

  static void warning(String message, [dynamic error]) {
    _log(LogLevel.warning, message, error);
  }

  static void error(String message, [dynamic error]) {
    _log(LogLevel.error, message, error);
  }

  static void _log(LogLevel level, String message, [dynamic error]) {
    if (!_isDebugMode && level == LogLevel.debug) return;

    if (level.index < _minimumLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = _prefixForLevel(level);

    if (error != null) {
      debugPrint('$prefix [$timestamp] $message\nError: $error');
    } else {
      debugPrint('$prefix [$timestamp] $message');
    }
  }

  static String _prefixForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '  DEBUG';
      case LogLevel.info:
        return '   INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return '  ERROR';
    }
  }
}
