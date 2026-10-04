import 'backup_file_io.dart'
    if (dart.library.js_interop) 'backup_file_web.dart' as platform;

/// Saves backup [contents] as [fileName] and returns a short description of
/// where it went (shown to the user).
typedef BackupFileSaver =
    Future<String> Function(String fileName, String contents);

/// Web: triggers a browser download. Native: writes into the Downloads
/// folder (or the app documents folder when there is none).
Future<String> saveBackupFile(String fileName, String contents) =>
    platform.saveBackupFile(fileName, contents);

/// Whether the browser has granted persistent storage, so it won't evict the
/// IndexedDB data under storage pressure. Null where it doesn't apply
/// (native builds keep the data in a file).
Future<bool?> isStoragePersistent() => platform.isStoragePersistent();

/// Asks the browser for persistent storage; returns the resulting state, or
/// null where it doesn't apply.
Future<bool?> requestPersistentStorage() =>
    platform.requestPersistentStorage();
