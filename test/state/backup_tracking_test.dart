import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/state/motivation_controller.dart';
import 'package:sembast/sembast_memory.dart';

/// Backup download, last-backup bookkeeping and the home nudge.
void main() {
  late MotivationDatabase db;
  late List<(String, String)> saved;

  setUp(() {
    db = MotivationDatabase.withFactory(newDatabaseFactoryMemory(), 'test.db');
    saved = [];
  });

  Future<MotivationController> ready() async {
    final controller = MotivationController(
      db,
      saveFile: (name, contents) async {
        saved.add((name, contents));
        return 'test/$name';
      },
    );
    await controller.initialize();
    return controller;
  }

  test('download saves a dated json file and records the backup', () async {
    final controller = await ready();
    expect(controller.lastBackupAt, isNull);

    final location = await controller.downloadBackup();

    expect(saved, hasLength(1));
    final (name, contents) = saved.single;
    expect(name, matches(RegExp(r'^quest-backup-\d{4}-\d{2}-\d{2}\.json$')));
    expect(location, 'test/$name');
    expect((jsonDecode(contents) as Map)['formatVersion'], 1);
    expect(controller.lastBackupAt, isNotNull);

    final reloaded = await ready();
    expect(reloaded.lastBackupAt, controller.lastBackupAt);
  });

  test('nudge: due after the interval, hidden by a backup or a snooze',
      () async {
    final controller = await ready();
    final now = DateTime.now();
    await controller.markBackedUp(now.subtract(const Duration(days: 10)));
    expect(controller.isBackupNudgeDueAt(now), isTrue);

    await controller.snoozeBackupNudge(now);
    expect(controller.isBackupNudgeDueAt(now), isFalse);
    expect(
      controller.isBackupNudgeDueAt(now.add(const Duration(days: 8))),
      isTrue,
    );

    await controller.markBackedUp(now);
    expect(controller.isBackupNudgeDueAt(now), isFalse);

    await controller.setBackupReminderDays(0);
    expect(
      controller.isBackupNudgeDueAt(now.add(const Duration(days: 365))),
      isFalse,
    );
    expect((await ready()).backupReminderDays, 0);
  });

  test('backup bookkeeping stays on the device across export and import',
      () async {
    final controller = await ready();
    final old = DateTime(2026, 1, 1);
    await controller.markBackedUp(old);
    final backup = await controller.exportBackupJson();
    final settings = ((jsonDecode(backup) as Map)['data'] as Map)['settings'];
    expect((settings as Map).containsKey('lastBackupAt'), isFalse);

    final recent = DateTime(2026, 10, 1);
    await controller.markBackedUp(recent);
    await controller.importBackupJson(backup);

    expect(controller.lastBackupAt, recent);
  });
}
