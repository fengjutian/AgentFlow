/// LSP (Language Server Protocol) client over a [ProcessSession] stdio transport.
///
/// Implements the LSP client lifecycle, document synchronization, and code
/// intelligence requests (completion, definition, hover, diagnostics).
///
/// Unlike MCP stdio (newline-delimited JSON), LSP uses HTTP-style framing:
///   Content-Length: <N>\r\n\r\n<JSON body of N UTF-8 bytes>
library;

import 'dart:async';
import 'dart:convert';

import '../../runtime/runtime.dart';
import '../mcp/json_rpc.dart';

// ---------------------------------------------------------------------------
// LSP data types
// ---------------------------------------------------------------------------

/// A position in a text document (0-based line and character).
class LspPosition {
  const LspPosition(this.line, this.character);
  final int line;
  final int character;

  factory LspPosition.fromJson(Map<String, dynamic> json) =>
      LspPosition(
        json['line'] as int? ?? 0,
        json['character'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'line': line, 'character': character};
}

/// A range in a text document.
class LspRange {
  const LspRange(this.start, this.end);
  final LspPosition start;
  final LspPosition end;

  factory LspRange.fromJson(Map<String, dynamic> json) => LspRange(
        LspPosition.fromJson(json['start'] as Map<String, dynamic>),
        LspPosition.fromJson(json['end'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'start': start.toJson(), 'end': end.toJson()};
}

/// A location in a file (URI + range).
class LspLocation {
  const LspLocation(this.uri, this.range);
  final String uri;
  final LspRange range;

  factory LspLocation.fromJson(Map<String, dynamic> json) => LspLocation(
        json['uri'] as String? ?? '',
        LspRange.fromJson(json['range'] as Map<String, dynamic>),
      );
}

/// LSP diagnostic severity.
enum LspDiagnosticSeverity { error, warning, information, hint }

/// A diagnostic (error, warning, etc.) reported by the language server.
class LspDiagnostic {
  const LspDiagnostic({
    required this.range,
    required this.message,
    this.severity = LspDiagnosticSeverity.error,
    this.source,
    this.code,
  });

  final LspRange range;
  final String message;
  final LspDiagnosticSeverity severity;
  final String? source;
  final dynamic code;

  factory LspDiagnostic.fromJson(Map<String, dynamic> json) => LspDiagnostic(
        range: LspRange.fromJson(json['range'] as Map<String, dynamic>),
        message: json['message'] as String? ?? '',
        severity: LspDiagnosticSeverity.values[
            ((json['severity'] as int?) ?? 1) - 1],
        source: json['source'] as String?,
        code: json['code'],
      );
}

/// LSP completion item kind (subset of the LSP spec).
enum LspCompletionKind {
  text,
  method,
  function_,
  constructor_,
  field,
  variable,
  class_,
  interface_,
  module,
  property,
  unit,
  value,
  enum_,
  keyword,
  snippet,
  color,
  file,
  reference,
  folder,
  enumMember,
  constant,
  struct,
  event,
  operator_,
  typeParameter,
}

/// Icon data for a completion kind (for UI rendering).
LspCompletionKind completionKindFromInt(int kind) {
  if (kind >= 1 && kind <= LspCompletionKind.values.length) {
    return LspCompletionKind.values[kind - 1];
  }
  return LspCompletionKind.text;
}

/// A single completion item.
class LspCompletionItem {
  const LspCompletionItem({
    required this.label,
    this.kind = LspCompletionKind.text,
    this.detail,
    this.documentation,
    this.insertText,
    this.sortText,
    this.filterText,
  });

  final String label;
  final LspCompletionKind kind;
  final String? detail;
  final String? documentation;
  final String? insertText;
  final String? sortText;
  final String? filterText;

  /// The text to insert: insertText if present, else label.
  String get effectiveInsertText => insertText ?? label;

  factory LspCompletionItem.fromJson(Map<String, dynamic> json) {
    String? doc;
    final rawDoc = json['documentation'];
    if (rawDoc is String) {
      doc = rawDoc;
    } else if (rawDoc is Map<String, dynamic>) {
      doc = rawDoc['value'] as String?;
    }
    return LspCompletionItem(
      label: json['label'] as String? ?? '',
      kind: completionKindFromInt(json['kind'] as int? ?? 1),
      detail: json['detail'] as String?,
      documentation: doc,
      insertText: json['insertText'] as String?,
      sortText: json['sortText'] as String?,
      filterText: json['filterText'] as String?,
    );
  }
}

/// Result of a completion request.
class LspCompletionResult {
  const LspCompletionResult(this.items, {this.isIncomplete = false});
  final List<LspCompletionItem> items;
  final bool isIncomplete;

  factory LspCompletionResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) =>
                LspCompletionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <LspCompletionItem>[];
    return LspCompletionResult(
      items,
      isIncomplete: json['isIncomplete'] as bool? ?? false,
    );
  }
}

/// Result of a hover request.
class LspHoverResult {
  const LspHoverResult(this.contents, {this.range});
  final String contents;
  final LspRange? range;

