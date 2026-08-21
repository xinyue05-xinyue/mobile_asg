import 'package:flutter/material.dart';

import 'app/theme/app_theme.dart';
import 'data/remote/supabase_service.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MyDarahApp());
}

class MyDarahApp extends StatelessWidget {
  const MyDarahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDarah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
