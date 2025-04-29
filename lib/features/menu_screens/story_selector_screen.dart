// lib/features/menu_screens/story_selector_screen.dart

import 'package:flutter/material.dart';

// Import the new carousel widget
// Replace 'barnbok' with your actual project name if different
import 'package:barnbok/features/menu_screens/widgets/story_carousel.dart';


class StorySelectorScreen extends StatelessWidget {
  const StorySelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      // --- MODIFIED BODY ---
      // Replace the simple Text widget with the StoryCarousel
      body: Column( // Wrap in a Column for potential future additions
         mainAxisAlignment: MainAxisAlignment.center, // Center vertically
         children: [
            // You could add text or other widgets above/below the carousel here
             StoryCarousel(), // Add the carousel widget instance
             // Example: Add some space below
             const SizedBox(height: 20),
         ],
       )
      // --- END MODIFIED BODY ---
    );
  }
}