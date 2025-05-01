// lib/features/menu_screens/story_selector_screen.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // Import Hive

// Adjust paths as needed
import 'package:barnbok/features/menu_screens/widgets/story_carousel.dart';
import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';


// Convert to StatefulWidget to perform actions in initState
class StorySelectorScreen extends StatefulWidget {
  const StorySelectorScreen({super.key});

  @override
  State<StorySelectorScreen> createState() => _StorySelectorScreenState();
}

class _StorySelectorScreenState extends State<StorySelectorScreen> {

  @override
  void initState() {
    super.initState();
    // Call the logging function when the widget is first initialized
    _logSavedCardInfo();
  }

  // --- Function to fetch and log saved card info ---
  Future<void> _logSavedCardInfo() async {
    print("StorySelectorScreen: Attempting to log saved card info...");
    try {
      // --- Manually get repository instance (See note in StoryCarousel) ---
      // Ensure the box is open before accessing
       if (!Hive.isBoxOpen(HiveCardDataRepository.boxName)) {
          print("StorySelectorScreen: Warning - Box was not open. Cannot log info.");
          return; // Exit if box isn't open
       }
       final cardInfoBox = Hive.box<CardInfo>(HiveCardDataRepository.boxName);
       // Check if the box is actually open before creating the repository
       if (!cardInfoBox.isOpen) {
         print("StorySelectorScreen: Error - Box is not open despite Hive.isBoxOpen being true?");
         return;
       }
       final CardDataRepository repository = HiveCardDataRepository(cardInfoBox);
       // --- End Manual Instance Creation ---

       // Fetch all cards
       final List<CardInfo> allCards = await repository.getAllCardsSortedByPosition();

       // Log the total count
       print("StorySelectorScreen: Found ${allCards.length} saved card(s) in the box.");

       // Log the position index for each card
       if (allCards.isNotEmpty) {
          print("StorySelectorScreen: Saved card positions:");
          for (final card in allCards) {
            // Log position index and maybe uniqueId for context
            print("  - Position Index: ${card.positionIndex} (ID: ${card.uniqueId})");
          }
       } else {
         print("StorySelectorScreen: No cards currently saved.");
       }

    } catch (e, stackTrace) {
       print("StorySelectorScreen: Error logging saved card info: $e\n$stackTrace");
       // Handle error appropriately
    }
  }
  // --- End logging function ---

  // --- Function to clear the Hive box ---
  Future<void> _clearHiveBox() async {
     print("StorySelectorScreen: Attempting to clear Hive box...");
     try {
        if (!Hive.isBoxOpen(HiveCardDataRepository.boxName)) {
          print("StorySelectorScreen: Warning - Box was not open. Cannot clear.");
          return; // Exit if box isn't open
       }
       final cardInfoBox = Hive.box<CardInfo>(HiveCardDataRepository.boxName);
       final int numberOfItems = cardInfoBox.length; // Get count before clearing
       await cardInfoBox.clear(); // Clear all entries in the box
       print("StorySelectorScreen: Hive box cleared. Removed $numberOfItems item(s).");

       // Optionally re-log to confirm it's empty
       await _logSavedCardInfo();

       // Optionally trigger a UI refresh if needed (e.g., if displaying saved data)
       // setState(() {});

     } catch (e, stackTrace) {
        print("StorySelectorScreen: Error clearing Hive box: $e\n$stackTrace");
        // Handle error appropriately (e.g., show a SnackBar)
     }
  }
  // --- End clear function ---


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          tooltip: 'Clear All Saved Cards (Debug)',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Clear'),
                content: const Text(
                    'Are you sure you want to delete ALL saved card data? This cannot be undone.'),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Clear All Data'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _clearHiveBox();
            }
          },
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            StoryCarousel(),
            SizedBox(height: 20),
        ],
      ),
  ),
),
  );
}
}