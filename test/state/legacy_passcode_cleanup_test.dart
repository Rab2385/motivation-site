import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/state/motivation_controller.dart';
import 'package:sembast/sembast_memory.dart';

/// The passcode lock was removed. Values older versions stored (in plain
/// text) are deleted on load and never travel in a backup.
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

  test('a stored passcode and recovery code are deleted on load', () async {
    await db.saveSetting('appPasscode', '1357');
    await db.saveSetting('appRecoveryCode', 'QUEST-333333-444444');

    await ready();

    expect(await db.loadSetting('appPasscode'), isNull);
    expect(await db.loadSetting('appRecoveryCode'), isNull);
  });

  test('backups leave out the old passcode keys and the safety copy',
      () async {
    final controller = await ready();
    await db.saveSetting('appPasscode', '1357');
    await db.saveSetting('__safetyBackup', '{"data":{}}');
    await db.saveSetting('userName', 'Sam');

    final exported = jsonDecode(await controller.exportBackupJson()) as Map;
    final settings = (exported['data'] as Map)['settings'] as Map;
    expect(settings.containsKey('appPasscode'), isFalse);
    expect(settings.containsKey('__safetyBackup'), isFalse);
    expect(settings['userName'], 'Sam');
  });

  test('importing an old backup works and drops its passcode', () async {
    final controller = await ready();
    final envelope = jsonDecode(await controller.exportBackupJson()) as Map;
    ((envelope['data'] as Map)['settings'] as Map)
      ..['appPasscode'] = '0000'
      ..['userName'] = 'Sam';

    await controller.importBackupJson(jsonEncode(envelope));

    expect(controller.userName, 'Sam');
    expect(await db.loadSetting('appPasscode'), isNull);
    final safety = await db.loadSetting('__safetyBackup') as String;
    expect(jsonDecode(safety), contains('data'));
  });
}
