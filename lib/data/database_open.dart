import 'package:sembast/sembast.dart';

import 'database_open_io.dart'
    if (dart.library.js_interop) 'database_open_web.dart';

/// Opens the Sembast database for the current platform.
///
/// Web uses an IndexedDB-backed store; native platforms use a file in the
/// app documents directory. The rest of the app only sees [Database].
Future<Database> openMotivationDatabase(String databaseName) =>
    openPlatformDatabase(databaseName);
