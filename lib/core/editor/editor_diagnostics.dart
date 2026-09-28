library;

import 'editor_workspace.dart';

/// Parses common analyzer, compiler and test-runner location formats.
/// Unknown lines are ignored so callers can pass complete command output.
List<EditorDiagnostic> parseEditorDiagnostics(
  String output, {
  String? source,
  String basePath = '',
}) {
  final diagnostics = <EditorDiagnostic>[];
  for (final rawLine in output.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final analyzer = RegExp(
      r'^(error|warning|info)\s+-\s+(.+):(\d+):(\d+)\s+-\s+(.+?)(?:\s+-\s+[^\s]+)?$',
      caseSensitive: false,
    ).firstMatch(line);
    if (analyzer != null) {
      diagnostics.add(
        _diagnostic(
          path: analyzer.group(2)!,
          line: analyzer.group(3)!,
          column: analyzer.group(4)!,
          level: analyzer.group(1),
          message: analyzer.group(5)!,
          source: source,
          basePath: basePath,
        ),
      );
      continue;
    }

    final colon = RegExp(
      r'^(.+):(\d+):(\d+):\s*(?:(error|warning|info)\s*[:\-]?\s*)?(.+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (colon != null) {
      diagnostics.add(
        _diagnostic(
          path: colon.group(1)!,
          line: colon.group(2)!,
          column: colon.group(3)!,
          level: colon.group(4),
          message: colon.group(5)!,
          source: source,
          basePath: basePath,
        ),
      );
      continue;
    }

    final parenthesized = RegExp(
      r'^(.+)\((\d+),(\d+)\)\s*:\s*(?:(error|warning|info)[^:]*:\s*)?(.+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (parenthesized != null) {
      diagnostics.add(
        _diagnostic(
          path: parenthesized.group(1)!,
          line: parenthesized.group(2)!,
          column: parenthesized.group(3)!,
          level: parenthesized.group(4),
          message: parenthesized.group(5)!,
          source: source,
          basePath: basePath,
        ),
      );
    }
  }
  return diagnostics;
}

EditorDiagnostic _diagnostic({
  required String path,
  required String line,
  required String column,
  required String? level,
  required String message,
  required String? source,
  required String basePath,
}) =>
    EditorDiagnostic(
      message: message.trim(),
      location: EditorLocation(
        path: _resolvePath(path, basePath),
        line: int.parse(line),
        column: int.parse(column),
      ),
      severity: switch (level?.toLowerCase()) {
        'warning' => DiagnosticSeverity.warning,
        'info' => DiagnosticSeverity.information,
        _ => DiagnosticSeverity.error,
      },
      source: source,
    );

String _resolvePath(String path, String basePath) {
  final normalized = path.trim().replaceAll('\\', '/');
  final absolute = normalized.startsWith('/') ||
      RegExp(r'^[A-Za-z]:/').hasMatch(normalized);
  if (absolute || basePath.isEmpty) return normalized;
  final base = basePath.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  return '$base/$normalized';
}
