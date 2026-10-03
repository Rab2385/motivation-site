import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sembast/sembast.dart';

import '../models/milestone.dart';
import '../models/proposal.dart';
import '../models/task_category.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../models/week_template.dart';
import '../models/weight_entry.dart';
import 'database_open.dart';

/// Everything loaded from disk in one shot at startup.
class DatabaseSnapshot {
  const DatabaseSnapshot({
    required this.categories,
    required this.definitions,
    required this.occurrences,
    required this.templates,
    required this.proposals,
    required this.milestones,
    required this.weightEntries,
    required this.achievementUnlocks,
    required this.settings,
    required this.meta,
  });

  final List<TaskCategory> categories;
  final List<TaskDefinition> definitions;
  final List<TaskOccurrence> occurrences;
  final List<WeekTemplate> templates;
  final List<Proposal> proposals;
  final List<Milestone> milestones;
  final List<WeightEntry> weightEntries;

  /// achievementId -> unlockedAt.
  final Map<String, DateTime> achievementUnlocks;
  final Map<String, Object?> settings;
  final Map<String, Object?> meta;
}

/// Thin persistence layer over Sembast. All writes the app makes go through
/// [PlanService], which in turn uses this class; widgets never touch it.
class MotivationDatabase {
  MotivationDatabase() : _injectedFactory = null, _databaseName = _defaultName;

  /// Test-only: run against an injected (e.g. in-memory) factory.
  @visibleForTesting
  MotivationDatabase.withFactory(this._injectedFactory, this._databaseName);

  static const String _defaultName = 'motivation.db';

  final DatabaseFactory? _injectedFactory;
  final String _databaseName;

  final _categories = stringMapStoreFactory.store('categories');
  final _definitions = stringMapStoreFactory.store('task_definitions');
  final _occurrences = stringMapStoreFactory.store('occurrences');
  final _templates = stringMapStoreFactory.store('week_templates');
  final _proposals = stringMapStoreFactory.store('proposals');
  final _milestones = stringMapStoreFactory.store('milestones');
  final _weightEntries = stringMapStoreFactory.store('weight_entries');
  final _achievements = stringMapStoreFactory.store('achievement_unlocks');
  final _settings = StoreRef<String, Object?>('settings');
  final _meta = StoreRef<String, Object?>('meta');

  Database? _database;

  Future<Database> get _db async {
    return _database ??= _injectedFactory != null
        ? await _injectedFactory.openDatabase(_databaseName, version: 1)
        : await openMotivationDatabase(_databaseName);
  }

