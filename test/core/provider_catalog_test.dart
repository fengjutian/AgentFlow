import 'package:agentflow/core/model/provider_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog exposes the four first-party Chinese provider presets', () {
    final ids = providerCatalog.map((preset) => preset.id).toSet();
    expect(ids, containsAll(<String>['minimax', 'deepseek', 'qwen', 'kimi']));

    for (final id in <String>['minimax', 'deepseek', 'qwen', 'kimi']) {
      final preset = providerPresetById(id);
      expect(preset, isNotNull);
      expect(preset!.baseUrl, startsWith('https://'));
      expect(preset.defaultModel, isNotEmpty);
      expect(preset.requiresApiKey, isTrue);
    }
  });

  test('provider ids and endpoint/model pairs are unique', () {
    expect(
      providerCatalog.map((preset) => preset.id).toSet().length,
      providerCatalog.length,
    );
    expect(
      providerCatalog
          .where((preset) => preset.baseUrl.isNotEmpty)
          .map((preset) => '${preset.baseUrl}|${preset.defaultModel}')
          .toSet()
          .length,
      providerCatalog.where((preset) => preset.baseUrl.isNotEmpty).length,
    );
  });
}
