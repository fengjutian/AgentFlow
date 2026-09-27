/// Log sanitization — removes secrets from strings before logging.
///
/// Prevents accidental leakage of passwords, tokens, private keys, API keys
/// and other credentials into log output, crash reports, or model context.
///
/// Usage:
/// ```dart
/// log('Connecting with token: ${sanitizeSecret(actualToken)}');
/// // Output: "Connecting with token: [REDACTED]"
/// ```
library;

import 'package:flutter/foundation.dart';

/// Replaces a secret value with `[REDACTED]` for safe logging.
///
/// Returns `[REDACTED]` if [value] is non-null and non-empty, otherwise returns
/// the original value.
String sanitizeSecret(String? value) {
  if (value == null || value.isEmpty) return '';
  return '[REDACTED]';
}

/// Sanitizes a map of headers, redacting sensitive keys.
///
/// Returns a new map where values of sensitive headers (Authorization, Cookie,
/// X-Api-Key, etc.) are replaced with `[REDACTED]`.
Map<String, String> sanitizeHeaders(Map<String, String> headers) {
  const sensitiveKeys = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'proxy-authorization',
    'x-api-key',
    'x-auth-token',
    'api-key',
    'apikey',
  };
  return headers.map((key, value) {
    final lower = key.toLowerCase();
    if (sensitiveKeys.any((s) => lower.contains(s))) {
      return MapEntry(key, '[REDACTED]');
    }
    return MapEntry(key, value);
  });
}

/// Sanitizes a log message by redacting common secret patterns.
///
/// Patterns detected:
/// - Bearer tokens: `Bearer xxx` → `Bearer [REDACTED]`
/// - Password fields: `password=xxx` → `password=[REDACTED]`
/// - API keys: `api_key=xxx`, `apiKey: xxx`
/// - SSH private key blocks: `-----BEGIN ... PRIVATE KEY-----...`
String sanitizeLogMessage(String message) {
  var result = message;

  // Bearer tokens.
  result = result.replaceAllMapped(
    RegExp(r'Bearer\s+\S+', caseSensitive: false),
    (m) => 'Bearer [REDACTED]',
  );

  // Key-value secrets (password=xxx, api_key=xxx, token=xxx).
  result = result.replaceAllMapped(
    RegExp(
      r'(password|passwd|pwd|secret|token|api[_-]?key|apikey|auth)'
      r'(\s*[=:]\s*)'
      r'\S+',
      caseSensitive: false,
    ),
    (m) => '${m[1]}${m[2]}[REDACTED]',
  );

  // Private key blocks.
  result = result.replaceAllMapped(
    RegExp(r'-----BEGIN\s+\w+\s+PRIVATE\s+KEY-----(.+?)-----END', dotAll: true),
    (m) => '-----BEGIN PRIVATE KEY-----[REDACTED]-----END',
  );

  // SSH password patterns.
  result = result.replaceAllMapped(
    RegExp(r'ssh.*password[:\s]+.*', caseSensitive: false),
    (m) => 'ssh password: [REDACTED]',
  );

  return result;
}

/// Debug-log a message after sanitizing it.
///
/// Only outputs in debug mode. Safe to call with messages that may contain
/// secrets — they will be redacted before printing.
void debugLog(String message) {
  if (kDebugMode) {
    debugPrint(sanitizeLogMessage(message));
  }
}
