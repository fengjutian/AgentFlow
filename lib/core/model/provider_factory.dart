/// Maps a [ModelConfig] to a concrete [ModelProvider].
///
/// Because [OpenAiCompatibleProvider] reads its endpoint/credentials from the
/// request, one instance serves every OpenAI-style backend (OpenAI, DeepSeek,
/// Qwen, local servers). Only genuinely different protocols need their own
/// class; the `mock` provider enables offline demos and tests.
library;

import 'package:http/http.dart' as http;

import 'mock_provider.dart';
import 'model_provider.dart';
import 'openai_provider.dart';

class ModelProviderFactory {
  ModelProviderFactory({http.Client? httpClient}) : _httpClient = httpClient;

  final http.Client? _httpClient;
  final Map<String, ModelProvider> _cache = <String, ModelProvider>{};

  /// Returns the provider responsible for [config].
  ///
  /// The OpenAI-compatible provider is stateless per request and cached. The
  /// mock provider is stateful (it replays a script), so a fresh demo instance
  /// is created for every run.
  ModelProvider providerFor(ModelConfig config) {
    if (config.provider == 'mock') return MockModelProvider.demo();
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
