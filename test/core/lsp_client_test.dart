import 'dart:async';
import 'dart:convert';

import 'package:agentflow/core/editor/syntax_highlighter.dart';
import 'package:agentflow/core/lsp/lsp_client.dart';
import 'package:agentflow/runtime/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mock ProcessSession that simulates an LSP server over stdio.
///
/// Uses LSP message framing (Content-Length headers) and responds to
/// standard LSP requests: initialize, textDocument/completion,
/// textDocument/definition, textDocument/hover.
class _MockLspProcessSession implements ProcessSession {
  final StreamController<String> _stdout = StreamController<String>.broadcast();
  final StreamController<String> _stderr = StreamController<String>.broadcast();
  final Completer<int> _exit = Completer<int>();
  bool _alive = true;

  /// Records of notifications received from the client.
  final List<Map<String, dynamic>> notifications = [];

  @override
  Stream<String> get stdout => _stdout.stream;

  @override
  Stream<String> get stderr => _stderr.stream;

  @override
  Future<void> writeStdin(String data) async {
    // Parse LSP framed message: Content-Length: N\r\n\r\n{...}
    final messages = _parseLspMessages(data);
    for (final json in messages) {
      final id = json['id'];
      final method = json['method'] as String?;

      // Notifications (no id) — record them.
      if (id == null && method != null) {
        notifications.add(json);
        if (method == 'textDocument/publishDiagnostics') {
          // Server can push diagnostics — but this is client-side, skip.
        }
        continue;
      }

      if (id == null) continue;

      Map<String, dynamic> response;

      switch (method) {
        case 'initialize':
          response = _lspResponse(id, {
            'capabilities': {
              'completionProvider': {
                'triggerCharacters': ['.', ':'],
              },
              'hoverProvider': true,
              'definitionProvider': true,
            },
          });
        case 'shutdown':
          response = _lspResponse(id, null);
        case 'textDocument/completion':
          response = _lspResponse(id, {
            'isIncomplete': false,
            'items': [
              {
                'label': 'print',
                'kind': 3,
                'detail': 'void print(Object? object)',
                'documentation': 'Prints to console.',
              },
              {
                'label': 'println',
                'kind': 3,
                'detail': 'void println()',
              },
            ],
          });
        case 'textDocument/definition':
          response = _lspResponse(id, {
            'uri': 'file:///project/other.dart',
            'range': {
              'start': {'line': 5, 'character': 0},
              'end': {'line': 5, 'character': 10},
            },
          });
        case 'textDocument/hover':
          response = _lspResponse(id, {
            'contents': {
              'kind': 'markdown',
              'value': '```dart\nvoid print(Object? object)\n```\nPrints to console.',
            },
          });
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

  /// Sends a notification from the mock server to the client.
  void pushNotification(String method, Map<String, dynamic> params) {
    final msg = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    };
    _sendLspMessage(msg);
  }

  // -- LSP framing helpers --

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
      <String, dynamic>{
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      };
}

void main() {
  group('LspClient', () {
    late _MockLspProcessSession mockSession;
    late LspClient client;

    setUp(() {
      mockSession = _MockLspProcessSession();
      client = LspClient(
        session: mockSession,
        timeout: const Duration(seconds: 5),
      );
    });

    tearDown(() async {
      await client.close();
    });

    test('initialize handshake completes and reports capabilities', () async {
      await client.initialize(rootUri: 'file:///project');

      expect(client.isInitialized, isTrue);
      expect(client.capabilities.completionProvider, isTrue);
      expect(client.capabilities.hoverProvider, isTrue);
      expect(client.capabilities.definitionProvider, isTrue);
      expect(
        client.capabilities.completionTriggerCharacters,
        contains('.'),
      );
    });

    test('didOpen sends notification with correct params', () async {
      await client.initialize(rootUri: 'file:///project');
      await client.didOpen(
        'file:///project/main.dart',
        'dart',
        'void main() {}',
      );

      final didOpen = mockSession.notifications
          .where((n) => n['method'] == 'textDocument/didOpen')
          .toList();
      expect(didOpen, hasLength(1));

      final doc =
          (didOpen.first['params'] as Map)['textDocument'] as Map;
      expect(doc['uri'], 'file:///project/main.dart');
      expect(doc['languageId'], 'dart');
      expect(doc['text'], 'void main() {}');
    });

    test('didChange sends full document sync', () async {
      await client.initialize(rootUri: 'file:///project');
      await client.didChange('file:///project/main.dart', 'void main() { print("hello"); }');

      final didChange = mockSession.notifications
          .where((n) => n['method'] == 'textDocument/didChange')
          .toList();
      expect(didChange, hasLength(1));

      final params = didChange.first['params'] as Map;
      final changes = params['contentChanges'] as List;
      expect(changes.first['text'], 'void main() { print("hello"); }');
    });

    test('completion returns parsed items', () async {
      await client.initialize(rootUri: 'file:///project');

      final result = await client.completion(
        'file:///project/main.dart',
        10,
        5,
      );

      expect(result.items, hasLength(2));
      expect(result.items[0].label, 'print');
      expect(result.items[0].kind, LspCompletionKind.function_);
      expect(result.items[0].detail, 'void print(Object? object)');
      expect(result.items[0].documentation, 'Prints to console.');
      expect(result.items[1].label, 'println');
    });

    test('definition returns parsed locations', () async {
      await client.initialize(rootUri: 'file:///project');

      final locations = await client.definition(
        'file:///project/main.dart',
        5,
        3,
      );

      expect(locations, hasLength(1));
      expect(locations[0].uri, 'file:///project/other.dart');
      expect(locations[0].range.start.line, 5);
    });

    test('hover returns parsed content', () async {
      await client.initialize(rootUri: 'file:///project');

      final hover = await client.hover(
        'file:///project/main.dart',
        10,
        3,
      );

      expect(hover, isNotNull);
      expect(hover!.contents, contains('void print'));
      expect(hover.contents, contains('Prints to console.'));
    });

    test('diagnostics notification is forwarded', () async {
      await client.initialize(rootUri: 'file:///project');

      final future = client.notifications.firstWhere(
        (n) => n.method == 'textDocument/publishDiagnostics',
      );

      mockSession.pushNotification('textDocument/publishDiagnostics', {
        'uri': 'file:///project/main.dart',
        'diagnostics': [
          {
            'range': {
              'start': {'line': 3, 'character': 0},
              'end': {'line': 3, 'character': 10},
            },
            'severity': 1,
            'message': 'Unused variable',
            'source': 'dart',
          },
        ],
      });

      final notification = await future;
      expect(notification.method, 'textDocument/publishDiagnostics');
      final params = notification.params;
      expect(params['uri'], 'file:///project/main.dart');
      final diagnostics = params['diagnostics'] as List;
      expect(diagnostics, hasLength(1));
      expect(diagnostics[0]['message'], 'Unused variable');
    });

    test('shutdown sends request and exit notification', () async {
      await client.initialize(rootUri: 'file:///project');
      await client.shutdown();

      expect(client.isShutdown, isTrue);
      final exitNotifs = mockSession.notifications
          .where((n) => n['method'] == 'exit')
          .toList();
      expect(exitNotifs, hasLength(1));
    });
  });

  group('LSP data types', () {
    test('LspPosition fromJson', () {
      final pos = LspPosition.fromJson({'line': 5, 'character': 10});
      expect(pos.line, 5);
      expect(pos.character, 10);
    });

    test('LspDiagnostic fromJson with severity mapping', () {
      final diag = LspDiagnostic.fromJson({
        'range': {
          'start': {'line': 1, 'character': 0},
          'end': {'line': 1, 'character': 5},
        },
        'severity': 2,
        'message': 'Possible null reference',
        'source': 'analyzer',
      });
      expect(diag.severity, LspDiagnosticSeverity.warning);
      expect(diag.message, 'Possible null reference');
      expect(diag.source, 'analyzer');
    });

    test('LspCompletionItem fromJson with markdown doc', () {
      final item = LspCompletionItem.fromJson({
        'label': 'myFunction',
        'kind': 3,
        'detail': 'int myFunction()',
        'documentation': {
          'kind': 'markdown',
          'value': 'Returns an integer.',
        },
      });
      expect(item.label, 'myFunction');
      expect(item.kind, LspCompletionKind.function_);
      expect(item.documentation, 'Returns an integer.');
      expect(item.effectiveInsertText, 'myFunction');
    });

    test('LspCompletionResult from list response', () {
      final result = LspCompletionResult.fromJson({
        'isIncomplete': true,
        'items': [
          {'label': 'foo', 'kind': 6},
          {'label': 'bar', 'kind': 1},
        ],
      });
      expect(result.isIncomplete, isTrue);
      expect(result.items, hasLength(2));
    });

    test('LspHoverResult from string contents', () {
      final hover = LspHoverResult.fromJson({
        'contents': 'Type: String',
      });
      expect(hover.contents, 'Type: String');
    });

    test('LspHoverResult from MarkupContent', () {
      final hover = LspHoverResult.fromJson({
        'contents': {
          'kind': 'markdown',
          'value': '**bold** text',
        },
      });
      expect(hover.contents, '**bold** text');
    });

    test('LspLocation fromJson', () {
      final loc = LspLocation.fromJson({
        'uri': 'file:///test.dart',
        'range': {
          'start': {'line': 10, 'character': 5},
          'end': {'line': 10, 'character': 15},
        },
      });
      expect(loc.uri, 'file:///test.dart');
      expect(loc.range.start.line, 10);
      expect(loc.range.end.character, 15);
    });
  });

  group('Bracket matching', () {
    test('findMatchingBracket finds paired parentheses', () {
      final match = findMatchingBracket('(hello)', 0);
      expect(match, isNotNull);
      expect(match!.openIndex, 0);
      expect(match.closeIndex, 6);
    });

    test('findMatchingBracket finds paired braces', () {
      final match = findMatchingBracket('{a: {b: c}}', 4);
      expect(match, isNotNull);
      expect(match!.openIndex, 4);
      expect(match.closeIndex, 9);
    });

    test('findMatchingBracket returns null for unmatched', () {
      final match = findMatchingBracket('(hello', 0);
      expect(match, isNull);
    });

    test('findMatchingBracket handles nested brackets', () {
      final match = findMatchingBracket('((a)(b))', 0);
      expect(match, isNotNull);
      expect(match!.openIndex, 0);
      expect(match.closeIndex, 7);
    });

    test('findMatchingBracket finds backward from closing bracket', () {
      final match = findMatchingBracket('(hello)', 6);
      expect(match, isNotNull);
      expect(match!.openIndex, 0);
      expect(match.closeIndex, 6);
    });
  });
}
