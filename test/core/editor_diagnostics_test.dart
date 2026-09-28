import 'package:agentflow/core/editor/editor_diagnostics.dart';
import 'package:agentflow/core/editor/editor_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Dart analyzer diagnostics', () {
    final result = parseEditorDiagnostics(
      'error - lib/main.dart:12:5 - Undefined name foo - undefined_identifier',
      source: 'dart analyze',
    );

    expect(result, hasLength(1));
    expect(result.single.location.path, 'lib/main.dart');
    expect(result.single.location.line, 12);
    expect(result.single.location.column, 5);
    expect(result.single.severity, DiagnosticSeverity.error);
    expect(result.single.message, 'Undefined name foo');
  });

  test('parses colon locations including Windows paths', () {
    final result = parseEditorDiagnostics(
      r'C:\project\lib\main.dart:7:3: warning: Unused value',
    );

    expect(result.single.location.path, 'C:/project/lib/main.dart');
    expect(result.single.severity, DiagnosticSeverity.warning);
  });

  test('parses parenthesized compiler locations and ignores other output', () {
    final result = parseEditorDiagnostics(
      'Building...\nmain.cpp(4,9): error C2065: undeclared identifier\nDone',
    );

    expect(result, hasLength(1));
    expect(result.single.location.line, 4);
    expect(result.single.message, 'undeclared identifier');
  });

  test('resolves relative locations against the command directory', () {
    final result = parseEditorDiagnostics(
      'main.dart:2:1: error: broken',
      basePath: 'packages/example',
    );

    expect(result.single.location.path, 'packages/example/main.dart');
  });
}
