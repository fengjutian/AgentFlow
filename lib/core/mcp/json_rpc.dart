/// JSON-RPC 2.0 protocol models for MCP communication.
///
/// Implements the core JSON-RPC request, response, and notification structures
/// used by the Model Context Protocol. All messages follow the JSON-RPC 2.0 spec.
library;

/// A JSON-RPC 2.0 request expecting a response.
class JsonRpcRequest {
  const JsonRpcRequest({
    required this.id,
    required this.method,
    this.params,
  });

  final dynamic id;
  final String method;
  final Map<String, dynamic>? params;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        if (params != null) 'params': params,
      };
}

/// A JSON-RPC 2.0 notification (no id, no response expected).
class JsonRpcNotification {
  const JsonRpcNotification({required this.method, this.params});

  final String method;
  final Map<String, dynamic>? params;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'jsonrpc': '2.0',
        'method': method,
        if (params != null) 'params': params,
      };
}

/// A successful JSON-RPC 2.0 response.
class JsonRpcResponse {
  const JsonRpcResponse({required this.id, required this.result});

  final dynamic id;
  final dynamic result;

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) =>
      JsonRpcResponse(id: json['id'], result: json['result']);
}

/// A JSON-RPC 2.0 error response.
class JsonRpcError implements Exception {
  const JsonRpcError({required this.id, required this.code, required this.message, this.data});

  final dynamic id;
  final int code;
  final String message;
  final dynamic data;

  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>? ?? {};
    return JsonRpcError(
      id: json['id'],
      code: error['code'] as int? ?? -32000,
      message: error['message'] as String? ?? 'Unknown error',
      data: error['data'],
    );
  }

  @override
  String toString() => 'JSON-RPC error $code: $message';
}

/// A JSON-RPC 2.0 response that may be success or error.
class JsonRpcMessage {
  JsonRpcMessage._({this.response, this.error});

  final JsonRpcResponse? response;
  final JsonRpcError? error;

  bool get isError => error != null;
  bool get isSuccess => response != null;

  factory JsonRpcMessage.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return JsonRpcMessage._(error: JsonRpcError.fromJson(json));
    }
    return JsonRpcMessage._(response: JsonRpcResponse.fromJson(json));
  }
}

/// Standard JSON-RPC error codes.
class JsonRpcErrorCode {
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;
}
