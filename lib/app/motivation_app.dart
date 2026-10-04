import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_text.dart';
import '../pages/login_gate.dart';
import '../pages/motivation_shell.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';

class MotivationApp extends StatefulWidget {
  const MotivationApp({
    super.key,
    required this.controller,
    this.relockAfter = const Duration(minutes: 5),
  });

  final MotivationController controller;

  /// How long the app may sit in the background before it locks again.
  final Duration relockAfter;

  @override
  State<MotivationApp> createState() => _MotivationAppState();
}

class _MotivationAppState extends State<MotivationApp>
    with WidgetsBindingObserver {
  // Always start on the gate: it unlocks with the passcode, or asks to set
  // one when none exists yet.
  bool _isUnlocked = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (_isUnlocked &&
            widget.controller.hasAppPasscode &&
            since != null &&
            DateTime.now().difference(since) >= widget.relockAfter) {
          setState(() => _isUnlocked = false);
        }
        widget.controller.maybeRollover();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppText.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _isUnlocked
          ? MotivationShell(controller: widget.controller)
          : LoginGate(
              controller: widget.controller,
              onUnlocked: () => setState(() => _isUnlocked = true),
            ),
    );
  }
}