  factory LspHoverResult.fromJson(Map<String, dynamic> json) {
    String contents;
    final raw = json['contents'];
    if (raw is String) {
      contents = raw;
    } else if (raw is Map<String, dynamic>) {
      contents = raw['value'] as String? ?? '';
    } else if (raw is List) {
      contents = raw
          .map((e) =>
              e is String ? e : (e as Map<String, dynamic>)['value'] ?? '')
          .join('\n\n');
    } else {
      contents = '';
    }
    final rangeJson = json['range'] as Map<String, dynamic>?;
    return LspHoverResult(
      contents,
      range: rangeJson != null ? LspRange.fromJson(rangeJson) : null,
    );
  }
}

// ---------------------------------------------------------------------------
// LSP notification event (for manager to dispatch)
// ---------------------------------------------------------------------------

/// A notification received from the language server.
class LspNotification {
  const LspNotification(this.method, this.params);
  final String method;
  final Map<String, dynamic> params;
}

/// Diagnostics published by the language server for a specific document.
class LspDiagnosticsEvent {
  const LspDiagnosticsEvent(this.uri, this.diagnostics);
  final String uri;
  final List<LspDiagnostic> diagnostics;
}

// ---------------------------------------------------------------------------
// LSP server capabilities (from initialize response)
// ---------------------------------------------------------------------------

class LspServerCapabilities {
  const LspServerCapabilities({
    this.completionProvider = false,
    this.hoverProvider = false,
    this.definitionProvider = false,
    this.completionTriggerCharacters = const <String>[],
  });

  final bool completionProvider;
  final bool hoverProvider;
  final bool definitionProvider;
  final List<String> completionTriggerCharacters;

  factory LspServerCapabilities.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LspServerCapabilities();
    final completion = json['completionProvider'];
    final triggerChars = completion is Map<String, dynamic>
        ? (completion['triggerCharacters'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            <String>[]
        : <String>[];
    return LspServerCapabilities(
      completionProvider: completion != null,
      hoverProvider: json['hoverProvider'] != null &&
          json['hoverProvider'] != false,
      definitionProvider: json['definitionProvider'] != null &&
          json['definitionProvider'] != false,
      completionTriggerCharacters: triggerChars,
    );
  }
}

// ---------------------------------------------------------------------------
// LSP Client
// ---------------------------------------------------------------------------

/// LSP client communicating with a language server over stdio.
///
/// Usage:
/// ```dart
/// final client = LspClient(session: processSession);
/// await client.initialize(rootUri: 'file:///project');
/// await client.didOpen('file:///project/main.dart', 'dart', content);
/// final completions = await client.completion('file:///...', 10, 5);
/// await client.shutdown();
/// ```
class LspClient {
  LspClient({
    required this.session,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseSize = 10 * 1024 * 1024,
  });

  final ProcessSession session;
  final Duration timeout;
  final int maxResponseSize;

  int _nextId = 1;
  bool _initialized = false;
  bool _shutdown = false;
  LspServerCapabilities _capabilities = const LspServerCapabilities();

  final Map<dynamic, Completer<JsonRpcMessage>> _pending = {};
  StreamSubscription<String>? _stdoutSub;
  String _buffer = '';

  /// Broadcast stream of server notifications (diagnostics, etc.).
  final StreamController<LspNotification> _notificationController =
      StreamController<LspNotification>.broadcast();

  /// Whether the client has completed the initialize handshake.
  bool get isInitialized => _initialized;

  /// Whether the client has been shut down.
  bool get isShutdown => _shutdown;

  /// Server capabilities discovered during initialization.
  LspServerCapabilities get capabilities => _capabilities;

  /// Stream of server-to-client notifications.
  Stream<LspNotification> get notifications => _notificationController.stream;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Performs the LSP initialize handshake.
  Future<void> initialize({String? rootUri, String? workspaceRoot}) async {
    if (_initialized) return;

    _startListening();

    final response = await _send(JsonRpcRequest(
      id: _nextId++,
      method: 'initialize',
      params: <String, dynamic>{
        'processId': null,
        'rootUri': rootUri,
        'rootPath': workspaceRoot,
        'capabilities': <String, dynamic>{
          'textDocument': <String, dynamic>{
            'completion': <String, dynamic>{
              'completionItem': <String, dynamic>{
                'snippetSupport': false,
                'documentationFormat': <String>['markdown', 'plaintext'],
              },
            },
            'hover': <String, dynamic>{
              'contentFormat': <String>['markdown', 'plaintext'],
            },
            'synchronization': <String, dynamic>{
              'didSave': true,
              'willSave': false,
            },
            'publishDiagnostics': <String, dynamic>{
              'relatedInformation': false,
            },
          },
        },
      },
    ));

    if (response.isError) {
      throw response.error!;
    }

    final result = response.response!.result as Map<String, dynamic>?;
    _capabilities = LspServerCapabilities.fromJson(
        result?['capabilities'] as Map<String, dynamic>?);

    // Send initialized notification.
    await _sendNotification(
        const JsonRpcNotification(method: 'initialized'));
    _initialized = true;
  }

