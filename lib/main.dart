// main.dart - TEMPORARY VERSION TO CLEAR BOX

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import your project files (!!! ADJUST PATHS AS NEEDED !!!)
import 'core/shared/services/error_handler.dart';
import 'core/app.dart';
import 'models/card_info.dart';
import 'repositories/hive_card_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter Widgets Initialized.');

  try {
    print('Initializing Hive...');
    await Hive.initFlutter();
    print('Hive Initialized.');

    // --- END TEMPORARY ---

    print('Registering CardInfoAdapter...');
    Hive.registerAdapter(CardInfoAdapter());
    print('CardInfoAdapter Registered.');

    print('Opening Hive Box: "${HiveCardDataRepository.boxName}"...');
    await Hive.openBox<CardInfo>(HiveCardDataRepository.boxName); // Open the (now empty) box
    print('Hive Box "${HiveCardDataRepository.boxName}" opened successfully.');

  } catch (e, stackTrace) {
     print('FATAL ERROR during app initialization: $e\n$stackTrace');
     // ErrorHandler.logError('App Initialization Failed', e, stackTrace);
  }

  ErrorHandler.initialize();
  print('Global Error Handler Initialized.');

  print('Running the App...');
  runApp(const MyApp());
}