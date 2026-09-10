import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared page chrome: a serif page title (+ optional subline and actions) over
/// a width-constrained, scrollable body that rebuilds with the controller.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.listenable,
    required this.builder,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.maxContentWidth = 820,
  });

  final String title;
  final String? subtitle;
  final Listenable listenable;
  final WidgetBuilder builder;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 26),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(subtitle!,
                                  style: const TextStyle(
                                      color: AppTheme.textMid)),
                            ],
                          ],
                        ),
                      ),
                      ...?actions,
                    ],
                  ),
                ),
                Expanded(child: builder(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 0.8,
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
