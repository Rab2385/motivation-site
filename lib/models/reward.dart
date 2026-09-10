import 'package:flutter/material.dart';

/// Icons a reward may use – kept const so web icon tree-shaking still works.
const Map<String, IconData> rewardIcons = {
  'game': Icons.sports_esports_outlined,
  'coffee': Icons.coffee_outlined,
  'movie': Icons.movie_outlined,
  'music': Icons.headphones_outlined,
  'food': Icons.restaurant_outlined,
  'book': Icons.auto_stories_outlined,
  'nature': Icons.forest_outlined,
  'sleep': Icons.bedtime_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'star': Icons.star_border,
};

IconData rewardIconFor(String key) => rewardIcons[key] ?? Icons.star_border;

/// A self-chosen reward that unlocks at a given level. Redeeming just records
/// that the user treated themselves – there is no XP cost, matching the
/// "earn your break" framing.
@immutable
class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.requiredLevel,
    required this.createdAt,
    this.redeemedCount = 0,
    this.lastRedeemedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final int requiredLevel;
  final DateTime createdAt;
  final int redeemedCount;
  final DateTime? lastRedeemedAt;

  IconData get icon => rewardIconFor(iconKey);

  bool isUnlocked(int level) => level >= requiredLevel;

  Reward copyWith({
    String? title,
    String? description,
    String? iconKey,
    int? requiredLevel,
    int? redeemedCount,
    DateTime? lastRedeemedAt,
  }) {
    return Reward(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      createdAt: createdAt,
      redeemedCount: redeemedCount ?? this.redeemedCount,
      lastRedeemedAt: lastRedeemedAt ?? this.lastRedeemedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'iconKey': iconKey,
        'requiredLevel': requiredLevel,
        'createdAt': createdAt.toIso8601String(),
        'redeemedCount': redeemedCount,
        'lastRedeemedAt': lastRedeemedAt?.toIso8601String(),
      };

  factory Reward.fromMap(Map<String, Object?> map) {
    return Reward(
      id: map['id']! as String,
      title: map['title']! as String,
      description: map['description'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? 'star',
      requiredLevel: (map['requiredLevel'] as num? ?? 1).toInt(),
      createdAt: DateTime.parse(map['createdAt']! as String),
      redeemedCount: (map['redeemedCount'] as num? ?? 0).toInt(),
      lastRedeemedAt: map['lastRedeemedAt'] == null
          ? null
          : DateTime.parse(map['lastRedeemedAt']! as String),
    );
  }

  static List<Reward> defaults(DateTime now) => [
        Reward(
          id: 'r_coffee',
          title: 'Kaffee-Pause',
          description: 'Eine wohlverdiente Auszeit.',
          iconKey: 'coffee',
          requiredLevel: 1,
          createdAt: now,
        ),
        Reward(
          id: 'r_game_30',
          title: '30 Minuten Gaming-Zeit',
          description: 'Ohne schlechtes Gewissen.',
          iconKey: 'game',
          requiredLevel: 3,
          createdAt: now,
        ),
        Reward(
          id: 'r_episode',
          title: 'Eine Folge deiner Serie',
          description: 'Zurücklehnen und genießen.',
          iconKey: 'movie',
          requiredLevel: 5,
          createdAt: now,
        ),
        Reward(
          id: 'r_game_60',
          title: '1 Stunde Gaming-Zeit',
          description: 'Der große Abend.',
          iconKey: 'game',
          requiredLevel: 8,
          createdAt: now,
        ),
        Reward(
          id: 'r_daytrip',
          title: 'Ausflug ins Grüne',
          description: 'Raus in die Natur, einen halben Tag lang.',
          iconKey: 'nature',
          requiredLevel: 12,
          createdAt: now,
        ),
      ];
}
