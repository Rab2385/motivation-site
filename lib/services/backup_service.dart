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

  Future<String> exportJson() async {
    final data = await _db.exportData();
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
      throw BackupFormatException('Datei ist kein gültiges JSON: ${error.message}');
    }
    if (decoded is! Map) {
      throw const BackupFormatException('Backup-Datei hat das falsche Format.');
    }
    final version = decoded['formatVersion'];
    if (version is! int) {
      throw const BackupFormatException('Versionsangabe fehlt.');
    }
    if (version > formatVersion) {
      throw BackupFormatException(
        'Backup wurde mit einer neueren App-Version erstellt (Format $version).',
      );
    }
    final data = decoded['data'];
    if (data is! Map) {
      throw const BackupFormatException('Backup enthält keine Daten.');
    }
    return decoded.cast<String, Object?>();
  }

  /// Imports a validated envelope. Writes the current data to
  /// `settings['__safetyBackup']` first.
  Future<void> importValidated(Map<String, Object?> envelope) async {
    final current = await _db.exportData();
    await _db.saveSetting('__safetyBackup', jsonEncode({
      'createdAt': DateTime.now().toIso8601String(),
      'data': current,
    }));
    await _db.replaceAll((envelope['data'] as Map).cast<String, Object?>());
  }
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}
