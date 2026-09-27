import 'dart:async';
import 'dart:convert';

import 'package:agentflow/core/log_sanitizer.dart';
import 'package:agentflow/core/mcp/mcp_stdio_client.dart';
import 'package:agentflow/runtime/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mock ProcessSession that simulates an MCP server over stdio.
///
/// Responds to JSON-RPC requests with predefined responses. Supports the
/// standard MCP lifecycle: initialize, notifications/initialized, tools/list,
/// tools/call.
class _MockMcpProcessSession implements ProcessSession {
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
    // Parse the incoming JSON-RPC request and respond.
    final lines = data.split('\n').where((l) => l.trim().isNotEmpty);
    for (final line in lines) {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final id = json['id'];
      final method = json['method'] as String?;

      // Notifications have no id — no response needed.
      if (id == null) continue;

      Map<String, dynamic> response;

      switch (method) {
        case 'initialize':
          response = <String, dynamic>{
            'jsonrpc': '2.0',
            'id': id,
            'result': <String, dynamic>{
              'protocolVersion': '2025-06-18',
              'capabilities': <String, dynamic>{
                'tools': <String, dynamic>{'listChanged': true},
              },
              'serverInfo': <String, dynamic>{
                'name': 'mock-mcp-server',
                'version': '1.0.0',
              },
            },
          };
        case 'tools/list':
          response = <String, dynamic>{
            'jsonrpc': '2.0',
            'id': id,
            'result': <String, dynamic>{
              'tools': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'greet',
                  'description': 'Greets a person by name.',
                  'inputSchema': <String, dynamic>{
                    'type': 'object',
                    'properties': <String, dynamic>{
                      'name': <String, dynamic>{
                        'type': 'string',
                        'description': 'Name to greet',
                      },
                    },
                    'required': <String>['name'],
                  },
                },
                <String, dynamic>{
                  'name': 'add',
                  'description': 'Adds two numbers.',
                  'inputSchema': <String, dynamic>{
                    'type': 'object',
                    'properties': <String, dynamic>{
                      'a': <String, dynamic>{'type': 'number'},
                      'b': <String, dynamic>{'type': 'number'},
                    },
                    'required': <String>['a', 'b'],
                  },
                },
              ],
            },
          };
        case 'tools/call':
          final params = json['params'] as Map<String, dynamic>?;
          final toolName = params?['name'] as String?;
          final args = params?['arguments'] as Map<String, dynamic>? ?? {};
          String resultText;
          if (toolName == 'greet') {
            resultText = 'Hello, ${args['name']}!';
          } else if (toolName == 'add') {
            final sum = (args['a'] as num) + (args['b'] as num);
            resultText = 'Result: $sum';
          } else {
            resultText = 'Unknown tool: $toolName';
          }
          response = <String, dynamic>{
            'jsonrpc': '2.0',
            'id': id,
            'result': <String, dynamic>{
              'content': <Map<String, dynamic>>[
                <String, dynamic>{'type': 'text', 'text': resultText},
              ],
            },
          };
        default:
          response = <String, dynamic>{
            'jsonrpc': '2.0',
            'id': id,
            'error': <String, dynamic>{
              'code': -32601,
              'message': 'Method not found: $method',
            },
          };
      }

      // Simulate async response with a small delay.
      Future<void>.delayed(const Duration(milliseconds: 10), () {
        if (!_stdout.isClosed) {
          _stdout.add('${jsonEncode(response)}\n');
        }
      });
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
}

void main() {
  group('McpStdioClient', () {
    test('initialize handshake completes successfully', () async {
      final session = _MockMcpProcessSession();
      final client = McpStdioClient(session: session);

      await client.initialize();
      expect(client.isInitialized, isTrue);
      expect(client.capabilities.tools, isTrue);

      await client.close();
    });

    test('listTools returns discovered tools', () async {
      final session = _MockMcpProcessSession();
      final client = McpStdioClient(session: session);

      await client.initialize();
      final tools = await client.listTools();

      expect(tools, hasLength(2));
      expect(tools[0].name, 'greet');
      expect(tools[1].name, 'add');
      expect(tools[0].description, 'Greets a person by name.');

      await client.close();
    });

    test('callTool returns tool result', () async {
      final session = _MockMcpProcessSession();
      final client = McpStdioClient(session: session);

      await client.initialize();
      final result = await client.callTool(
        'greet',
        <String, dynamic>{'name': 'World'},
      );

      expect(result.isError, isFalse);
      expect(result.text, 'Hello, World!');

      await client.close();
    });

    test('callTool with numeric arguments', () async {
      final session = _MockMcpProcessSession();
      final client = McpStdioClient(session: session);

      await client.initialize();
      final result = await client.callTool(
        'add',
        <String, dynamic>{'a': 3, 'b': 4},
      );

      expect(result.isError, isFalse);
      expect(result.text, 'Result: 7');

      await client.close();
    });

    test('tool adapters wrap stdio tools correctly', () async {
      final session = _MockMcpProcessSession();
      final client = McpStdioClient(session: session);

      await client.initialize();
      final tools = await client.listTools();

      // Verify tool metadata.
      expect(tools.length, greaterThanOrEqualTo(1));
      final greet = tools.firstWhere((t) => t.name == 'greet');
      expect(greet.inputSchema['type'], 'object');
      expect(greet.inputSchema['properties'], isNotNull);

      await client.close();
    });
  });

  group('McpStdioClient error handling', () {
    test('throws StateError if not initialized', () async {
      final session = _MockMcpProcessSession();
      final client = McpStdioClient(session: session);

      expect(
        () => client.listTools(),
        throwsA(isA<StateError>()),
      );

      await client.close();
    });

    test('close terminates the process', () async {
      final session = _MockMcpProcessSession();
      final client = McpStdioClient(session: session);

      await client.initialize();
      await client.close();

      expect(session.isAlive, isFalse);
    });
  });

  group('Log sanitizer', () {
    test('sanitizeHeaders redacts Authorization', () {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer secret-token-123',
        'X-Custom': 'visible',
      };
      final sanitized = sanitizeHeaders(headers);
      expect(sanitized['Content-Type'], 'application/json');
      expect(sanitized['Authorization'], '[REDACTED]');
      expect(sanitized['X-Custom'], 'visible');
    });

    test('sanitizeHeaders redacts Cookie', () {
      final headers = <String, String>{
        'Cookie': 'session=abc123',
      };
      final sanitized = sanitizeHeaders(headers);
      expect(sanitized['Cookie'], '[REDACTED]');
    });
  });

  group('ProcessSession', () {
    test('ProcessConfig stores command and arguments', () {
      const config = ProcessConfig(
        command: 'node',
        arguments: ['server.js'],
        workingDirectory: '/tmp',
        environment: {'PORT': '3000'},
      );
      expect(config.command, 'node');
      expect(config.arguments, ['server.js']);
      expect(config.workingDirectory, '/tmp');
      expect(config.environment, {'PORT': '3000'});
    });
  });
}
