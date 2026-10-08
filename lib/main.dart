import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalDatabase.instance.database;

  runApp(const PosMateApp());
}
