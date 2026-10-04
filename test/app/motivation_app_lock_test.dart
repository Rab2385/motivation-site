import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/app/motivation_app.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/pages/login_gate.dart';
import 'package:motivation/pages/motivation_shell.dart';
import 'package:motivation/state/motivation_controller.dart';
import 'package:sembast/sembast_memory.dart';

/// The app must open on the passcode gate, whether or not a passcode exists,
/// and lock again after sitting in the background.
void main() {
  late MotivationController controller;

  Future<void> setUpController(WidgetTester tester, {String? passcode}) async {
    await tester.runAsync(() async {
      final db = MotivationDatabase.withFactory(
        newDatabaseFactoryMemory(),
        'test.db',
      );
      controller = MotivationController(db);
      await controller.initialize();
      if (passcode != null) {
        await controller.setAppPasscode(passcode, recoveryCode: 'QUEST-1-2');
      }
    });
  }

  void useDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('with a passcode set, the app opens locked', (tester) async {
    await setUpController(tester, passcode: '2468');
    await tester.pumpWidget(MotivationApp(controller: controller));
    await tester.pump();

    expect(find.byType(LoginGate), findsOneWidget);
    expect(find.byType(MotivationShell), findsNothing);
    expect(find.text('Enter your passcode'), findsOneWidget);
    expect(find.text('View recovery code'), findsNothing);
  });

  testWidgets('without a passcode, the app asks to set one', (tester) async {
    await setUpController(tester);
    await tester.pumpWidget(MotivationApp(controller: controller));
    await tester.pump();

    expect(find.byType(LoginGate), findsOneWidget);
    expect(find.text('Set a passcode'), findsOneWidget);
  });

  testWidgets('a wrong passcode stays locked, the right one unlocks',
      (tester) async {
    useDesktopSize(tester);
    await setUpController(tester, passcode: '2468');
    await tester.pumpWidget(MotivationApp(controller: controller));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('Enter'));
    await tester.pump();
    expect(find.text('Incorrect passcode.'), findsOneWidget);
    expect(find.byType(MotivationShell), findsNothing);

    await tester.enterText(find.byType(TextField), '2468');
    await tester.tap(find.text('Enter'));
    await tester.pump();
    expect(find.byType(MotivationShell), findsOneWidget);
  });

  testWidgets('locks again after being in the background', (tester) async {
    useDesktopSize(tester);
    await setUpController(tester, passcode: '2468');
    await tester.pumpWidget(
      MotivationApp(controller: controller, relockAfter: Duration.zero),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '2468');
    await tester.tap(find.text('Enter'));
    await tester.pump();
    expect(find.byType(MotivationShell), findsOneWidget);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(find.byType(LoginGate), findsOneWidget);
    expect(find.byType(MotivationShell), findsNothing);
  });
}
