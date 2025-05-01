import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Still need hive_flutter

// Import your project files (!!! ADJUST PATHS AS NEEDED !!!)
import 'core/shared/services/error_handler.dart';
import 'core/app.dart';
import 'models/card_info.dart';                      // Import the model
// Import the concrete repository & boxName.
import 'repositories/hive_card_data_repository.dart';

// main function needs to be asynchronous
Future<void> main() async {
  // Ensure Flutter framework is ready
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter Widgets Initialized.');

  // --- Outer Try/Catch for overall setup ---
  try {
    // ---- Hive Initialization (Required) ----
    print('Initializing Hive...');
    await Hive.initFlutter();
    print('Hive Initialized.');

    print('Registering CardInfoAdapter...');
    // Ensure CardInfoAdapter is registered so Hive knows how to handle CardInfo
    Hive.registerAdapter(CardInfoAdapter());
    print('CardInfoAdapter Registered.');

    print('Opening Hive Box: "${HiveCardDataRepository.boxName}"...');
    // Open the box where CardInfo objects will be stored
    await Hive.openBox<CardInfo>(HiveCardDataRepository.boxName);
    print('Hive Box "${HiveCardDataRepository.boxName}" opened successfully.');
    // ---- End Hive Initialization ----

    // --- Dependency Injection Setup would go here if you add it later ---
    // Example: setupLocator();

  } catch (e, stackTrace) {
     // Catch errors during critical Hive setup
     print('FATAL ERROR during app initialization: $e\n$stackTrace');
     // Optionally log using your handler
     // ErrorHandler.logError('App Initialization Failed', e, stackTrace);
     // Decide how to handle critical failure
  }

  // Initialize global error handling (Your existing code)
  ErrorHandler.initialize();
  print('Global Error Handler Initialized.');

  // Launch the app (Your existing code)
  print('Running the App...');
  runApp(const MyApp());
}
