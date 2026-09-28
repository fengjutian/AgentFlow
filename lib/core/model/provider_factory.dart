/// Maps a [ModelConfig] to a concrete [ModelProvider].
///
/// Because [OpenAiCompatibleProvider] reads its endpoint/credentials from the
/// request, one instance serves every OpenAI-style backend (OpenAI, DeepSeek,
/// Qwen, local servers). Only genuinely different protocols need their own
/// class.
library;

import 'package:http/http.dart' as http;

import 'model_provider.dart';
import 'openai_provider.dart';

class ModelProviderFactory {
  ModelProviderFactory({http.Client? httpClient}) : _httpClient = httpClient;

  final http.Client? _httpClient;
  final Map<String, ModelProvider> _cache = <String, ModelProvider>{};

  /// Returns the [OpenAiCompatibleProvider] — it is stateless per request and
  /// cached for the lifetime of this factory.
  ModelProvider providerFor(ModelConfig config) {
    return _cache.putIfAbsent(
      'openai-compatible',
      () => OpenAiCompatibleProvider(client: _httpClient),
    );
  }

  void dispose() {
    for (final provider in _cache.values) {
      if (provider is OpenAiCompatibleProvider) provider.close();
    }
    _cache.clear();
  }
}
