import 'dart:convert';

import '../data/motivation_database.dart';

/// Versioned JSON backup of the whole database.
///
/// Local storage (IndexedDB) can be wiped by the browser, so the user should
/// export regularly. Import validates the envelope, keeps a safety copy of the
/// current data, then replaces everything in one transaction.
class BackupService {
  BackupService(this._db);

  final MotivationDatabase _db;

  static const int formatVersion = 1;
  static const String _appVersion = '0.1.0';

  /// Settings that never travel in a backup file: the passcode and recovery
  /// code left behind by the removed lock screen (stored in plain text by
  /// older versions), the import safety copy (which would otherwise nest a
  /// full older backup inside every export), and this device's backup
  /// bookkeeping.
  static const Set<String> localOnlySettings = {
    'appPasscode',
    'appRecoveryCode',
    '__safetyBackup',
    ..._keptOnImport,
  };

  /// Local-only settings whose current value survives an import, so an old
  /// backup can't make the app think it was backed up back then.
  static const Set<String> _keptOnImport = {
    'lastBackupAt',
    'backupSnoozedUntil',
  };

  Future<String> exportJson() async {
    final data = await _db.exportData();
    final settings = data['settings'];
    if (settings is Map) {
      data['settings'] = {
        for (final entry in settings.entries)
          if (!localOnlySettings.contains(entry.key)) entry.key: entry.value,
      };
    }
    final envelope = {
      'formatVersion': formatVersion,
      'appVersion': _appVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Parses and validates [raw]; throws [BackupFormatException] on anything
  /// unexpected. Does not touch the database.
  Map<String, Object?> parseAndValidate(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw BackupFormatException('Not valid JSON: ${error.message}');
    }
    if (decoded is! Map) {
      throw const BackupFormatException('Backup file has the wrong shape.');
    }
    final version = decoded['formatVersion'];
    if (version is! int) {
      throw const BackupFormatException('Missing format version.');
    }
    if (version > formatVersion) {
      throw BackupFormatException(
        'This backup was made with a newer app version (format $version).',
      );
    }
    final data = decoded['data'];
    if (data is! Map) {
      throw const BackupFormatException('Backup contains no data.');
    }
    return decoded.cast<String, Object?>();
  }

  /// Imports a validated envelope. Writes the current data to
  /// `settings['__safetyBackup']` first.
  Future<void> importValidated(Map<String, Object?> envelope) async {
    final current = await _db.exportData();
    final currentSettings =
        (current['settings'] as Map?)?.cast<String, Object?>() ?? const {};
    final safetyBackup = jsonEncode({
      'createdAt': DateTime.now().toIso8601String(),
      'data': current,
    });
    await _db.saveSetting('__safetyBackup', safetyBackup);

    final data = Map<String, Object?>.of(
      (envelope['data'] as Map).cast<String, Object?>(),
    );
    final settings = Map<String, Object?>.of(
      (data['settings'] as Map?)?.cast<String, Object?>() ?? const {},
    );
    settings.removeWhere((key, _) => localOnlySettings.contains(key));
    for (final key in _keptOnImport) {
      final keep = currentSettings[key];
      if (keep != null) settings[key] = keep;
    }
    settings['__safetyBackup'] = safetyBackup;
    data['settings'] = settings;
    await _db.replaceAll(data);
  }
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}
