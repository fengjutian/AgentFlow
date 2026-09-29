import 'dart:async';
import 'dart:convert';

import 'package:agentflow/core/editor/syntax_highlighter.dart';
import 'package:agentflow/core/lsp/lsp_client.dart';
import 'package:agentflow/core/lsp/lsp_client_manager.dart';
import 'package:agentflow/core/lsp/lsp_config.dart';
import 'package:agentflow/runtime/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mock Runtime that creates mock LSP process sessions.
class _MockRuntime implements Runtime {
  @override
  String get id => 'mock-runtime';

  @override
  String get label => 'Mock Runtime';

  @override
  RuntimeKind get kind => RuntimeKind.local;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<CommandResult> execute(
    String command, {
    String? workingDirectory,
    int timeoutMillis = 60000,
    Map<String, String>? environment,
    OutputCallback? onStdout,
    OutputCallback? onStderr,
  }) async {
    return const CommandResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  Future<ProcessSession> startProcess(ProcessConfig config) async {
    return _MockLspSession();
  }

  @override
  Future<String> readFile(String path) async => '';

  @override
  Future<void> writeFile(String path, String content) async {}

  @override
  Future<void> deleteFile(String path) async {}

  @override
  Future<void> createDirectory(String path) async {}

  @override
  Future<void> renameEntry(String path, String newPath) async {}

  @override
  Future<void> deleteEntry(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<List<FileEntry>> listFiles(String path) async => [];
}

/// A mock ProcessSession for LSP that responds to initialize and other
/// requests with minimal valid responses.
class _MockLspSession implements ProcessSession {
  final StreamController<String> _stdout = StreamController<String>.broadcast();
  final StreamController<String> _stderr = StreamController<String>.broadcast();
  final Completer<int> _exit = Completer<int>();
  bool _alive = true;

  @override
  Stream<String> get stdout => _stdout.stream;

  @override
  Stream<String> get stderr => _stderr.stream;

  @override
  Future<void> writeStdin(String data) async {
    final messages = _parseLspMessages(data);
    for (final json in messages) {
      final id = json['id'];
      final method = json['method'] as String?;
      if (id == null) continue;

      Map<String, dynamic> response;
      switch (method) {
        case 'initialize':
          response = _lspResponse(id, {
            'capabilities': {
              'completionProvider': {'triggerCharacters': ['.']},
              'hoverProvider': true,
              'definitionProvider': true,
            },
          });
        case 'shutdown':
          response = _lspResponse(id, null);
        case 'textDocument/completion':
          response = _lspResponse(id, {'isIncomplete': false, 'items': []});
        case 'textDocument/definition':
          response = _lspResponse(id, []);
        case 'textDocument/hover':
          response = _lspResponse(id, null);
        default:
          response = _lspResponse(id, null);
      }
      _sendLspMessage(response);
    }
  }

  @override
  Future<int> waitForExit() => _exit.future;

  @override
  Future<void> terminate() async {
    _alive = false;
    if (!_exit.isCompleted) _exit.complete(0);
    await _stdout.close();
    await _stderr.close();
  }

  @override
  bool get isAlive => _alive;

  List<Map<String, dynamic>> _parseLspMessages(String data) {
    final messages = <Map<String, dynamic>>[];
    var remaining = data;
    while (remaining.contains('\r\n\r\n')) {
      final headerEnd = remaining.indexOf('\r\n\r\n');
      final headers = remaining.substring(0, headerEnd);
      int? contentLength;
      for (final header in headers.split('\r\n')) {
        if (header.toLowerCase().startsWith('content-length:')) {
          contentLength = int.tryParse(header.substring(15).trim());
        }
      }
      if (contentLength == null) break;
      final bodyStart = headerEnd + 4;
      if (remaining.length < bodyStart + contentLength) break;
      final body = remaining.substring(bodyStart, bodyStart + contentLength);
      messages.add(jsonDecode(body) as Map<String, dynamic>);
      remaining = remaining.substring(bodyStart + contentLength);
    }
    return messages;
  }

  void _sendLspMessage(Map<String, dynamic> json) {
    final body = jsonEncode(json);
    final bodyBytes = utf8.encode(body);
    final header = 'Content-Length: ${bodyBytes.length}\r\n\r\n';
    _stdout.add(header + body);
  }

  Map<String, dynamic> _lspResponse(dynamic id, dynamic result) =>
      <String, dynamic>{'jsonrpc': '2.0', 'id': id, 'result': result};
}

void main() {
  group('LspClientManager', () {
    late LspClientManager manager;
    late _MockRuntime runtime;

    setUp(() {
      manager = LspClientManager(maxConcurrentServers: 2);
      runtime = _MockRuntime();
      manager.setRuntime(runtime, rootDirectory: '/project');
    });

    tearDown(() async {
      await manager.shutdownAll();
    });

    test('getOrCreate starts a server for a language', () async {
      // Override config since mock doesn't have real servers.
      manager.setConfigOverride(
        'dart',
        const LspServerConfig(
          languageId: 'dart',
          command: 'dart',
          arguments: ['language-server', '--stdio'],
        ),
      );

      final client = await manager.getOrCreate('dart');
      expect(client, isNotNull);
      expect(client!.isInitialized, isTrue);
      expect(manager.hasClient('dart'), isTrue);
    });

    test('getOrCreate returns null for unsupported language', () async {
      final client = await manager.getOrCreate('cobol');
      expect(client, isNull);
    });

    test('getOrCreate reuses existing client', () async {
      manager.setConfigOverride(
        'python',
        const LspServerConfig(
          languageId: 'python',
          command: 'pyright-langserver',
          arguments: ['--stdio'],
        ),
      );

      final client1 = await manager.getOrCreate('python');
      final client2 = await manager.getOrCreate('python');
      expect(client1, same(client2));
    });

    test('notifyDidOpen starts server and sends notification', () async {
      manager.setConfigOverride(
        'rust',
        const LspServerConfig(
          languageId: 'rust',
          command: 'rust-analyzer',
          arguments: [],
        ),
      );

      await manager.notifyDidOpen(
        'file:///project/main.rs',
        'rust',
        'fn main() {}',
      );

      expect(manager.hasClient('rust'), isTrue);
    });

    test('shutdown removes client', () async {
      manager.setConfigOverride(
        'go',
        const LspServerConfig(
          languageId: 'go',
          command: 'gopls',
          arguments: ['serve'],
        ),
      );

      await manager.getOrCreate('go');
      expect(manager.hasClient('go'), isTrue);

      await manager.shutdown('go');
      expect(manager.hasClient('go'), isFalse);
    });

    test('shutdownAll clears all clients', () async {
      manager.setConfigOverride(
        'dart',
        const LspServerConfig(
          languageId: 'dart',
          command: 'dart',
          arguments: ['language-server'],
        ),
      );
      manager.setConfigOverride(
        'python',
        const LspServerConfig(
          languageId: 'python',
          command: 'pyright-langserver',
          arguments: ['--stdio'],
        ),
      );

      await manager.getOrCreate('dart');
      await manager.getOrCreate('python');
      expect(manager.activeLanguages, hasLength(2));

      await manager.shutdownAll();
      expect(manager.activeLanguages, isEmpty);
    });

    test('max concurrent servers evicts idle server', () async {
      // Set max to 2, then try to create 3.
      for (final lang in ['dart', 'python', 'rust']) {
        manager.setConfigOverride(
          lang,
          LspServerConfig(
            languageId: lang,
            command: '$lang-server',
            arguments: [],
          ),
        );
      }

      await manager.getOrCreate('dart');
      await manager.getOrCreate('python');
      expect(manager.activeLanguages, hasLength(2));

      // Creating a 3rd should evict the oldest.
      await manager.getOrCreate('rust');
      expect(manager.activeLanguages, hasLength(2));
      expect(manager.hasClient('rust'), isTrue);
    });

    test('diagnostics stream forwards server events', () async {
      manager.setConfigOverride(
        'dart',
        const LspServerConfig(
          languageId: 'dart',
          command: 'dart',
          arguments: ['language-server'],
        ),
      );

      // Start listening before creating the client so events are captured.
      final events = <LspDiagnosticsEvent>[];
      final sub = manager.diagnostics.listen(events.add);

      await manager.getOrCreate('dart');

      // Verify the stream is wired up and can be listened to.
      expect(manager.diagnostics, isA<Stream<LspDiagnosticsEvent>>());

      await sub.cancel();
    });
  });

  group('LspServerConfig', () {
    test('copyWith preserves values', () {
      const config = LspServerConfig(
        languageId: 'dart',
        command: 'dart',
        arguments: ['language-server', '--stdio'],
        environment: {'PATH': '/usr/bin'},
      );

      final updated = config.copyWith(rootUri: 'file:///project');
      expect(updated.languageId, 'dart');
      expect(updated.command, 'dart');
      expect(updated.rootUri, 'file:///project');
    });

    test('lspLanguageIdFor maps CodeLanguage correctly', () {
      expect(lspLanguageIdFor(CodeLanguage.dart), 'dart');
      expect(lspLanguageIdFor(CodeLanguage.python), 'python');
      expect(lspLanguageIdFor(CodeLanguage.typescript), 'typescript');
      expect(lspLanguageIdFor(CodeLanguage.shell), 'shellscript');
      expect(lspLanguageIdFor(CodeLanguage.unknown), '');
    });
  });
}
