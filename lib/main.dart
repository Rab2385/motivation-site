import 'package:flutter/material.dart';

import 'app/motivation_app.dart';
import 'data/motivation_database.dart';
import 'state/motivation_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = MotivationController(MotivationDatabase());

  try {
    await controller.initialize();
  } catch (error, stackTrace) {
    debugPrint('Motivation failed to start: $error\n$stackTrace');
    runApp(_StartupErrorApp(error: error));
    return;
  }

  runApp(MotivationApp(controller: controller));
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Motivation konnte nicht gestartet werden.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Der lokale Speicher konnte nicht geöffnet werden. '
                    'Im privaten Modus mancher Browser ist das erwartbar – '
                    'dann bitte in einem normalen Fenster erneut öffnen.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
