import 'package:flutter/material.dart';
import 'core/shared/services/error_handler.dart';
import 'core/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handling
  ErrorHandler.initialize();

  // Launch the app
  runApp(const MyApp());
}