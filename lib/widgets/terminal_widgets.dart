import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// `$ section` heading with an optional `// comment` line underneath —
/// the recurring section-header motif of the terminal UI.
class TerminalHeader extends StatelessWidget {
  const TerminalHeader(this.label, {super.key, this.comment, this.trailing});

  final String label;
  final String? comment;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('\$ ',
                style: TextStyle(
                    fontFamilyFallback: AppTheme.mono,
                    color: AppTheme.amber,
                    fontWeight: FontWeight.w700)),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamilyFallback: AppTheme.mono,
                  color: AppTheme.textHigh,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        if (comment != null) ...[
          const SizedBox(height: 3),
          Text('// $comment', style: AppTheme.comment.copyWith(fontSize: 11.5)),
        ],
      ],
    );
  }
}

/// A bordered panel with the standard card chrome, used for every box in the
/// three-column layout.
class TerminalPanel extends StatelessWidget {
  const TerminalPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: padding ?? const EdgeInsets.all(14),
      child: child,
    );
  }
}

/// `user[pro]@Quest $ command` breadcrumb line.
class PromptLine extends StatelessWidget {
  const PromptLine(this.command, {super.key, this.user = 'you'});

  final String command;
  final String user;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamilyFallback: AppTheme.mono, fontSize: 12),
        children: [
          TextSpan(text: user, style: const TextStyle(color: AppTheme.successAccent)),
          const TextSpan(text: '[pro]', style: TextStyle(color: AppTheme.textLow)),
          const TextSpan(text: '@Quest ', style: TextStyle(color: AppTheme.textMid)),
          const TextSpan(text: r'$ ', style: TextStyle(color: AppTheme.amber)),
          TextSpan(text: command, style: const TextStyle(color: AppTheme.textHigh)),
        ],
      ),
    );
  }
}

/// Linear bracket-style progress bar: `[####------]  33%`.
class BarProgress extends StatelessWidget {
  const BarProgress({
    super.key,
    required this.fraction,
    this.color = AppTheme.amber,
    this.height = 8,
    this.label,
  });

  final double fraction;
  final Color color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(height: height, color: const Color(0xFF19212F)),
                FractionallySizedBox(
                  widthFactor: clamped,
                  child: Container(height: height, color: color),
                ),
              ],
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(label!,
              style: const TextStyle(
                  fontFamilyFallback: AppTheme.mono,
                  color: AppTheme.textMid,
                  fontSize: 11.5)),
        ],
      ],
    );
  }
}

/// The vim-style keyboard-shortcut hint strip along the bottom of the app.
class KeyboardHintBar extends StatelessWidget {
  const KeyboardHintBar({super.key, required this.hints});

  final List<(String, String)> hints;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgRaised,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Wrap(
        spacing: 18,
        runSpacing: 4,
        children: [
          for (final (key, label) in hints)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontFamilyFallback: AppTheme.mono, fontSize: 11),
                children: [
                  TextSpan(
                      text: key,
                      style: const TextStyle(
                          color: AppTheme.amberBright, fontWeight: FontWeight.w700)),
                  TextSpan(text: ' $label', style: const TextStyle(color: AppTheme.textLow)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
