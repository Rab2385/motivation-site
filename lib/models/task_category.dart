import 'package:flutter/material.dart';

/// The fixed set of icons a category may use. Kept as `const IconData` so the
/// web release build can still tree-shake the icon font. Categories store the
/// key, not a raw code point.
const Map<String, IconData> categoryIcons = {
  'fitness': Icons.fitness_center,
  'book': Icons.menu_book,
  'code': Icons.code,
  'mindful': Icons.self_improvement,
  'home': Icons.home_outlined,
  'health': Icons.favorite_border,
  'water': Icons.local_drink_outlined,
  'work': Icons.work_outline,
  'creative': Icons.brush_outlined,
  'social': Icons.groups_outlined,
  'money': Icons.savings_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'courage': Icons.bolt_outlined,
  'compass': Icons.explore_outlined,
  'star': Icons.star_border,
};

IconData iconForKey(String key) => categoryIcons[key] ?? Icons.star_border;

/// A user-managed category. Ships with seeded defaults; the user can add,
/// rename, recolour and archive their own.
///
/// [isFocusArea] doubles this up as a Life Grid area (see `domain/life_grid.dart`)
/// when the category is one of the eight life areas: true means it's a
/// current 90-day priority, false means "maintenance mode". It's meaningless
/// for a plain non-life-grid category.
@immutable
class TaskCategory {
  const TaskCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.sortOrder,
    this.isArchived = false,
    this.isFocusArea = false,
  });

  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final int sortOrder;
  final bool isArchived;
  final bool isFocusArea;

  Color get color => Color(colorValue);

  IconData get icon => iconForKey(iconKey);

  TaskCategory copyWith({
    String? name,
    int? colorValue,
    String? iconKey,
    int? sortOrder,
    bool? isArchived,
    bool? isFocusArea,
  }) {
    return TaskCategory(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      isFocusArea: isFocusArea ?? this.isFocusArea,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'iconKey': iconKey,
    'sortOrder': sortOrder,
    'isArchived': isArchived,
    'isFocusArea': isFocusArea,
  };

  factory TaskCategory.fromMap(Map<String, Object?> map) {
    return TaskCategory(
      id: map['id']! as String,
      name: map['name']! as String,
      colorValue: (map['colorValue'] as num).toInt(),
      iconKey: map['iconKey'] as String? ?? 'star',
      sortOrder: (map['sortOrder'] as num? ?? 0).toInt(),
      isArchived: map['isArchived'] as bool? ?? false,
      isFocusArea: map['isFocusArea'] as bool? ?? false,
    );
  }

  /// Seeded on first run. Six of these double as Life Grid areas once
  /// [MotivationController] runs the Life Grid seed (see `life_grid.dart`);
  /// `fitness`, `home` and `shopping` stay as plain, non-life-grid categories.
  static List<TaskCategory> defaults() => const [
    TaskCategory(
      id: 'fitness',
      name: 'Fitness',
      colorValue: 0xFFEF6C4D,
      iconKey: 'fitness',
      sortOrder: 0,
    ),
    TaskCategory(
      id: 'learning',
      name: 'Learning',
      colorValue: 0xFF4C8DFF,
      iconKey: 'book',
      sortOrder: 1,
    ),
    TaskCategory(
      id: 'coding',
      name: 'Coding',
      colorValue: 0xFF7C4DFF,
      iconKey: 'code',
      sortOrder: 2,
    ),
    TaskCategory(
      id: 'mindfulness',
      name: 'Mindfulness',
      colorValue: 0xFF26A69A,
      iconKey: 'mindful',
      sortOrder: 3,
    ),
    TaskCategory(
      id: 'work',
      name: 'Work',
      colorValue: 0xFF5E7CE2,
      iconKey: 'work',
      sortOrder: 4,
    ),
    TaskCategory(
      id: 'home',
      name: 'Home',
      colorValue: 0xFFFFB300,
      iconKey: 'home',
      sortOrder: 5,
    ),
    TaskCategory(
      id: 'health',
      name: 'Health',
      colorValue: 0xFF66BB6A,
      iconKey: 'health',
      sortOrder: 6,
    ),
    TaskCategory(
      id: 'shopping',
      name: 'Shopping',
      colorValue: 0xFFFF6B9D,
      iconKey: 'shopping',
      sortOrder: 7,
    ),
  ];
}
