import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The bordered card toast used for quest completions, unlocks and redemptions.
void showQuestToast(
  BuildContext context, {
  required String title,
  String? subtitle,
  int? xp,
  IconData icon = Icons.check_circle,
  Color accent = AppTheme.successAccent,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final width = MediaQuery.sizeOf(context).width;
  final rightMargin = width > 620 ? width - 420.0 : 16.0;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(left: 16, right: rightMargin, bottom: 16),
        content: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                            color: AppTheme.textMid, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (xp != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$xp XP',
                    style: const TextStyle(
                      color: AppTheme.goldBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
}
