import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void configureDatabasePlatform() {
  // Android / iOS / macOS에서는 기본 sqflite factory를 그대로 사용한다.
}

Future<String> resolvePosMateDatabasePath() async {
  final databasePath = await getDatabasesPath();
  return join(databasePath, 'pos_mate.db');
}
