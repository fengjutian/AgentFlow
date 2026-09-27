/// MCP HTTP client with streamable HTTP transport.
///
/// Implements the Model Context Protocol client lifecycle:
/// - initialize handshake
/// - tools/list discovery
/// - tools/call invocation
/// - Connection management with timeout and error handling
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'json_rpc.dart';

/// MCP server capabilities reported during initialization.
class McpCapabilities {
  const McpCapabilities({this.tools = false});

  final bool tools;

  factory McpCapabilities.fromJson(Map<String, dynamic>? json) =>
      McpCapabilities(tools: json?['tools']?['listChanged'] == true ||
          json?['tools'] != null);
}

/// An MCP tool definition discovered via tools/list.
class McpTool {
  const McpTool({
    required this.name,
    required this.description,
    this.inputSchema = const <String, dynamic>{},
  });

  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  factory McpTool.fromJson(Map<String, dynamic> json) => McpTool(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        inputSchema:
            (json['inputSchema'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
}

/// Result of calling an MCP tool.
class McpToolResult {
  const McpToolResult({required this.content, this.isError = false});

  final List<McpContent> content;
  final bool isError;

  factory McpToolResult.fromJson(Map<String, dynamic> json) {
    final contentList = (json['content'] as List<dynamic>?)
            ?.map((e) => McpContent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <McpContent>[];
    return McpToolResult(
      content: contentList,
      isError: json['isError'] as bool? ?? false,
    );
  }

  /// Concatenates all text content into a single string.
  String get text => content
      .where((c) => c.type == 'text')
      .map((c) => c.text)
      .join('\n');
}

/// A piece of content returned by an MCP tool call.
class McpContent {
  const McpContent({required this.type, this.text = '', this.mimeType = '', this.data});

  final String type;
  final String text;
  final String mimeType;
  final dynamic data;

  factory McpContent.fromJson(Map<String, dynamic> json) => McpContent(
        type: json['type'] as String? ?? 'text',
        text: json['text'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? '',
        data: json['data'],
      );
}

/// HTTP-based MCP client with streamable transport.
class McpHttpClient {
  McpHttpClient({
    required this.endpoint,
    this.headers = const <String, String>{},
    this.timeout = const Duration(seconds: 30),
    this.maxResponseSize = 10 * 1024 * 1024, // 10 MB
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String endpoint;
  final Map<String, String> headers;
  final Duration timeout;

  /// Maximum response body size in bytes. Responses exceeding this limit are
  /// rejected to prevent memory exhaustion.
  final int maxResponseSize;

  final http.Client _client;

  int _nextId = 1;
  McpCapabilities _capabilities = const McpCapabilities();
  bool _initialized = false;

  /// Whether the client has completed the initialize handshake.
  bool get isInitialized => _initialized;

  /// Server capabilities discovered during initialization.
  McpCapabilities get capabilities => _capabilities;

  /// Performs the MCP initialize handshake.
  Future<void> initialize() async {
    if (_initialized) return;

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
    await _sendNotification(JsonRpcNotification(method: 'notifications/initialized'));
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
  Future<McpToolResult> callTool(String name, Map<String, dynamic> arguments) async {
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

  /// Closes the HTTP client.
  void close() {
    _client.close();
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
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('MCP client not initialized. Call initialize() first.');
    }
  }

  Future<JsonRpcMessage> _send(JsonRpcRequest request) async {
    final body = jsonEncode(request.toJson());
    final uri = Uri.parse(endpoint);
    final response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            ...headers,
          },
          body: body,
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw JsonRpcError(
        id: request.id,
        code: response.statusCode,
        message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    // Enforce response size limit.
    if (response.contentLength != null &&
        response.contentLength! > maxResponseSize) {
      throw JsonRpcError(
        id: request.id,
        code: -32000,
        message:
            'Response too large: ${response.contentLength} bytes '
            '(limit: $maxResponseSize)',
      );
    }

    final responseBody = response.body;
    if (responseBody.length > maxResponseSize) {
      throw JsonRpcError(
        id: request.id,
        code: -32000,
        message:
            'Response too large: ${responseBody.length} bytes '
            '(limit: $maxResponseSize)',
      );
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    return JsonRpcMessage.fromJson(json);
  }

  Future<void> _sendNotification(JsonRpcNotification notification) async {
    final body = jsonEncode(notification.toJson());
    final uri = Uri.parse(endpoint);
    await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        ...headers,
      },
      body: body,
    ).timeout(timeout);
  }
}
