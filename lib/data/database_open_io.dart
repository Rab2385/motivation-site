import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Native (Windows, desktop, mobile) implementation: a single database file
/// in the application documents directory.
Future<Database> openPlatformDatabase(String databaseName) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final databasePath = p.join(documentsDir.path, databaseName);
  return databaseFactoryIo.openDatabase(databasePath, version: 1);
}
