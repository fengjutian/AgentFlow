import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrivacyConsentStore {
  const PrivacyConsentStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'legal/privacy-consent-v1';
  final FlutterSecureStorage _storage;

  Future<bool> hasConsent() async => (await _storage.read(key: _key)) == 'yes';

  Future<void> grant() => _storage.write(key: _key, value: 'yes');

  Future<void> withdraw() => _storage.delete(key: _key);
}
