/// Task priority — purely informational (sorting/emphasis), doesn't affect XP.
enum Priority {
  low(label: 'Low'),
  normal(label: 'Normal'),
  high(label: 'High');

  const Priority({required this.label});

  final String label;

  static Priority fromName(String? name) {
    for (final value in Priority.values) {
      if (value.name == name) return value;
    }
    return Priority.normal;
  }
}
