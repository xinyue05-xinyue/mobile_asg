import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyDarahApp());
}

class MyDarahApp extends StatelessWidget {
  const MyDarahApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDarah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}


