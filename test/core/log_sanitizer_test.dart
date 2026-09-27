import 'package:agentflow/core/log_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeSecret', () {
    test('returns empty for null', () {
      expect(sanitizeSecret(null), '');
    });

    test('returns empty for empty string', () {
      expect(sanitizeSecret(''), '');
    });

    test('redacts non-empty secrets', () {
      expect(sanitizeSecret('my-secret-password'), '[REDACTED]');
      expect(sanitizeSecret('Bearer abc123'), '[REDACTED]');
    });
  });

  group('sanitizeHeaders', () {
    test('redacts Authorization header', () {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer secret-token-123',
        'X-Custom': 'visible',
      };
      final sanitized = sanitizeHeaders(headers);
      expect(sanitized['Content-Type'], 'application/json');
      expect(sanitized['Authorization'], '[REDACTED]');
      expect(sanitized['X-Custom'], 'visible');
    });

    test('redacts Cookie header', () {
      final headers = <String, String>{
        'Cookie': 'session=abc123',
      };
      final sanitized = sanitizeHeaders(headers);
      expect(sanitized['Cookie'], '[REDACTED]');
    });

    test('redacts X-Api-Key header', () {
      final headers = <String, String>{
        'X-Api-Key': 'key-12345',
      };
      final sanitized = sanitizeHeaders(headers);
      expect(sanitized['X-Api-Key'], '[REDACTED]');
    });

    test('preserves non-sensitive headers', () {
      final headers = <String, String>{
        'Accept': 'application/json',
        'User-Agent': 'AgentFlow/1.0',
      };
      final sanitized = sanitizeHeaders(headers);
      expect(sanitized['Accept'], 'application/json');
      expect(sanitized['User-Agent'], 'AgentFlow/1.0');
    });

    test('is case-insensitive', () {
      final headers = <String, String>{
        'authorization': 'Basic dXNlcjpwYXNz',
        'AUTHORIZATION': 'Bearer token',
      };
      final sanitized = sanitizeHeaders(headers);
      expect(sanitized['authorization'], '[REDACTED]');
      expect(sanitized['AUTHORIZATION'], '[REDACTED]');
    });
  });

  group('sanitizeLogMessage', () {
    test('redacts Bearer tokens', () {
      expect(
        sanitizeLogMessage('Authorization: Bearer abc123xyz'),
        'Authorization: Bearer [REDACTED]',
      );
    });

    test('redacts password= values', () {
      expect(
        sanitizeLogMessage('password=mysecret123'),
        'password=[REDACTED]',
      );
    });

    test('redacts api_key= values', () {
      expect(
        sanitizeLogMessage('api_key=sk-12345'),
        'api_key=[REDACTED]',
      );
    });

    test('redacts token: values', () {
      expect(
        sanitizeLogMessage('token: my-token-value'),
        'token: [REDACTED]',
      );
    });

    test('redacts private key blocks', () {
      final input = '-----BEGIN RSA PRIVATE KEY-----\n'
          'MIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn\n'
          '-----END RSA PRIVATE KEY-----';
      final result = sanitizeLogMessage(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('MIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn')));
    });

    test('redacts SSH password patterns', () {
      expect(
        sanitizeLogMessage('ssh password: mysecretpassword'),
        'ssh password: [REDACTED]',
      );
    });

    test('leaves non-sensitive text unchanged', () {
      const input = 'Connected to server example.com on port 22';
      expect(sanitizeLogMessage(input), input);
    });

    test('handles multiple secrets in one message', () {
      final input = 'Connecting with password=abc and token: xyz123';
      final result = sanitizeLogMessage(input);
      expect(result, isNot(contains('abc')));
      expect(result, isNot(contains('xyz123')));
      expect(result, contains('[REDACTED]'));
    });
  });
}
