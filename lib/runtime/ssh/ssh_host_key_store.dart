/// SSH host key persistence and verification.
///
/// Stores host key fingerprints keyed by `host:port` in SecretStore. On first
/// connection the fingerprint is presented to the user for confirmation. On
/// subsequent connections the stored fingerprint is compared; a mismatch
/// indicates a potential MITM attack and the connection is refused.
library;

import 'dart:convert';

import '../../storage/secret_store.dart';

/// A verified SSH host key fingerprint.
class SshHostKey {
  const SshHostKey({
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.algorithm,
  });

  final String host;
  final int port;
  final String fingerprint;
  final String algorithm;

  String get key => '$host:$port';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fingerprint': fingerprint,
        'algorithm': algorithm,
      };

  factory SshHostKey.fromJson(String host, int port, Map<String, dynamic> json) =>
      SshHostKey(
        host: host,
        port: port,
        fingerprint: json['fingerprint'] as String? ?? '',
        algorithm: json['algorithm'] as String? ?? '',
      );
}

/// Persists and verifies SSH host key fingerprints.
class SshHostKeyStore {
  SshHostKeyStore(this._secrets);

  final SecretStore _secrets;

  String _secretKey(String host, int port) => 'ssh-hostkey/$host:$port';

  /// Returns the stored host key for the given host:port, or null if not seen.
  Future<SshHostKey?> get(String host, int port) async {
    final raw = await _secrets.read(_secretKey(host, port));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SshHostKey.fromJson(host, port, json);
    } catch (_) {
      return null;
    }
  }

  /// Stores a host key fingerprint after user confirmation.
  Future<void> store(SshHostKey key) async {
    await _secrets.write(_secretKey(key.host, key.port), jsonEncode(key.toJson()));
  }

  /// Removes a stored host key (e.g., when user deletes the SSH config).
  Future<void> remove(String host, int port) async {
    await _secrets.delete(_secretKey(host, port));
  }

  /// Verifies a presented fingerprint against the stored one.
  /// Returns:
  /// - `HostKeyVerification.unknown` if no key is stored (first connection)
  /// - `HostKeyVerification.match` if fingerprints match
  /// - `HostKeyVerification.mismatch` if fingerprints differ (security alert)
  Future<HostKeyVerification> verify(
    String host,
    int port,
    String fingerprint,
    String algorithm,
  ) async {
    final stored = await get(host, port);
    if (stored == null) {
      return HostKeyVerification.unknown(
        host: host,
        port: port,
        fingerprint: fingerprint,
        algorithm: algorithm,
      );
    }
    if (stored.fingerprint == fingerprint) {
      return const HostKeyVerification.match();
    }
    return HostKeyVerification.mismatch(
      stored: stored,
      presented: SshHostKey(
        host: host,
        port: port,
        fingerprint: fingerprint,
        algorithm: algorithm,
      ),
    );
  }
}

/// Result of host key verification.
class HostKeyVerification {
  const HostKeyVerification._({
    required this.status,
    this.host = '',
    this.port = 22,
    this.fingerprint = '',
    this.algorithm = '',
    this.storedKey,
    this.presentedKey,
  });

  final HostKeyStatus status;
  final String host;
  final int port;
  final String fingerprint;
  final String algorithm;
  final SshHostKey? storedKey;
  final SshHostKey? presentedKey;

  factory HostKeyVerification.unknown({
    required String host,
    required int port,
    required String fingerprint,
    required String algorithm,
  }) =>
      HostKeyVerification._(
        status: HostKeyStatus.unknown,
        host: host,
        port: port,
        fingerprint: fingerprint,
        algorithm: algorithm,
      );

  const HostKeyVerification.match()
      : this._(status: HostKeyStatus.match);

  factory HostKeyVerification.mismatch({
    required SshHostKey stored,
    required SshHostKey presented,
  }) =>
      HostKeyVerification._(
        status: HostKeyStatus.mismatch,
        storedKey: stored,
        presentedKey: presented,
      );

  bool get isMatch => status == HostKeyStatus.match;
  bool get isUnknown => status == HostKeyStatus.unknown;
  bool get isMismatch => status == HostKeyStatus.mismatch;
}

enum HostKeyStatus { unknown, match, mismatch }