  /// Sends the shutdown request.
  Future<void> shutdown() async {
    if (!_initialized || _shutdown) return;
    _shutdown = true;

    try {
      await _send(JsonRpcRequest(id: _nextId++, method: 'shutdown'));
      await _sendNotification(
          const JsonRpcNotification(method: 'exit'));
    } catch (_) {
      // Best-effort — server may already be gone.
    }
  }

  /// Closes the client and terminates the process.
  Future<void> close() async {
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('LSP client closed.'));
      }
    }
    _pending.clear();
    await _notificationController.close();
    await session.terminate();
    _initialized = false;
  }

  // -------------------------------------------------------------------------
  // Document synchronization
  // -------------------------------------------------------------------------

  /// Notifies the server that a document was opened.
  Future<void> didOpen(
    String uri,
    String languageId,
    String text, {
    int version = 1,
  }) async {
    _ensureInitialized();
    await _sendNotification(JsonRpcNotification(
      method: 'textDocument/didOpen',
      params: <String, dynamic>{
        'textDocument': <String, dynamic>{
          'uri': uri,
          'languageId': languageId,
          'version': version,
          'text': text,
        },
      },
    ));
  }

  /// Notifies the server that a document was changed (full sync).
  Future<void> didChange(
    String uri,
    String text, {
    int version = 2,
  }) async {
    _ensureInitialized();
    await _sendNotification(JsonRpcNotification(
      method: 'textDocument/didChange',
      params: <String, dynamic>{
        'textDocument': <String, dynamic>{
          'uri': uri,
          'version': version,
        },
        'contentChanges': <Map<String, dynamic>>[
          <String, dynamic>{'text': text},
        ],
      },
    ));
  }

  /// Notifies the server that a document was saved.
  Future<void> didSave(String uri) async {
    _ensureInitialized();
    await _sendNotification(JsonRpcNotification(
      method: 'textDocument/didSave',
      params: <String, dynamic>{
        'textDocument': <String, dynamic>{'uri': uri},
      },
    ));
  }

  /// Notifies the server that a document was closed.
  Future<void> didClose(String uri) async {
    _ensureInitialized();
    await _sendNotification(JsonRpcNotification(
      method: 'textDocument/didClose',
      params: <String, dynamic>{
        'textDocument': <String, dynamic>{'uri': uri},
      },
    ));
  }

  // -------------------------------------------------------------------------
  // Code intelligence requests
  // -------------------------------------------------------------------------

  /// Requests completions at the given position (0-based line/character).
  Future<LspCompletionResult> completion(
    String uri,
    int line,
    int character,
  ) async {
    _ensureInitialized();
    final response = await _send(JsonRpcRequest(
      id: _nextId++,
      method: 'textDocument/completion',
      params: <String, dynamic>{
        'textDocument': <String, dynamic>{'uri': uri},
        'position': <String, dynamic>{
          'line': line,
          'character': character,
        },
      },
    ));

    if (response.isError) {
      throw response.error!;
    }

    final result = response.response!.result;
    if (result == null) return const LspCompletionResult(<LspCompletionItem>[]);
    if (result is List) {
      return LspCompletionResult(
        result
            .map((e) =>
                LspCompletionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    return LspCompletionResult.fromJson(result as Map<String, dynamic>);
  }

  /// Requests go-to-definition at the given position.
  Future<List<LspLocation>> definition(
    String uri,
    int line,
    int character,
  ) async {
    _ensureInitialized();
    final response = await _send(JsonRpcRequest(
      id: _nextId++,
      method: 'textDocument/definition',
      params: <String, dynamic>{
        'textDocument': <String, dynamic>{'uri': uri},
        'position': <String, dynamic>{
          'line': line,
          'character': character,
        },
      },
    ));

    if (response.isError) {
      throw response.error!;
    }

    final result = response.response!.result;
    if (result == null) return const <LspLocation>[];
    if (result is List) {
      return result
          .map((e) => LspLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <LspLocation>[
      LspLocation.fromJson(result as Map<String, dynamic>),
    ];
  }

  /// Requests hover information at the given position.
  Future<LspHoverResult?> hover(
    String uri,
    int line,
    int character,
  ) async {
    _ensureInitialized();
    final response = await _send(JsonRpcRequest(
      id: _nextId++,
      method: 'textDocument/hover',
      params: <String, dynamic>{
        'textDocument': <String, dynamic>{'uri': uri},
        'position': <String, dynamic>{
          'line': line,
          'character': character,
        },
      },
    ));

    if (response.isError) {
      throw response.error!;
    }

    final result = response.response!.result;
    if (result == null) return null;
    return LspHoverResult.fromJson(result as Map<String, dynamic>);
  }

  /// Sends a cancel request notification for an in-flight request.
  Future<void> cancelRequest(int requestId) async {
    await _sendNotification(JsonRpcNotification(
      method: r'$/cancelRequest',
      params: <String, dynamic>{'id': requestId},
    ));
    final completer = _pending.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        StateError('Request $requestId cancelled by client.'),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Internal: message framing (Content-Length headers)
  // -------------------------------------------------------------------------

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'LSP client not initialized. Call initialize() first.');
    }
  }

  void _startListening() {
    _stdoutSub = session.stdout.listen(
      (String chunk) {
        _buffer += chunk;
        _processBuffer();
      },
      onError: (Object error) {
        for (final completer in _pending.values) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        }
        _pending.clear();
      },
      onDone: () {
        for (final completer in _pending.values) {
          if (!completer.isCompleted) {
            completer.completeError(
                StateError('Language server process exited.'));
          }
        }
        _pending.clear();
      },
    );
  }

  /// Processes the receive buffer, extracting complete LSP messages.
  ///
  /// LSP messages use HTTP-style framing:
  ///   Content-Length: <N>\r\n
  ///   \r\n
  ///   <JSON body of N UTF-8 bytes>
  void _processBuffer() {
    while (true) {
      // Find end of headers.
      final headerEnd = _buffer.indexOf('\r\n\r\n');
      if (headerEnd < 0) return;

      // Parse Content-Length from headers.
      final headers = _buffer.substring(0, headerEnd);
      int? contentLength;
      for (final header in headers.split('\r\n')) {
        if (header.toLowerCase().startsWith('content-length:')) {
          contentLength =
              int.tryParse(header.substring(15).trim());
        }
      }
      if (contentLength == null) {
        // Malformed — skip past this header block.
        _buffer = _buffer.substring(headerEnd + 4);
        continue;
      }

      final bodyStart = headerEnd + 4;
      final bodyBytes = utf8.encode(_buffer.substring(bodyStart));

      if (bodyBytes.length < contentLength) {
        return; // Body not yet complete — wait for more data.
      }

      // Extract the body.
      final bodyUtf8 = bodyBytes.sublist(0, contentLength);
      final body = utf8.decode(bodyUtf8);

      // Advance buffer past this message.
      // Compute the character offset for the consumed bytes.
      final consumedChars = bodyStart +
          utf8.decode(bodyBytes.sublist(0, contentLength)).length;
      _buffer = _buffer.substring(consumedChars);

      // Enforce size limit.
      if (contentLength > maxResponseSize) continue;

      _handleMessage(body);
    }
  }

  void _handleMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Check if this is a notification (no id) or a response (has id).
      if (!json.containsKey('id') || json['id'] == null) {
        // Server notification.
        final method = json['method'] as String? ?? '';
        final params = json['params'] as Map<String, dynamic>? ?? {};
        _notificationController.add(LspNotification(method, params));
        return;
      }

      final message = JsonRpcMessage.fromJson(json);
      final id = message.response?.id ?? message.error?.id;
      final completer = _pending.remove(id);
      if (completer != null && !completer.isCompleted) {
        completer.complete(message);
      }
    } catch (_) {
      // Skip malformed messages.
    }
  }

  /// Sends a JSON-RPC request and waits for a response.
  Future<JsonRpcMessage> _send(JsonRpcRequest request) async {
    final completer = Completer<JsonRpcMessage>();
    _pending[request.id] = completer;

    await _writeMessage(request.toJson());

    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(request.id);
      throw TimeoutException(
          'LSP request ${request.id} (${request.method}) timed out.',
          timeout);
    });
  }

  /// Sends a JSON-RPC notification (no response expected).
  Future<void> _sendNotification(JsonRpcNotification notification) async {
    await _writeMessage(notification.toJson());
  }

  /// Writes a JSON message with LSP Content-Length framing.
  Future<void> _writeMessage(Map<String, dynamic> json) async {
    final body = jsonEncode(json);
    final bodyBytes = utf8.encode(body);
    final header = 'Content-Length: ${bodyBytes.length}\r\n\r\n';
    await session.writeStdin(header + body);
  }
}
