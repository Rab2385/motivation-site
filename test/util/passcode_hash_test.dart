import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/util/passcode_hash.dart';

void main() {
  test('a hash verifies the right secret and rejects a wrong one', () {
    final stored = hashSecret('1234');
    expect(isHashedSecret(stored), isTrue);
    expect(stored, isNot(contains('1234')));
    expect(verifySecret('1234', stored), isTrue);
    expect(verifySecret('1235', stored), isFalse);
    expect(verifySecret('', stored), isFalse);
  });

  test('the same secret hashes differently each time (random salt)', () {
    expect(hashSecret('1234'), isNot(hashSecret('1234')));
  });

  test('legacy plain text and malformed values never verify', () {
    expect(isHashedSecret('1234'), isFalse);
    expect(verifySecret('1234', '1234'), isFalse);
    expect(verifySecret('1234', 'pbkdf2-sha256\$x\$abc\$def'), isFalse);
    expect(verifySecret('1234', 'pbkdf2-sha256\$10\$!!\$!!'), isFalse);
  });

  test('matches the PBKDF2-HMAC-SHA256 reference vector (RFC 7914 §11)', () {
    // P="passwd", S="salt", c=1, dkLen=64 — first 32 bytes, base64.
    const stored =
        'pbkdf2-sha256\$1\$c2FsdA==\$VawEblbjCJ/sFpHCJUS2BflBhSFt3gRl5oudV8INrLw=';
    expect(verifySecret('passwd', stored), isTrue);
  });
}
