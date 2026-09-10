import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_text.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.maybeRollover();
    }
  }

  bool _darkMode = true;

  void _onChange() {
    if (widget.controller.darkMode != _darkMode) {
      setState(() => _darkMode = widget.controller.darkMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    _darkMode = widget.controller.darkMode;
    return MaterialApp(
      title: AppText.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MotivationShell(controller: widget.controller),
    );
  }
}
