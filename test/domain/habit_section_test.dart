import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/habit_section.dart';

void main() {
  test('groupBySection buckets empty section names under General', () {
    final groups = groupBySection<String>(
      ['a', 'b'],
      (item) => item == 'a' ? '' : 'Morning',
    );
    expect(groups.map((e) => e.key), ['Morning', generalSection]);
  });

  test('known sections sort in their canonical order, General last', () {
    final groups = groupBySection<String>(
      ['w', 'm', 'd', 'g'],
      (item) => switch (item) {
        'w' => 'Wind Down',
        'm' => 'Morning',
        'd' => 'Deep Work',
        _ => '',
      },
    );
    expect(groups.map((e) => e.key), ['Morning', 'Deep Work', 'Wind Down', generalSection]);
  });

  test('unknown custom sections sort alphabetically after known ones', () {
    final groups = groupBySection<String>(
      ['z', 'm', 'a'],
      (item) => switch (item) {
        'z' => 'Zzz Custom',
        'm' => 'Morning',
        _ => 'Aaa Custom',
      },
    );
    expect(groups.map((e) => e.key), ['Morning', 'Aaa Custom', 'Zzz Custom']);
  });

  test('emojiForSection falls back to a dot for unknown names', () {
    expect(emojiForSection('Morning'), isNotEmpty);
    expect(emojiForSection('Something Else'), '▸');
  });
}
