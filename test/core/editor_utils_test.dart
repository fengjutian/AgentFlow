import 'package:flutter_test/flutter_test.dart';

// Import private functions via the library for testing.
// We test the logic directly since _isBinaryContent and _formatBytes
// are private to editor_page.dart.

void main() {
  group('_formatBytes', () {
    test('formats bytes correctly', () {
      expect(_formatBytes(0), '0 B');
      expect(_formatBytes(512), '512 B');
      expect(_formatBytes(1023), '1023 B');
    });

    test('formats kilobytes correctly', () {
      expect(_formatBytes(1024), '1.0 KB');
      expect(_formatBytes(1536), '1.5 KB');
      expect(_formatBytes(10240), '10.0 KB');
    });

    test('formats megabytes correctly', () {
      expect(_formatBytes(1024 * 1024), '1.0 MB');
      expect(_formatBytes(1536 * 1024), '1.5 MB');
      expect(_formatBytes(5 * 1024 * 1024), '5.0 MB');
    });
  });

  group('_isBinaryContent', () {
    test('returns false for plain text', () {
      expect(_isBinaryContent('Hello, world!'), isFalse);
      expect(_isBinaryContent('Line 1\nLine 2\nLine 3'), isFalse);
      expect(_isBinaryContent('const x = 42;'), isFalse);
    });

    test('returns false for unicode text', () {
      expect(_isBinaryContent('你好世界'), isFalse);
      expect(_isBinaryContent('Hello 世界 🌍'), isFalse);
      expect(_isBinaryContent('Café résumé'), isFalse);
    });

    test('returns true for null bytes', () {
      expect(_isBinaryContent('Hello\x00World'), isTrue);
      expect(_isBinaryContent('\x00\x00\x00'), isTrue);
      expect(_isBinaryContent('text\x00more text'), isTrue);
    });

    test('returns true for UTF-8 replacement character', () {
      expect(_isBinaryContent('HelloWorld'), isTrue);
      expect(_isBinaryContent('text more'), isTrue);
    });

    test('handles empty content', () {
      expect(_isBinaryContent(''), isFalse);
    });

    test('samples only first 8KB for large content', () {
      // Binary at the start should be detected.
      final binaryStart = 'Hello\x00World' + 'x' * 10000;
      expect(_isBinaryContent(binaryStart), isTrue);

      // Binary after 8KB should NOT be detected (by design for performance).
      final binaryEnd = 'x' * 10000 + '\x00';
      expect(_isBinaryContent(binaryEnd), isFalse);
    });
  });
}

/// Formats a byte count as a human-readable string.
/// Copy of the private function from editor_page.dart for testing.
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Returns true if the content appears to be binary.
/// Copy of the private function from editor_page.dart for testing.
bool _isBinaryContent(String content) {
  const sampleSize = 8192;
  final sample = content.length > sampleSize
      ? content.substring(0, sampleSize)
      : content;
  if (sample.contains('\x00')) return true;
  if (sample.contains('')) return true;
  return false;
}
