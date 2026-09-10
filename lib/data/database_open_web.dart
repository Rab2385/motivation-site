import 'package:sembast_web/sembast_web.dart';

/// Web implementation: an IndexedDB-backed store keyed by [databaseName].
Future<Database> openPlatformDatabase(String databaseName) =>
    databaseFactoryWeb.openDatabase(databaseName, version: 1);
