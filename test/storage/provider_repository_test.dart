import 'package:agentflow/core/model/model_provider.dart';
import 'package:agentflow/storage/database.dart';
import 'package:agentflow/storage/repositories.dart';
import 'package:agentflow/storage/secret_store.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MemorySecretStore secrets;
  late ProviderRepository repository;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    secrets = MemorySecretStore();
    repository = ProviderRepository(database, secrets);
  });

  tearDown(() => database.close());

  test('new API keys are stored outside SQLite', () async {
    await repository.upsert(const ModelConfig(
      id: 'deepseek',
      label: 'DeepSeek',
      provider: 'deepseek',
      model: 'deepseek-chat',
      baseUrl: 'https://api.deepseek.com/v1',
      apiKey: 'secret-value',
    ));

    final row = await database.select(database.providerConfigs).getSingle();
    expect(row.apiKey, isEmpty);
    expect((await repository.all()).single.apiKey, 'secret-value');
  });

  test('legacy plaintext key is migrated and erased', () async {
    await database.into(database.providerConfigs).insert(
          ProviderConfigsCompanion.insert(
            id: 'legacy',
            label: 'Legacy',
            provider: 'openai',
            model: 'gpt-test',
            baseUrl: 'https://example.test/v1',
            apiKey: const Value('old-plaintext-key'),
          ),
        );

    expect((await repository.all()).single.apiKey, 'old-plaintext-key');
    final migrated = await database.select(database.providerConfigs).getSingle();
    expect(migrated.apiKey, isEmpty);
    expect(await secrets.read('model-provider/legacy/api-key'),
        'old-plaintext-key');
  });
}
