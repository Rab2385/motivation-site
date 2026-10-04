import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native implementation: writes into Downloads (or app documents).
Future<String> saveBackupFile(String fileName, String contents) async {
  Directory? dir;
  try {
    dir = await getDownloadsDirectory();
  } on UnsupportedError {
    dir = null;
  }
  dir ??= await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsString(contents, flush: true);
  return file.path;
}

Future<bool?> isStoragePersistent() async => null;

Future<bool?> requestPersistentStorage() async => null;
