import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_text.dart';
import '../pages/login_gate.dart';
import '../pages/motivation_shell.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';

class MotivationApp extends StatefulWidget {
  const MotivationApp({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<MotivationApp> createState() => _MotivationAppState();
}

class _MotivationAppState extends State<MotivationApp>
    with WidgetsBindingObserver {
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isUnlocked = widget.controller.hasAppPasscode;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.maybeRollover();
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
