import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agentflow/core/mcp/mcp_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal fake MCP server that handles initialize, tools/list and tools/call.
class _FakeMcpServer {
  _FakeMcpServer(this._server);

  final HttpServer _server;
  final List<Map<String, dynamic>> receivedRequests = [];

  /// Tools the fake server advertises.
  List<Map<String, dynamic>> tools = [
    {
      'name': 'echo',
      'description': 'Echoes back the input.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'message': {'type': 'string'},
        },
      },
    },
    {
      'name': 'add',
      'description': 'Adds two numbers.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'a': {'type': 'number'},
          'b': {'type': 'number'},
        },
      },
    },
  ];

  /// If set, the next tools/call returns this error.
  String? toolError;

  String get endpoint => 'http://127.0.0.1:${_server.port}/mcp';

  Future<void> serve() async {
    await for (final request in _server) {
      final body = await utf8.decoder.bind(request).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      receivedRequests.add(json);

      final method = json['method'] as String?;
      final id = json['id'];

      if (method == 'initialize') {
        _respond(request, id, {
          'protocolVersion': '2025-06-18',
          'capabilities': {'tools': {'listChanged': true}},
          'serverInfo': {'name': 'fake-mcp-server', 'version': '0.1.0'},
        });
      } else if (method == 'notifications/initialized') {
        // Notification — no response needed.
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write('')
          ..close();
      } else if (method == 'tools/list') {
        _respond(request, id, {'tools': tools});
      } else if (method == 'tools/call') {
        final params = json['params'] as Map<String, dynamic>? ?? {};
        final toolName = params['name'] as String? ?? '';
        final args = params['arguments'] as Map<String, dynamic>? ?? {};

        if (toolError != null) {
          _respondError(request, id, -32603, toolError!);
          continue;
        }

        if (toolName == 'echo') {
          final message = args['message'] ?? '';
          _respond(request, id, {
            'content': [
              {'type': 'text', 'text': 'Echo: $message'},
            ],
          });
        } else if (toolName == 'add') {
          final a = (args['a'] as num?) ?? 0;
          final b = (args['b'] as num?) ?? 0;
          _respond(request, id, {
            'content': [
              {'type': 'text', 'text': '${a + b}'},
            ],
          });
        } else {
          _respondError(request, id, -32601, 'Unknown tool: $toolName');
        }
      } else {
        _respondError(request, id, -32601, 'Method not found: $method');
      }
    }
  }

  void _respond(HttpRequest request, dynamic id, dynamic result) {
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      }))
      ..close();
  }

  void _respondError(HttpRequest request, dynamic id, int code, String message) {
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': code, 'message': message},
      }))
      ..close();
  }

  Future<void> close() async {
    await _server.close(force: true);
  }
}

void main() {
  late HttpServer httpServer;
  late _FakeMcpServer fakeServer;
  late McpHttpClient client;

  setUp(() async {
    httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    fakeServer = _FakeMcpServer(httpServer);
    // Start serving in the background.
    unawaited(fakeServer.serve());
  });

  tearDown(() async {
    client.close();
    await fakeServer.close();
  });

  group('MCP HTTP integration', () {
    test('full lifecycle: initialize → listTools → callTool', () async {
      client = McpHttpClient(
        endpoint: fakeServer.endpoint,
        timeout: const Duration(seconds: 5),
      );

      // Initialize handshake.
      await client.initialize();
      expect(client.isInitialized, isTrue);
      expect(client.capabilities.tools, isTrue);

      // Verify the server received initialize + notification.
      expect(fakeServer.receivedRequests.length, greaterThanOrEqualTo(1));
      expect(fakeServer.receivedRequests.first['method'], 'initialize');

      // List tools.
      final tools = await client.listTools();
      expect(tools, hasLength(2));
      expect(tools[0].name, 'echo');
      expect(tools[0].description, contains('Echo'));
      expect(tools[1].name, 'add');

      // Call echo tool.
      final echoResult = await client.callTool('echo', {'message': 'hello'});
      expect(echoResult.isError, isFalse);
      expect(echoResult.text, 'Echo: hello');

      // Call add tool.
      final addResult = await client.callTool('add', {'a': 3, 'b': 7});
      expect(addResult.isError, isFalse);
      expect(addResult.text, '10');
    });

    test('callTool with unknown tool returns error', () async {
      client = McpHttpClient(
        endpoint: fakeServer.endpoint,
        timeout: const Duration(seconds: 5),
      );
      await client.initialize();

      // The server returns a JSON-RPC error for unknown tools.
      expect(
        () => client.callTool('nonexistent', {}),
        throwsA(isA<Exception>()),
      );
    });

    test('server error is reported to client', () async {
      client = McpHttpClient(
        endpoint: fakeServer.endpoint,
        timeout: const Duration(seconds: 5),
      );
      await client.initialize();

      fakeServer.toolError = 'Internal tool failure';

      expect(
        () => client.callTool('echo', {'message': 'test'}),
        throwsA(isA<Exception>()),
      );
    });

    test('tools/list after tool list changes returns updated tools', () async {
      client = McpHttpClient(
        endpoint: fakeServer.endpoint,
        timeout: const Duration(seconds: 5),
      );
      await client.initialize();

      // Initial list.
      final initial = await client.listTools();
      expect(initial, hasLength(2));

      // Simulate tool list change on the server.
      fakeServer.tools = [
        {
          'name': 'new_tool',
          'description': 'A new tool.',
          'inputSchema': {'type': 'object'},
        },
      ];

      // Refresh.
      final updated = await client.listTools();
      expect(updated, hasLength(1));
      expect(updated[0].name, 'new_tool');
    });

    test('response size limit rejects oversized payloads', () async {
      client = McpHttpClient(
        endpoint: fakeServer.endpoint,
        timeout: const Duration(seconds: 5),
        maxResponseSize: 200, // Large enough for initialize, too small for tools/list.
      );
      await client.initialize();

      // Add many tools to make the tools/list response exceed 200 bytes.
      fakeServer.tools = List.generate(20, (i) => {
        'name': 'tool_$i',
        'description': 'A tool with a long description for testing purposes.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'param1': {'type': 'string', 'description': 'A long parameter description'},
          },
        },
      });

      // tools/list will exceed the 200-byte limit.
      expect(
        () => client.listTools(),
        throwsA(isA<Exception>()),
      );
    });

    test('multiple sequential callTool invocations work correctly', () async {
      client = McpHttpClient(
        endpoint: fakeServer.endpoint,
        timeout: const Duration(seconds: 5),
      );
      await client.initialize();

      for (var i = 0; i < 5; i++) {
        final result = await client.callTool('add', {'a': i, 'b': i});
        expect(result.text, '${i + i}');
      }
    });

    test('close prevents further calls', () async {
      client = McpHttpClient(
        endpoint: fakeServer.endpoint,
        timeout: const Duration(seconds: 5),
      );
      await client.initialize();
      client.close();

      expect(client.isInitialized, isFalse);
      expect(
        () => client.listTools(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
