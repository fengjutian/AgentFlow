/// Visual theme for AgentFlow.
///
/// Material 3 with a seed-derived palette plus semantic colors for the Agent
/// Activity feed and diffs, so status is legible at a glance in both light and
/// dark mode.
library;

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF4F46E5); // indigo
  static const Color added = Color(0xFF2E7D32);
  static const Color removed = Color(0xFFC62828);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      listTileTheme: const ListTileThemeData(dense: true),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Monospace style used for code, diffs and terminal output.
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12.5,
    height: 1.35,
  );
}

/// Colors for Activity statuses.
extension ActivityColors on BuildContext {
  Color get doneColor => Colors.green.shade600;
  Color get runningColor => Theme.of(this).colorScheme.primary;
  Color get errorColor => AppTheme.removed;
  Color get pendingColor => Theme.of(this).colorScheme.outline;
}
