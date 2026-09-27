import 'dart:io';

import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/code/code_tools.dart';
import 'package:agentflow/tools/filesystem/file_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late LocalRuntime runtime;
  late ToolContext ctx;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('agentflow_tools_test');
    File('${tmp.path}${Platform.pathSeparator}hello.txt')
        .writeAsStringSync('Hello world\nsecond line\n');
    Directory('${tmp.path}${Platform.pathSeparator}lib').createSync();
    File('${tmp.path}${Platform.pathSeparator}lib${Platform.pathSeparator}main.dart')
        .writeAsStringSync('void main() {\n  print("hi");\n}\n');
    runtime = LocalRuntime(rootDirectory: tmp.path);
    ctx = ToolContext(runtime: runtime, workingDirectory: tmp.path);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('list_files', () {
    test('enumerates entries and marks directories', () async {
      final result = await ListFilesTool().execute(<String, dynamic>{'path': '.'}, ctx);
      expect(result.isError, isFalse);
      expect(result.content, contains('hello.txt'));
      expect(result.content, contains('lib/'));
      final files = result.data!['files'] as List;
      expect(
        files.any((dynamic f) =>
            (f as Map)['name'] == 'lib' && f['type'] == 'directory'),
        isTrue,
      );
    });

    test('empty directory is reported, not an error', () async {
      Directory('${tmp.path}${Platform.pathSeparator}empty').createSync();
      final result = await ListFilesTool()
          .execute(<String, dynamic>{'path': 'empty'}, ctx);
      expect(result.isError, isFalse);
      expect(result.content, contains('empty directory'));
    });
  });

  group('read_file', () {
    test('returns the file content', () async {
      final result =
          await ReadFileTool().execute(<String, dynamic>{'path': 'hello.txt'}, ctx);
      expect(result.isError, isFalse);
      expect(result.content, contains('Hello world'));
    });

    test('honours a line range slice', () async {
      final result = await ReadFileTool().execute(
        <String, dynamic>{'path': 'hello.txt', 'startLine': 2, 'endLine': 2},
        ctx,
      );
      expect(result.content, contains('second line'));
      expect(result.content, isNot(contains('Hello world')));
    });

    test('a missing file raises ToolExecutionException', () {
      expect(
        () => ReadFileTool().execute(<String, dynamic>{'path': 'nope.txt'}, ctx),
        throwsA(isA<ToolExecutionException>()),
      );
    });
  });

  group('write_file', () {
    test('creates a new file and returns a diff payload', () async {
      final result = await WriteFileTool().execute(
        <String, dynamic>{'path': 'out/new.txt', 'content': 'line1\nline2\n'},
        ctx,
      );
      final created =
          File('${tmp.path}${Platform.pathSeparator}out${Platform.pathSeparator}new.txt');
      expect(created.existsSync(), isTrue);
      expect(created.readAsStringSync(), 'line1\nline2\n');
      expect(result.data!['diff'], isNotNull);
      expect(result.data!['isNewFile'], isTrue);
      expect(result.content, contains('Created'));
    });

    test('overwriting reports Updated with add/remove counts', () async {
      final result = await WriteFileTool().execute(
        <String, dynamic>{'path': 'hello.txt', 'content': 'Hello world\nchanged\n'},
        ctx,
      );
      expect(result.content, contains('Updated'));
      expect(result.data!['isNewFile'], isFalse);
    });

    test('preview does not touch disk and committed change can be undone', () async {
      final tool = WriteFileTool();
      final preview = await tool.preview(
        <String, dynamic>{'path': 'hello.txt', 'content': 'replacement\n'},
        ctx,
      );
      expect(File('${tmp.path}${Platform.pathSeparator}hello.txt').readAsStringSync(),
          'Hello world\nsecond line\n');
      expect(preview.data['diff'], isNotNull);

      final result = await tool.executePrepared(
        <String, dynamic>{'path': 'hello.txt', 'content': 'replacement\n'},
        ctx,
        preview,
      );
      expect(File('${tmp.path}${Platform.pathSeparator}hello.txt').readAsStringSync(),
          'replacement\n');
      final message =
          await fileChangeJournal.undo(result.data!['transactionId'] as String);
      expect(message, contains('Undid'));
      expect(File('${tmp.path}${Platform.pathSeparator}hello.txt').readAsStringSync(),
          'Hello world\nsecond line\n');
    });

    test('undo refuses to overwrite a later manual edit', () async {
      final result = await WriteFileTool().execute(
        <String, dynamic>{'path': 'hello.txt', 'content': 'agent edit\n'},
        ctx,
      );
      File('${tmp.path}${Platform.pathSeparator}hello.txt')
          .writeAsStringSync('manual edit\n');
      expect(
        () => fileChangeJournal.undo(result.data!['transactionId'] as String),
        throwsA(isA<ToolExecutionException>()),
      );
      expect(File('${tmp.path}${Platform.pathSeparator}hello.txt').readAsStringSync(),
          'manual edit\n');
    });
  });

  group('search_code', () {
    test('finds matches and respects fileGlob', () async {
      final result = await SearchCodeTool().execute(
        <String, dynamic>{'pattern': r'void\s+main', 'fileGlob': '*.dart'},
        ctx,
      );
      expect(result.isError, isFalse);
      expect(result.content, contains('main.dart'));
      final count = (result.data!['count'] as num).toInt();
      expect(count, greaterThanOrEqualTo(1));
    });

    test('searches all text files when no glob is given', () async {
      final result = await SearchCodeTool()
          .execute(<String, dynamic>{'pattern': 'Hello world'}, ctx);
      expect(result.content, contains('hello.txt'));
    });

    test('reports no matches cleanly', () async {
      final result = await SearchCodeTool()
          .execute(<String, dynamic>{'pattern': 'zzz_not_present_zzz'}, ctx);
      expect(result.content, contains('No matches'));
    });

    test('an invalid regular expression is a tool error, not a crash', () {
      expect(
        () => SearchCodeTool().execute(<String, dynamic>{'pattern': '('}, ctx),
        throwsA(isA<ToolExecutionException>()),
      );
    });
  });
}
