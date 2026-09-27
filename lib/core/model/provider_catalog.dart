/// Declarative catalog for model-provider presets shown in Settings.
///
/// Adding a provider should only require one entry here; the editor and the
/// OpenAI-compatible transport do not contain vendor-specific branches.
class ProviderPreset {
  const ProviderPreset({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.defaultModel,
    this.maxTokens = 8192,
    this.contextWindow = 128000,
    this.requiresApiKey = true,
  });

  final String id;
  final String displayName;
  final String baseUrl;
  final String defaultModel;
  final int maxTokens;
  final int contextWindow;
  final bool requiresApiKey;
}

const List<ProviderPreset> providerCatalog = <ProviderPreset>[
  ProviderPreset(
    id: 'minimax',
    displayName: 'MiniMax',
    baseUrl: 'https://api.minimaxi.com/v1',
    defaultModel: 'MiniMax-M2.5',
    contextWindow: 204800,
  ),
  ProviderPreset(
    id: 'deepseek',
    displayName: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-flash',
    contextWindow: 1000000,
  ),
  ProviderPreset(
    id: 'qwen',
    displayName: 'Qwen（通义千问）',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    defaultModel: 'qwen-plus',
    contextWindow: 131072,
  ),
  ProviderPreset(
    id: 'kimi',
    displayName: 'Kimi',
    baseUrl: 'https://api.moonshot.cn/v1',
    defaultModel: 'kimi-k2.5',
    contextWindow: 262144,
  ),
  ProviderPreset(
    id: 'openai',
    displayName: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
  ),
  ProviderPreset(
    id: 'openai-compatible',
    displayName: 'OpenAI Compatible',
    baseUrl: '',
    defaultModel: '',
  ),
  ProviderPreset(
    id: 'local',
    displayName: 'Local',
    baseUrl: 'http://localhost:1234/v1',
    defaultModel: '',
    requiresApiKey: false,
  ),
  ProviderPreset(
    id: 'mock',
    displayName: 'Demo (offline)',
    baseUrl: '',
    defaultModel: 'mock-agent',
    requiresApiKey: false,
  ),
];

ProviderPreset? providerPresetById(String id) {
  for (final preset in providerCatalog) {
    if (preset.id == id) return preset;
  }
  return null;
}
