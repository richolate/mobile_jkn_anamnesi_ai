// Conditional export for database implementation
export 'database_helper_stub.dart'
    if (dart.library.io) 'database_helper.dart'
    if (dart.library.html) 'database_helper_web.dart';
