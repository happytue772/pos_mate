import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/pos_provider.dart';

class PosMateApp extends StatelessWidget {
  const PosMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
      ],
      child: MaterialApp(
        title: 'POS Mate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LoginPage(),
      ),
    );
  }
}
