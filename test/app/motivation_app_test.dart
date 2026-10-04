import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/app/motivation_app.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/pages/motivation_shell.dart';
import 'package:motivation/state/motivation_controller.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets('opens straight into the app, without a lock screen',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late MotivationController controller;
    await tester.runAsync(() async {
      final db = MotivationDatabase.withFactory(
        newDatabaseFactoryMemory(),
        'test.db',
      );
      await db.saveSetting('appPasscode', '1357');
      controller = MotivationController(db);
      await controller.initialize();
    });

    await tester.pumpWidget(MotivationApp(controller: controller));
    await tester.pump();

    expect(find.byType(MotivationShell), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
