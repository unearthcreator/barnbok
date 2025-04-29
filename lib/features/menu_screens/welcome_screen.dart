// lib/features/menu_screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator

// Import kIsWeb constant to check if running on the web
import 'package:flutter/foundation.dart' show kIsWeb;

// Import the story selector screen
// Replace 'barnbok' with your actual project name if different
import 'package:barnbok/features/menu_screens/story_selector_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welcome to your story',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                // --- NAVIGATION CODE ---
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StorySelectorScreen()),
                );
                // --- END NAVIGATION CODE ---
              },
              child: const Text('Go to stories'),
            ),

            // --- CONDITIONALLY INCLUDE Exit Button and Spacer ---
            // Use a collection 'if' to only include these widgets if NOT on web (!kIsWeb)
            // We group the SizedBox and ElevatedButton using `...[]` (spread operator on a list)
            // so they are added/removed together under the same condition.
            if (!kIsWeb) ...[
              const SizedBox(height: 20), // Spacer before the button
              ElevatedButton(
                // No need for kIsWeb check inside onPressed anymore,
                // because this button won't even be built on web.
                onPressed: () {
                   SystemNavigator.pop();
                },
                child: const Text('Exit'),
              ),
            ]
            // --- END CONDITIONAL SECTION ---

          ],
        ),
      ),
    );
  }
}