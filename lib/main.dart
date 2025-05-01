import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Still need hive_flutter

// Import your project files (!!! ADJUST PATHS AS NEEDED !!!)
import 'core/shared/services/error_handler.dart';
import 'core/app.dart';
import 'models/card_info.dart';                      // Import the model
// Import the concrete repository & boxName. Abstract repo not needed for this test.
import 'repositories/hive_card_data_repository.dart';

// main function needs to be asynchronous
Future<void> main() async {
  // Ensure Flutter framework is ready
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter Widgets Initialized.');

  // --- Outer Try/Catch for overall setup ---
  try {
    // ---- Hive Initialization (Still Required) ----
    print('Initializing Hive...');
    await Hive.initFlutter();
    print('Hive Initialized.');

    print('Registering CardInfoAdapter...');
    Hive.registerAdapter(CardInfoAdapter());
    print('CardInfoAdapter Registered.');

    print('Opening Hive Box: "${HiveCardDataRepository.boxName}"...');
    await Hive.openBox<CardInfo>(HiveCardDataRepository.boxName); // Open the box
    print('Hive Box "${HiveCardDataRepository.boxName}" opened successfully.');
    // ---- End Hive Initialization ----


    // ---- Temporary Hive Test (Manual Instantiation - NO GetIt) ----
    print('--- Running Temporary Hive Test (Manual Instantiation) ---');
    try {
      // 1. Manually get the opened Hive Box instance directly from Hive
      final cardInfoBox = Hive.box<CardInfo>(HiveCardDataRepository.boxName);
      print('Test: Got Hive box instance manually.');

      // 2. Manually create an instance of the CONCRETE repository
      //    Pass the box instance directly into the constructor.
      final repository = HiveCardDataRepository(cardInfoBox);
      print('Test: Created repository instance manually.');

      // 3. Create some dummy data
      final testData = CardInfo(
        surname: 'Manual',
        lastName: 'Test-${DateTime.now().millisecond}', // Changing data
        imagePath: '/path/to/manual_test.jpg',
      );
      const testIndex = 77; // Use another distinct index

      print('Test: Attempting to save: $testData at index $testIndex');
      // 4. Save the data using the manually created repository instance
      await repository.saveCardInfo(testIndex, testData);
      print('Test: Save operation completed.');

      print('Test: Attempting to retrieve data at index $testIndex');
      // 5. Retrieve the data using the same repository instance
      final retrievedData = await repository.getCardInfo(testIndex);
      print('Test: Retrieve operation completed.');

      // 6. Verify and Print
      if (retrievedData != null) {
        print('Test: Successfully retrieved: $retrievedData');
        if (retrievedData.surname == testData.surname && retrievedData.lastName == testData.lastName) {
          print('Test SUCCESS: Retrieved data matches saved data!');
        } else {
          print('Test ERROR: Retrieved data does NOT match saved data!');
          print('Expected: $testData');
          print('Got:      $retrievedData');
        }
      } else {
        print('Test ERROR: Failed to retrieve data, got null!');
      }
    } catch (e, stackTrace) {
      // Catch errors specific to the test itself
      print('ERROR during Hive test execution: $e\n$stackTrace');
      // Optionally log using your handler
      // ErrorHandler.logError('Hive Manual Test Failed', e, stackTrace);
    }
    print('--- End Temporary Hive Test ---');
    // ---- End Temporary Hive Test ----

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