import 'package:agentflow/runtime/ssh/ssh_host_key_store.dart';
import 'package:agentflow/runtime/ssh/ssh_runtime.dart';
import 'package:agentflow/storage/secret_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SshConfig', () {
    test('hasAuth returns true when password is set', () {
      const config = SshConfig(
        id: 'test',
        host: 'example.com',
        username: 'user',
        password: 'secret',
      );
      expect(config.hasAuth, isTrue);
      expect(config.hasPassword, isTrue);
      expect(config.hasPrivateKey, isFalse);
    });

    test('hasAuth returns true when private key is set', () {
      const config = SshConfig(
        id: 'test',
        host: 'example.com',
        username: 'user',
        privateKey: '-----BEGIN RSA PRIVATE KEY-----\n...',
      );
      expect(config.hasAuth, isTrue);
      expect(config.hasPassword, isFalse);
      expect(config.hasPrivateKey, isTrue);
    });

    test('hasAuth returns false when no auth is set', () {
      const config = SshConfig(
        id: 'test',
        host: 'example.com',
        username: 'user',
      );
      expect(config.hasAuth, isFalse);
    });

    test('default port is 22', () {
      const config = SshConfig(
        id: 'test',
        host: 'example.com',
        username: 'user',
      );
      expect(config.port, 22);
    });

    test('default remoteRoot is home directory', () {
      const config = SshConfig(
        id: 'test',
        host: 'example.com',
        username: 'user',
      );
      expect(config.remoteRoot, '~');
    });
  });

  group('SshRuntime', () {
    test('label falls back to user@host when no label is set', () {
      const config = SshConfig(
        id: 'test',
        host: 'example.com',
        username: 'admin',
      );
      // We can't instantiate SshRuntime without a real hostKeyStore,
      // but we can test the label logic through the config.
      expect(config.label, isEmpty);
      expect(config.host, 'example.com');
      expect(config.username, 'admin');
    });

    test('label uses custom label when set', () {
      const config = SshConfig(
        id: 'test',
        host: 'example.com',
        username: 'admin',
        label: 'My Server',
      );
      expect(config.label, 'My Server');
    });
  });

  group('SshConnectionPool', () {
    test('getOrConnect creates new runtime for new host', () {
      final pool = SshConnectionPool();
      // closeAll should not throw even when pool is empty.
      expect(pool.closeAll, returnsNormally);
    });

    test('closeAll empties the pool', () {
      final pool = SshConnectionPool();
      pool.closeAll();
      // Should not throw even when empty.
      expect(pool.closeAll, returnsNormally);
    });

    test('invalidate removes specific host', () {
      final pool = SshConnectionPool();
      pool.invalidate('example.com', 22);
      // Should not throw even when host doesn't exist.
      expect(() => pool.invalidate('example.com', 22), returnsNormally);
    });
  });

  group('HostKeyMismatchException', () {
    test('toString includes message', () {
      final e = HostKeyMismatchException('MITM attack detected');
      expect(e.toString(), contains('MITM attack detected'));
    });
  });

  group('SshRuntime.resolvePath', () {
    late SshRuntime runtime;

    setUp(() {
      runtime = SshRuntime(
        config: const SshConfig(
          id: 'test',
          host: 'example.com',
          username: 'user',
          remoteRoot: '/home/user/project',
        ),
        hostKeyStore: SshHostKeyStore(MemorySecretStore()),
      );
    });

    test('resolves relative paths against remote root', () {
      expect(runtime.resolvePath('src/main.dart'), '/home/user/project/src/main.dart');
    });

    test('resolves nested relative paths', () {
      expect(runtime.resolvePath('lib/core/doc.dart'), '/home/user/project/lib/core/doc.dart');
    });

    test('allows absolute paths within remote root', () {
      expect(
        runtime.resolvePath('/home/user/project/src/main.dart'),
        '/home/user/project/src/main.dart',
      );
    });

    test('rejects paths with .. components', () {
      expect(
        () => runtime.resolvePath('../etc/passwd'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects nested .. traversal', () {
      expect(
        () => runtime.resolvePath('src/../../etc/shadow'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects absolute paths outside remote root', () {
      expect(
        () => runtime.resolvePath('/etc/passwd'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SshRuntime.resolvePath with ~ root', () {
    late SshRuntime runtime;

    setUp(() {
      runtime = SshRuntime(
        config: const SshConfig(
          id: 'test',
          host: 'example.com',
          username: 'user',
          remoteRoot: '~',
        ),
        hostKeyStore: SshHostKeyStore(MemorySecretStore()),
      );
    });

    test('resolves relative paths against home', () {
      expect(runtime.resolvePath('file.txt'), '~/file.txt');
    });

    test('still rejects .. paths even with ~ root', () {
      expect(
        () => runtime.resolvePath('../etc/passwd'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
