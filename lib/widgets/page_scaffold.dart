import 'package:flutter/material.dart';

/// Shared page chrome: an app bar plus a width-constrained, scrollable body
/// that rebuilds with the controller.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.listenable,
    required this.builder,
    this.actions,
    this.floatingActionButton,
    this.maxContentWidth = 720,
  });

  final String title;
  final Listenable listenable;
  final WidgetBuilder builder;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: builder(context),
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
