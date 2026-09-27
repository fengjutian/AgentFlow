/// MCP stdio client — communicates with an MCP server over a ProcessSession.
///
/// The stdio transport is used for local MCP servers (e.g. `npx -y @modelcontextprotocol/server-filesystem`)
/// and remote servers running over SSH. JSON-RPC messages are sent as
/// newline-delimited JSON on stdin and received on stdout.
library;

import 'dart:async';
import 'dart:convert';

import '../../runtime/runtime.dart';
import 'json_rpc.dart';
import 'mcp_client.dart';

/// MCP client using stdio transport over a [ProcessSession].
///
/// Protocol:
/// - Requests are written as single-line JSON + newline to stdin.
/// - Responses are read as single-line JSON from stdout.
/// - Notifications (no `id`) from the server are logged but not matched.
class McpStdioClient {
  McpStdioClient({
    required this.session,
    this.timeout = const Duration(seconds: 30),
    this.maxResponseSize = 10 * 1024 * 1024, // 10 MB
  });

  final ProcessSession session;
  final Duration timeout;

  /// Maximum size of a single response line in bytes.
  final int maxResponseSize;

  int _nextId = 1;
  bool _initialized = false;
  McpCapabilities _capabilities = const McpCapabilities();

  final Map<dynamic, Completer<JsonRpcMessage>> _pending = {};
  StreamSubscription<String>? _stdoutSub;
  final StringBuffer _lineBuffer = StringBuffer();

  /// Whether the client has completed the initialize handshake.
  bool get isInitialized => _initialized;

  /// Server capabilities discovered during initialization.
  McpCapabilities get capabilities => _capabilities;

  /// Performs the MCP initialize handshake over stdio.
  Future<void> initialize() async {
    if (_initialized) return;

    // Start listening for responses before sending the first request.
    _startListening();

    final response = await _send(JsonRpcRequest(
      id: _nextId++,
      method: 'initialize',
      params: <String, dynamic>{
        'protocolVersion': '2025-06-18',
        'capabilities': <String, dynamic>{},
        'clientInfo': <String, dynamic>{
          'name': 'AgentFlow',
          'version': '1.0.0',
        },
      },
    ));

    if (response.isError) {
      throw response.error!;
    }

    final result = response.response!.result as Map<String, dynamic>?;
    _capabilities = McpCapabilities.fromJson(
        result?['capabilities'] as Map<String, dynamic>?);

    // Send initialized notification.
    await _sendNotification(
        JsonRpcNotification(method: 'notifications/initialized'));
    _initialized = true;
  }

  /// Discovers available tools via tools/list.
  Future<List<McpTool>> listTools() async {
    _ensureInitialized();
    final response = await _send(JsonRpcRequest(
      id: _nextId++,
      method: 'tools/list',
    ));

    if (response.isError) {
      throw response.error!;
    }

    final result = response.response!.result as Map<String, dynamic>?;
    final toolsList = (result?['tools'] as List<dynamic>?)
            ?.map((e) => McpTool.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <McpTool>[];
    return toolsList;
  }

  /// Calls an MCP tool with the given arguments.
  Future<McpToolResult> callTool(
      String name, Map<String, dynamic> arguments) async {
    _ensureInitialized();
    final response = await _send(JsonRpcRequest(
      id: _nextId++,
      method: 'tools/call',
      params: <String, dynamic>{
        'name': name,
        'arguments': arguments,
      },
    ));

    if (response.isError) {
      throw response.error!;
    }

    final result = response.response!.result as Map<String, dynamic>?;
    return McpToolResult.fromJson(result ?? <String, dynamic>{});
  }

  /// Closes the client and terminates the process.
  Future<void> close() async {
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    // Cancel any pending requests.
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Client closed.'));
      }
    }
    _pending.clear();
    await session.terminate();
    _initialized = false;
  }

  /// Sends a `$/cancelRequest` notification to cancel an in-flight request.
  ///
  /// The MCP server may or may not honor the cancellation. This is a
  /// best-effort notification, not a guaranteed abort.
  Future<void> cancelRequest(int requestId) async {
    await _sendNotification(JsonRpcNotification(
      method: r'$/cancelRequest',
      params: <String, dynamic>{'id': requestId},
    ));
    // Also remove the pending completer so it doesn't block forever.
    final completer = _pending.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        StateError('Request $requestId cancelled by client.'),
      );
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('MCP stdio client not initialized. Call initialize() first.');
    }
  }

  void _startListening() {
    _stdoutSub = session.stdout.listen(
      (String chunk) {
        _lineBuffer.write(chunk);
        _processLines();
      },
      onError: (Object error) {
        // Fail all pending requests on stream error.
        for (final completer in _pending.values) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        }
        _pending.clear();
      },
      onDone: () {
        // Process exited — fail all pending requests.
        for (final completer in _pending.values) {
          if (!completer.isCompleted) {
            completer.completeError(
                StateError('MCP server process exited.'));
          }
        }
        _pending.clear();
      },
    );
  }

  void _processLines() {
    final content = _lineBuffer.toString();
    final lines = content.split('\n');
    // The last element may be an incomplete line — keep it in the buffer.
    _lineBuffer
      ..clear()
      ..write(lines.last);

    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      _handleLine(line);
    }
  }

  void _handleLine(String line) {
    try {
      // Enforce response size limit.
      if (line.length > maxResponseSize) {
        return; // Drop oversized responses silently.
      }
      final json = jsonDecode(line) as Map<String, dynamic>;

      // Notifications have no id — skip them.
      if (!json.containsKey('id') || json['id'] == null) return;

      final message = JsonRpcMessage.fromJson(json);
      final id = message.response?.id ?? message.error?.id;
      final completer = _pending.remove(id);
      if (completer != null && !completer.isCompleted) {
        completer.complete(message);
      }
    } catch (_) {
      // Skip malformed lines (could be server stderr leaking to stdout).
    }
  }

  Future<JsonRpcMessage> _send(JsonRpcRequest request) async {
    final completer = Completer<JsonRpcMessage>();
    _pending[request.id] = completer;

    final json = jsonEncode(request.toJson());
    await session.writeStdin('$json\n');

    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(request.id);
      throw TimeoutException(
          'MCP stdio request ${request.id} timed out.', timeout);
    });
  }

  Future<void> _sendNotification(JsonRpcNotification notification) async {
    final json = jsonEncode(notification.toJson());
    await session.writeStdin('$json\n');
  }
}
