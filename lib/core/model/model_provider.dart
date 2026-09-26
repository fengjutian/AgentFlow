/// Model layer abstraction.
///
/// The Agent Core talks to [ModelProvider] only; concrete vendors (OpenAI,
/// DeepSeek, Qwen, Gemini, local llama.cpp servers, ...) live behind it. This
/// keeps the loop testable — a [MockModelProvider] can drive a full run with no
/// network — and lets users switch providers from Settings without touching the
/// engine.
library;

import '../message.dart';

/// Runtime configuration for a provider endpoint.
class ModelConfig {
  const ModelConfig({
    required this.id,
    required this.label,
    required this.provider,
    required this.model,
    required this.baseUrl,
    this.apiKey = '',
    this.temperature = 0.2,
    this.maxTokens = 4096,
    this.contextWindow = 128000,
    this.isDefault = false,
  });

  final String id;
  final String label;

  /// Vendor family: `openai`, `deepseek`, `qwen`, `gemini`, `openai-compatible`,
  /// `local`, `mock`.
  final String provider;
  final String model;

  /// e.g. `https://api.deepseek.com/v1`.
  final String baseUrl;
  final String apiKey;
  final double temperature;
  final int maxTokens;
  final int contextWindow;
  final bool isDefault;

  bool get requiresApiKey => provider != 'mock' && provider != 'local';

  ModelConfig copyWith({
    String? label,
    String? provider,
    String? model,
    String? baseUrl,
    String? apiKey,
    double? temperature,
    int? maxTokens,
    int? contextWindow,
    bool? isDefault,
  }) =>
      ModelConfig(
        id: id,
        label: label ?? this.label,
        provider: provider ?? this.provider,
        model: model ?? this.model,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        contextWindow: contextWindow ?? this.contextWindow,
        isDefault: isDefault ?? this.isDefault,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'provider': provider,
        'model': model,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'contextWindow': contextWindow,
        'isDefault': isDefault,
      };

  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
        id: json['id'] as String,
        label: (json['label'] ?? '') as String,
        provider: (json['provider'] ?? 'openai-compatible') as String,
        model: (json['model'] ?? '') as String,
        baseUrl: (json['baseUrl'] ?? '') as String,
        apiKey: (json['apiKey'] ?? '') as String,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.2,
        maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 4096,
        contextWindow: (json['contextWindow'] as num?)?.toInt() ?? 128000,
        isDefault: (json['isDefault'] ?? false) as bool,
      );
}

/// A tool exposed to the model, in JSON-schema form.
class ToolSpec {
  const ToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;

  /// JSON schema for the tool arguments.
  final Map<String, dynamic> parameters;

  Map<String, dynamic> toOpenAiJson() => <String, dynamic>{
        'type': 'function',
        'function': <String, dynamic>{
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}

/// Everything the engine hands to the model on one loop iteration.
class ModelRequest {
  const ModelRequest({
    required this.messages,
    this.tools = const <ToolSpec>[],
    required this.config,
  });

  final List<ChatMessage> messages;
  final List<ToolSpec> tools;
  final ModelConfig config;
}

/// Why the model stopped generating.
enum FinishReason { stop, toolCalls, length, error }

/// The model's reply: natural-language [content] and/or [toolCalls].
class ModelResponse {
  const ModelResponse({
    required this.content,
    required this.toolCalls,
    required this.finishReason,
    this.rawUsage,
  });

  final String content;
  final List<ToolCall> toolCalls;
  final FinishReason finishReason;

  /// Prompt/completion token counts when the provider reports them.
  final Map<String, int>? rawUsage;

  bool get hasToolCalls => toolCalls.isNotEmpty;
  bool get isFinal => !hasToolCalls && finishReason != FinishReason.error;

  factory ModelResponse.text(String content) => ModelResponse(
        content: content,
        toolCalls: const <ToolCall>[],
        finishReason: FinishReason.stop,
      );
}

/// Thrown when a provider call fails (network, auth, malformed response).
class ModelException implements Exception {
  const ModelException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ModelException(${statusCode == null ? '' : '$statusCode '}$message)';
}

/// A single LLM backend.
abstract class ModelProvider {
  /// Stable identifier used for logging and Settings.
  String get id;

  /// Human-readable name.
  String get displayName;

  /// Runs one completion. Implementations must translate [ModelRequest.tools]
  /// into their native tool-calling schema and map the reply back to
  /// [ModelResponse].
  Future<ModelResponse> generate(ModelRequest request);
}
