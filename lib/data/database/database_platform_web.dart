import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

bool _configured = false;

void configureDatabasePlatform() {
  if (_configured) {
    return;
  }

  databaseFactory = databaseFactoryFfiWeb;
  _configured = true;
}

Future<String> resolvePosMateDatabasePath() async {
  // Web에서는 SQLite 데이터가 브라우저의 IndexedDB 기반 저장소에 보관된다.
  return 'pos_mate_web.db';
}
