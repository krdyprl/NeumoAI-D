import 'dart:math';

final Random _rng = Random.secure();
const String _hex = '0123456789abcdef';

/// Generates a random RFC-4122 v4 UUID string (e.g. for screening ids).
String generateUuid() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
  final sb = StringBuffer();
  for (var i = 0; i < 16; i++) {
    if (i == 4 || i == 6 || i == 8 || i == 10) sb.write('-');
    sb.write(_hex[(bytes[i] >> 4) & 0xf]);
    sb.write(_hex[bytes[i] & 0xf]);
  }
  return sb.toString();
}
