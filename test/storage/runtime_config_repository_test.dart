import 'package:agentflow/data/models.dart';
import 'package:agentflow/storage/database.dart';
import 'package:agentflow/storage/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late RuntimeConfigRepository repository;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    repository = RuntimeConfigRepository(database);
  });

  tearDown(() => database.close());

  test('stores and updates non-secret runtime configuration', () async {
    final createdAt = DateTime.utc(2026, 1, 1);
    await repository.upsert(
      RuntimeConfig(
        id: 'ssh-dev',
        label: 'Development server',
        kind: 'ssh',
        options: const <String, dynamic>{
          'host': 'dev.example.test',
          'port': 22,
          'username': 'agent',
          'remoteRoot': '/srv/project',
        },
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    final stored = await repository.byId('ssh-dev');
    expect(stored, isNotNull);
    expect(stored!.kind, 'ssh');
    expect(stored.options['host'], 'dev.example.test');
    expect(stored.options.containsKey('password'), isFalse);

    await repository.upsert(
      stored.copyWith(
        label: 'Renamed server',
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
    expect((await repository.all()).single.label, 'Renamed server');
  });

  test('deletes runtime configuration', () async {
    final now = DateTime.utc(2026);
    await repository.upsert(
      RuntimeConfig(
        id: 'runtime',
        label: 'Runtime',
        kind: 'local',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repository.delete('runtime');
    expect(await repository.byId('runtime'), isNull);
  });
}
