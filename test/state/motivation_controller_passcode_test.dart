import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/state/motivation_controller.dart';
import 'package:motivation/util/passcode_hash.dart';
import 'package:sembast/sembast_memory.dart';

/// The passcode and recovery code are stored only as salted hashes, legacy
/// plain-text values are migrated on load, and backups never carry them.
void main() {
  late MotivationDatabase db;

  setUp(() {
    db = MotivationDatabase.withFactory(newDatabaseFactoryMemory(), 'test.db');
  });

  Future<MotivationController> ready() async {
    final controller = MotivationController(db);
    await controller.initialize();
    return controller;
  }

  test('stores hashes, never the plain passcode or recovery code', () async {
    final controller = await ready();
    await controller.setAppPasscode('2468', recoveryCode: 'QUEST-111111-222222');

    final passcode = await db.loadSetting('appPasscode') as String;
    final recovery = await db.loadSetting('appRecoveryCode') as String;
    expect(isHashedSecret(passcode), isTrue);
    expect(isHashedSecret(recovery), isTrue);
    expect(passcode, isNot(contains('2468')));
    expect(recovery, isNot(contains('QUEST-111111-222222')));

    expect(controller.hasAppPasscode, isTrue);
    expect(await controller.validateAppPasscode('2468'), isTrue);
    expect(await controller.validateAppPasscode(' 2468 '), isTrue);
    expect(await controller.validateAppPasscode('0000'), isFalse);
  });

  test('a reload validates against the stored hash', () async {
    final first = await ready();
    await first.setAppPasscode('2468', recoveryCode: 'QUEST-111111-222222');

    final second = await ready();
    expect(second.hasAppPasscode, isTrue);
    expect(await second.validateAppPasscode('2468'), isTrue);
    expect(await second.validateRecoveryCode('QUEST-111111-222222'), isTrue);
  });

  test('legacy plain-text values are hashed on load and still work', () async {
    await db.saveSetting('appPasscode', '1357');
    await db.saveSetting('appRecoveryCode', 'QUEST-333333-444444');

    final controller = await ready();
    expect(isHashedSecret(await db.loadSetting('appPasscode') as String), isTrue);
    expect(
      isHashedSecret(await db.loadSetting('appRecoveryCode') as String),
      isTrue,
    );
    expect(await controller.validateAppPasscode('1357'), isTrue);
    expect(await controller.validateRecoveryCode('QUEST-333333-444444'), isTrue);
  });

  test('reset needs the right recovery code', () async {
    final controller = await ready();
    await controller.setAppPasscode('2468', recoveryCode: 'QUEST-111111-222222');

    await expectLater(
      controller.resetAppPasscode(
        recoveryCode: 'QUEST-000000-000000',
        newPasscode: '9999',
      ),
      throwsArgumentError,
    );
    expect(await controller.validateAppPasscode('2468'), isTrue);

    await controller.resetAppPasscode(
      recoveryCode: 'QUEST-111111-222222',
      newPasscode: '9999',
    );
    expect(await controller.validateAppPasscode('9999'), isTrue);
    expect(await controller.validateAppPasscode('2468'), isFalse);
  });

  test('backups leave out the passcode, recovery code and safety copy',
      () async {
    final controller = await ready();
    await controller.setAppPasscode('2468', recoveryCode: 'QUEST-111111-222222');
    await db.saveSetting('__safetyBackup', '{"data":{}}');
    await db.saveSetting('userName', 'Sam');

    final exported = jsonDecode(await controller.exportBackupJson()) as Map;
    final settings = (exported['data'] as Map)['settings'] as Map;
    expect(settings.containsKey('appPasscode'), isFalse);
    expect(settings.containsKey('appRecoveryCode'), isFalse);
    expect(settings.containsKey('__safetyBackup'), isFalse);
    expect(settings['userName'], 'Sam');
  });

  test('importing a backup keeps the current passcode', () async {
    final controller = await ready();
    final backup = await controller.exportBackupJson();
    await controller.setAppPasscode('2468', recoveryCode: 'QUEST-111111-222222');

    await controller.importBackupJson(backup);

    expect(controller.hasAppPasscode, isTrue);
    expect(await controller.validateAppPasscode('2468'), isTrue);
    expect(await controller.validateRecoveryCode('QUEST-111111-222222'), isTrue);
    final safety = await db.loadSetting('__safetyBackup') as String;
    expect(jsonDecode(safety), contains('data'));
  });

  test('an old backup with a plain-text passcode cannot replace it', () async {
    final controller = await ready();
    final envelope = jsonDecode(await controller.exportBackupJson()) as Map;
    ((envelope['data'] as Map)['settings'] as Map)
      ..['appPasscode'] = '0000'
      ..['appRecoveryCode'] = 'QUEST-000000-000000';
    await controller.setAppPasscode('2468', recoveryCode: 'QUEST-111111-222222');

    await controller.importBackupJson(jsonEncode(envelope));

    expect(await controller.validateAppPasscode('2468'), isTrue);
    expect(await controller.validateAppPasscode('0000'), isFalse);
    expect(await controller.validateRecoveryCode('QUEST-000000-000000'), isFalse);
  });
}
