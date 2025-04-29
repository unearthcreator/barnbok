import 'package:flutter/material.dart';
import 'package:barnbok/features/menu_screens/welcome_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomeScreen(), // updated to new WelcomeScreen
    );
  }
}