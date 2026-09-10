import 'dart:math';

final Random _random = Random();

/// A short, sortable-ish unique id: microsecond timestamp + random suffix.
///
/// The suffix uses two sub-2^30 draws because `Random.nextInt` is capped at
/// 2^32 and `1 << 32` overflows to 0 on the web.
String newId([String prefix = '']) {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = (_random.nextInt(1 << 30).toRadixString(36)) +
      _random.nextInt(1 << 30).toRadixString(36);
  return prefix.isEmpty ? '${time}_$salt' : '${prefix}_${time}_$salt';
}
