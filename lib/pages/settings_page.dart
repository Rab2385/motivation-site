import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../widgets/category_editor_sheet.dart';
import '../widgets/page_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.settings,
      listenable: controller,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionHeader(AppText.dayTargets),
            for (var index = 0; index < 7; index++)
              _TargetRow(controller: controller, weekdayIndex: index),
            const SectionHeader(AppText.categoriesTitle),
            for (final category in controller.categories)
              ListTile(
                leading: Icon(category.icon, color: category.color),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => showCategoryEditorSheet(
                        context,
                        controller,
                        existing: category,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => controller.deleteCategory(category.id),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showCategoryEditorSheet(context, controller),
                icon: const Icon(Icons.add),
                label: const Text(AppText.add),
              ),
            ),
            const SectionHeader(AppText.backup),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text(AppText.exportBackup),
              onTap: () => _export(context),
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: const Text(AppText.importBackup),
              onTap: () => _import(context),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => _clear(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text(AppText.clearData),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _export(BuildContext context) async {
    final json = await controller.exportBackupJson();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppText.exportBackup),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: SelectableText(json,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(context);
            },
            child: const Text('Kopieren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppText.close),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final textController = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppText.importBackup),
        content: TextField(
          controller: textController,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Backup-JSON einfügen …'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppText.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text(AppText.importBackup),
          ),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty) return;
    try {
      await controller.importBackupJson(raw);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup importiert.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import fehlgeschlagen: $error')),
        );
      }
    }
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppText.clearData),
        content: const Text(AppText.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppText.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppText.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clearAllData();
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.controller, required this.weekdayIndex});

  final MotivationController controller;
  final int weekdayIndex;

  @override
  Widget build(BuildContext context) {
    final value = controller.dayTargetXp[weekdayIndex];
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(AppText.weekdayShort[weekdayIndex]),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(0, 400),
            min: 0,
            max: 400,
            divisions: 40,
            label: '$value',
            onChanged: (next) => controller.setDayTargetXp(
                weekdayIndex, (next / 10).round() * 10),
          ),
        ),
        SizedBox(width: 48, child: Text('$value XP')),
      ],
    );
  }
}
