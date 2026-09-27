import 'dart:convert';

import 'package:agentflow/runtime/ssh/ssh_host_key_store.dart';
import 'package:agentflow/storage/secret_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecretStore secrets;
  late SshHostKeyStore hostKeyStore;

  setUp(() {
    secrets = MemorySecretStore();
    hostKeyStore = SshHostKeyStore(secrets);
  });

  group('SshHostKeyStore', () {
    test('get returns null for unknown host', () async {
      final key = await hostKeyStore.get('unknown.example.com', 22);
      expect(key, isNull);
    });

    test('store persists and get retrieves a host key', () async {
      const key = SshHostKey(
        host: 'example.com',
        port: 22,
        fingerprint: 'SHA256:abc123',
        algorithm: 'ssh-ed25519',
      );

      await hostKeyStore.store(key);

      final retrieved = await hostKeyStore.get('example.com', 22);
      expect(retrieved, isNotNull);
      expect(retrieved!.fingerprint, 'SHA256:abc123');
      expect(retrieved.algorithm, 'ssh-ed25519');
      expect(retrieved.host, 'example.com');
      expect(retrieved.port, 22);
    });

    test('store uses correct secret key format', () async {
      const key = SshHostKey(
        host: 'myserver.local',
        port: 2222,
        fingerprint: 'SHA256:xyz',
        algorithm: 'rsa',
      );

      await hostKeyStore.store(key);

      // Verify the secret is stored with the right key.
      final raw = await secrets.read('ssh-hostkey/myserver.local:2222');
      expect(raw, isNotNull);

      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['fingerprint'], 'SHA256:xyz');
      expect(json['algorithm'], 'rsa');
    });

    test('remove deletes the stored host key', () async {
      const key = SshHostKey(
        host: 'example.com',
        port: 22,
        fingerprint: 'SHA256:abc',
        algorithm: 'ed25519',
      );

      await hostKeyStore.store(key);
      expect(await hostKeyStore.get('example.com', 22), isNotNull);

      await hostKeyStore.remove('example.com', 22);
      expect(await hostKeyStore.get('example.com', 22), isNull);
    });

    test('remove does not throw for non-existent host', () async {
      expect(
        () => hostKeyStore.remove('nonexistent.com', 22),
        returnsNormally,
      );
    });
  });

  group('SshHostKeyStore.verify', () {
    test('returns unknown for first-time connection', () async {
      final result = await hostKeyStore.verify(
        'newhost.example.com',
        22,
        'SHA256:newkey',
        'ssh-ed25519',
      );

      expect(result.isUnknown, isTrue);
      expect(result.isMatch, isFalse);
      expect(result.isMismatch, isFalse);
      expect(result.fingerprint, 'SHA256:newkey');
    });

    test('returns match when fingerprints match', () async {
      const key = SshHostKey(
        host: 'trusted.example.com',
        port: 22,
        fingerprint: 'SHA256:trusted',
        algorithm: 'ssh-ed25519',
      );
      await hostKeyStore.store(key);

      final result = await hostKeyStore.verify(
        'trusted.example.com',
        22,
        'SHA256:trusted',
        'ssh-ed25519',
      );

      expect(result.isMatch, isTrue);
      expect(result.isUnknown, isFalse);
    });

    test('returns mismatch when fingerprints differ (MITM alert)', () async {
      const key = SshHostKey(
        host: 'compromised.example.com',
        port: 22,
        fingerprint: 'SHA256:original',
        algorithm: 'ssh-ed25519',
      );
      await hostKeyStore.store(key);

      final result = await hostKeyStore.verify(
        'compromised.example.com',
        22,
        'SHA256:suspicious',
        'ssh-ed25519',
      );

      expect(result.isMismatch, isTrue);
      expect(result.isMatch, isFalse);
      expect(result.storedKey, isNotNull);
      expect(result.storedKey!.fingerprint, 'SHA256:original');
      expect(result.presentedKey, isNotNull);
      expect(result.presentedKey!.fingerprint, 'SHA256:suspicious');
    });

    test('verify handles corrupted secret gracefully', () async {
      // Write invalid JSON to simulate corruption.
      await secrets.write('ssh-hostkey/corrupt.example.com:22', 'not-json');

      final result = await hostKeyStore.verify(
        'corrupt.example.com',
        22,
        'SHA256:newkey',
        'ssh-ed25519',
      );

      // Should treat it as unknown (first connection).
      expect(result.isUnknown, isTrue);
    });

    test('verify handles empty secret gracefully', () async {
      await secrets.write('ssh-hostkey/empty.example.com:22', '');

      final result = await hostKeyStore.verify(
        'empty.example.com',
        22,
        'SHA256:newkey',
        'ssh-ed25519',
      );

      expect(result.isUnknown, isTrue);
    });

    test('different ports are independent', () async {
      const key22 = SshHostKey(
        host: 'multi.example.com',
        port: 22,
        fingerprint: 'SHA256:port22',
        algorithm: 'ed25519',
      );
      await hostKeyStore.store(key22);

      // Port 2222 should be unknown.
      final result = await hostKeyStore.verify(
        'multi.example.com',
        2222,
        'SHA256:anything',
        'ed25519',
      );
      expect(result.isUnknown, isTrue);

      // Port 22 should match.
      final result22 = await hostKeyStore.verify(
        'multi.example.com',
        22,
        'SHA256:port22',
        'ed25519',
      );
      expect(result22.isMatch, isTrue);
    });
  });

  group('SshHostKey', () {
    test('key is host:port', () {
      const key = SshHostKey(
        host: 'example.com',
        port: 2222,
        fingerprint: 'fp',
        algorithm: 'algo',
      );
      expect(key.key, 'example.com:2222');
    });

    test('toJson round-trip preserves data', () {
      const key = SshHostKey(
        host: 'h',
        port: 22,
        fingerprint: 'SHA256:abc',
        algorithm: 'rsa',
      );
      final json = key.toJson();
      final restored = SshHostKey.fromJson('h', 22, json);

      expect(restored.fingerprint, 'SHA256:abc');
      expect(restored.algorithm, 'rsa');
      expect(restored.host, 'h');
      expect(restored.port, 22);
    });
  });
}
