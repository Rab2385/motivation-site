import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 for the app passcode and recovery code, so
/// neither is ever stored (or exported) in plain text.
///
/// Stored format: `pbkdf2-sha256$<iterations>$<salt b64>$<hash b64>`.
///
/// The iteration count is modest on purpose: hashing runs in Dart on the
/// web, and the passcode is a privacy lock, not encryption of the data.
const int passcodeHashIterations = 10000;
const String _scheme = 'pbkdf2-sha256';
const int _saltLength = 16;
const int _keyLength = 32;

/// Whether [stored] is in the hashed format (as opposed to a legacy
/// plain-text value written by older versions).
bool isHashedSecret(String stored) => stored.startsWith('$_scheme\$');

/// Hashes [secret] with a fresh random salt.
String hashSecret(
  String secret, {
  int iterations = passcodeHashIterations,
  Random? random,
}) {
  final rng = random ?? Random.secure();
  final salt = Uint8List.fromList(
    List<int>.generate(_saltLength, (_) => rng.nextInt(256)),
  );
  final key = _pbkdf2(utf8.encode(secret), salt, iterations, _keyLength);
  return '$_scheme\$$iterations\$${base64Encode(salt)}\$${base64Encode(key)}';
}

/// Checks [secret] against a value produced by [hashSecret]. Returns false
/// for anything malformed, including legacy plain-text values.
bool verifySecret(String secret, String stored) {
  final parts = stored.split('\$');
  if (parts.length != 4 || parts[0] != _scheme) return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 1) return false;
  final Uint8List salt;
  final Uint8List expected;
  try {
    salt = base64Decode(parts[2]);
    expected = base64Decode(parts[3]);
  } on FormatException {
    return false;
  }
  final actual = _pbkdf2(utf8.encode(secret), salt, iterations, expected.length);
  return _constantTimeEquals(actual, expected);
}

Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int length) {
  final hmac = Hmac(sha256, password);
  final out = BytesBuilder(copy: false);
  for (var block = 1; out.length < length; block++) {
    final blockIndex = [
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ];
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final t = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.add(t);
  }
  return Uint8List.sublistView(out.takeBytes(), 0, length);
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