  Future<DatabaseSnapshot> loadAll() async {
    final db = await _db;

    final categories =
        (await _categories.find(
            db,
          )).map((r) => TaskCategory.fromMap(r.value)).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final definitions = (await _definitions.find(
      db,
    )).map((r) => TaskDefinition.fromMap(r.value)).toList();

    final occurrences = (await _occurrences.find(
      db,
    )).map((r) => TaskOccurrence.fromMap(r.value)).toList();

    final templates =
        (await _templates.find(
            db,
          )).map((r) => WeekTemplate.fromMap(r.value)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final proposals = (await _proposals.find(
      db,
    )).map((r) => Proposal.fromMap(r.value)).toList();

    final milestones =
        (await _milestones.find(
            db,
          )).map((r) => Milestone.fromMap(r.value)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final weightEntries =
        (await _weightEntries.find(
            db,
          )).map((r) => WeightEntry.fromMap(r.value)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final achievementUnlocks = <String, DateTime>{};
    for (final record in await _achievements.find(db)) {
      final at = record.value['unlockedAt'] as String?;
      if (at != null) achievementUnlocks[record.key] = DateTime.parse(at);
    }

    final settings = {
      for (final record in await _settings.find(db)) record.key: record.value,
    };
    final meta = {
      for (final record in await _meta.find(db)) record.key: record.value,
    };

    return DatabaseSnapshot(
      categories: categories,
      definitions: definitions,
      occurrences: occurrences,
      templates: templates,
      proposals: proposals,
      milestones: milestones,
      weightEntries: weightEntries,
      achievementUnlocks: achievementUnlocks,
      settings: settings,
      meta: meta,
    );
  }

  // ---- Categories ---------------------------------------------------------

  Future<void> saveCategory(TaskCategory category) async =>
      _categories.record(category.id).put(await _db, category.toMap());

  Future<void> deleteCategory(String id) async =>
      _categories.record(id).delete(await _db);

  // ---- Definitions ------------------------------------------------------

  Future<void> saveDefinition(TaskDefinition definition) async =>
      _definitions.record(definition.id).put(await _db, definition.toMap());

  Future<void> deleteDefinition(String id) async =>
      _definitions.record(id).delete(await _db);

  // ---- Occurrences ------------------------------------------------------

  Future<void> saveOccurrence(TaskOccurrence occurrence) async =>
      _occurrences.record(occurrence.id).put(await _db, occurrence.toMap());

  Future<void> saveOccurrences(List<TaskOccurrence> occurrences) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final occurrence in occurrences) {
        await _occurrences.record(occurrence.id).put(txn, occurrence.toMap());
      }
    });
  }

  Future<void> deleteOccurrences(List<String> ids) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final id in ids) {
        await _occurrences.record(id).delete(txn);
      }
    });
  }

  // ---- Templates ------------------------------------------------------

  Future<void> saveTemplate(WeekTemplate template) async =>
      _templates.record(template.id).put(await _db, template.toMap());

  Future<void> deleteTemplate(String id) async =>
      _templates.record(id).delete(await _db);

  // ---- Proposals ------------------------------------------------------

  Future<void> saveProposal(Proposal proposal) async =>
      _proposals.record(proposal.id).put(await _db, proposal.toMap());

  Future<void> deleteProposal(String id) async =>
      _proposals.record(id).delete(await _db);

  // ---- Milestones ------------------------------------------------------

  Future<void> saveMilestone(Milestone milestone) async =>
      _milestones.record(milestone.id).put(await _db, milestone.toMap());

  Future<void> deleteMilestone(String id) async =>
      _milestones.record(id).delete(await _db);

  // ---- Weight entries ------------------------------------------------------

  Future<void> saveWeightEntry(WeightEntry entry) async =>
      _weightEntries.record(entry.id).put(await _db, entry.toMap());

  Future<void> deleteWeightEntry(String id) async =>
      _weightEntries.record(id).delete(await _db);

  // ---- Achievements ------------------------------------------------------

  Future<void> saveAchievementUnlock(String id, DateTime unlockedAt) async =>
      _achievements.record(id).put(await _db, {
        'unlockedAt': unlockedAt.toIso8601String(),
      });

  // ---- Settings / meta ------------------------------------------------------

  Future<void> saveSetting(String key, Object? value) async {
    final db = await _db;
    if (value == null) {
      await _settings.record(key).delete(db);
      return;
    }
    await _settings.record(key).put(db, value);
  }

  Future<Object?> loadSetting(String key) async {
    final db = await _db;
    return _settings.record(key).get(db);
  }

  Future<void> saveMeta(String key, Object? value) async {
    final db = await _db;
    if (value == null) {
      await _meta.record(key).delete(db);
      return;
    }
    await _meta.record(key).put(db, value);
  }

  // ---- Backup ------------------------------------------------------

  Future<Map<String, Object?>> exportData() async {
    final db = await _db;
    Future<List<Map<String, Object?>>> dump(
      StoreRef<String, Map<String, Object?>> store,
    ) async => (await store.find(db)).map((r) => r.value).toList();

    return {
      'categories': await dump(_categories),
      'task_definitions': await dump(_definitions),
      'occurrences': await dump(_occurrences),
      'week_templates': await dump(_templates),
      'proposals': await dump(_proposals),
      'milestones': await dump(_milestones),
      'weight_entries': await dump(_weightEntries),
      'achievement_unlocks': {
        for (final r in await _achievements.find(db)) r.key: r.value,
      },
      'settings': {for (final r in await _settings.find(db)) r.key: r.value},
      'meta': {for (final r in await _meta.find(db)) r.key: r.value},
    };
  }

  Future<void> replaceAll(Map<String, Object?> data) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _categories.delete(txn);
      await _definitions.delete(txn);
      await _occurrences.delete(txn);
      await _templates.delete(txn);
      await _proposals.delete(txn);
      await _milestones.delete(txn);
      await _weightEntries.delete(txn);
      await _achievements.delete(txn);
      await _settings.delete(txn);
      await _meta.delete(txn);

      Future<void> restoreList(
        StoreRef<String, Map<String, Object?>> store,
        Object? rows,
        String idField,
      ) async {
        for (final row in (rows as List? ?? const [])) {
          final map = (row as Map).cast<String, Object?>();
          await store.record(map[idField] as String).put(txn, map);
        }
      }

      await restoreList(_categories, data['categories'], 'id');
      await restoreList(_definitions, data['task_definitions'], 'id');
      await restoreList(_occurrences, data['occurrences'], 'id');
      await restoreList(_templates, data['week_templates'], 'id');
      await restoreList(_proposals, data['proposals'], 'id');
      await restoreList(_milestones, data['milestones'], 'id');
      await restoreList(_weightEntries, data['weight_entries'], 'id');

      for (final entry
          in (data['achievement_unlocks'] as Map? ?? const {}).entries) {
        await _achievements
            .record(entry.key as String)
            .put(txn, (entry.value as Map).cast<String, Object?>());
      }
      for (final entry in (data['settings'] as Map? ?? const {}).entries) {
        await _settings.record(entry.key as String).put(txn, entry.value);
      }
      for (final entry in (data['meta'] as Map? ?? const {}).entries) {
        await _meta.record(entry.key as String).put(txn, entry.value);
      }
    });
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.transaction((txn) async {
      await _categories.delete(txn);
      await _definitions.delete(txn);
      await _occurrences.delete(txn);
      await _templates.delete(txn);
      await _proposals.delete(txn);
      await _milestones.delete(txn);
      await _weightEntries.delete(txn);
      await _achievements.delete(txn);
      await _settings.delete(txn);
      await _meta.delete(txn);
    });
  }
}
