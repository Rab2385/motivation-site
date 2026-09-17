import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/terminal_widgets.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _shortcuts = [
    ('← / →', 'previous / next day'),
    ('1-5', 'switch between habits / stats / profile / system / help'),
    ('a', 'add a new habit'),
    ('space / enter', 'toggle the focused habit'),
    ('?', 'toggle this help'),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TerminalPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TerminalHeader('help', comment: 'keyboard shortcuts & about'),
                  const SizedBox(height: 14),
                  Text('keyboard shortcuts', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  for (final (key, label) in _shortcuts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.cardInset,
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(key,
                                style: const TextStyle(
                                    fontFamilyFallback: AppTheme.mono,
                                    color: AppTheme.amberBright,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(label,
                                style: const TextStyle(color: AppTheme.textMid, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text('about', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(AppText.aboutText,
                      style: TextStyle(color: AppTheme.textMid, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
