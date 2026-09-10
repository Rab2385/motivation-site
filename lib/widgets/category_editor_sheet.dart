import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/task_category.dart';
import '../state/motivation_controller.dart';

const List<int> _palette = [
  0xFFEF6C4D,
  0xFF4C8DFF,
  0xFF7C4DFF,
  0xFF26A69A,
  0xFFFFB300,
  0xFF66BB6A,
  0xFFEC407A,
  0xFF8D6E63,
];

Future<void> showCategoryEditorSheet(
  BuildContext context,
  MotivationController controller, {
  TaskCategory? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _CategoryEditorSheet(controller: controller, existing: existing),
  );
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({required this.controller, this.existing});

  final MotivationController controller;
  final TaskCategory? existing;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late int _color = widget.existing?.colorValue ?? _palette.first;
  late String _iconKey = widget.existing?.iconKey ?? 'star';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? AppText.add : AppText.edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: AppText.title),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final color in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: CircleAvatar(
                      backgroundColor: Color(color),
                      radius: 16,
                      child: _color == color
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in categoryIcons.entries)
                  ChoiceChip(
                    label: Icon(entry.value, size: 18),
                    selected: _iconKey == entry.key,
                    onSelected: (_) => setState(() => _iconKey = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _name.text.trim().isEmpty
                  ? null
                  : () {
                      final controller = widget.controller;
                      if (widget.existing == null) {
                        controller.addCategory(
                          name: _name.text,
                          colorValue: _color,
                          iconKey: _iconKey,
                        );
                      } else {
                        controller.updateCategory(
                          widget.existing!.id,
                          name: _name.text,
                          colorValue: _color,
                          iconKey: _iconKey,
                        );
                      }
                      Navigator.of(context).pop();
                    },
              child: const Text(AppText.save),
            ),
          ],
        ),
      ),
    );
  }
}
