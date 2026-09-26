/// Small helpers for validating tool arguments consistently.
///
/// Every tool throws [ToolExecutionException] on bad input so the engine can
/// turn it into an error [ToolResult] the model can read and correct, instead of
/// crashing the loop with a cast error.
library;

import 'agent_tool.dart';

String requireString(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is String && value.isNotEmpty) return value;
  throw ToolExecutionException("Missing required string argument '$key'.");
}

String optionalString(
  Map<String, dynamic> args,
  String key, {
  String fallback = '',
}) {
  final value = args[key];
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

int optionalInt(
  Map<String, dynamic> args,
  String key, {
  int fallback = 0,
}) {
  final value = args[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool optionalBool(
  Map<String, dynamic> args,
  String key, {
  bool fallback = false,
}) {
  final value = args[key];
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Truncates long tool output so it never overwhelms the model context, keeping
/// head and tail and marking the elision.
String clampOutput(String text, {int maxChars = 12000}) {
  if (text.length <= maxChars) return text;
  final head = text.substring(0, maxChars ~/ 2);
  final tail = text.substring(text.length - maxChars ~/ 2);
  final omitted = text.length - head.length - tail.length;
  return '$head\n\n... [$omitted characters omitted] ...\n\n$tail';
}
