// lib/features/menu_screens/widgets/create_story_dialog.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Import UUID
import 'package:hive/hive.dart'; // Import Hive

// Adjust paths as needed
import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';


/// Shows a dialog to enter first name (surname) and last name for a new story.
/// Saves the new story card data directly if confirmed.
///
/// Takes the `positionIndex` for the new card as an argument.
/// Returns `true` if the story was successfully created and saved, otherwise `false` or `null`.
Future<bool?> showCreateStoryDialog(BuildContext context, int positionIndex) async {
  // Show the dialog which now contains a StatefulWidget
  final result = await showDialog<bool?>( // Return type changed to bool?
    context: context,
    barrierDismissible: false, // User must tap button to close
    builder: (BuildContext dialogContext) {
      // Pass the positionIndex to the stateful widget
      return _CreateStoryDialogContent(positionIndex: positionIndex);
    },
  );
  return result;
}

// --- StatefulWidget for Dialog Content ---
// This manages the controllers, accepts positionIndex, and handles saving.
class _CreateStoryDialogContent extends StatefulWidget {
  final int positionIndex; // Accept the position index

  const _CreateStoryDialogContent({required this.positionIndex});

  @override
  State<_CreateStoryDialogContent> createState() => _CreateStoryDialogContentState();
}

class _CreateStoryDialogContentState extends State<_CreateStoryDialogContent> {
  // Keys and controllers are now part of the state
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _surnameController;
  late final TextEditingController _lastNameController;
  bool _isSaving = false; // State to track saving process

  // --- NOTE: Accessing the repository ---
  // Still using manual access here for consistency. DI is preferred.
  late final CardDataRepository _repository;
  bool _repoInitialized = false;
  // --- End Note ---


  @override
  void initState() {
    super.initState();
    // Initialize controllers here
    _surnameController = TextEditingController();
    _lastNameController = TextEditingController();
    // Initialize repository (could fail if box isn't open)
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
     try {
       if (!Hive.isBoxOpen(HiveCardDataRepository.boxName)) {
          print("CreateStoryDialog: Warning - Box was not open. Ensure it's opened in main.dart.");
          // Attempting to open here might cause issues if main hasn't finished.
          // Relying on main.dart having opened it successfully.
          _repoInitialized = false;
          return;
       }
       final cardInfoBox = Hive.box<CardInfo>(HiveCardDataRepository.boxName);
       _repository = HiveCardDataRepository(cardInfoBox);
       _repoInitialized = true;
       print("CreateStoryDialog: Repository initialized.");
     } catch (e) {
        print("CreateStoryDialog: Error initializing repository: $e");
       _repoInitialized = false;
     }
  }


  @override
  void dispose() {
    // Dispose controllers when this state object is removed
    _surnameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // --- Updated submit form to handle saving ---
  Future<void> _submitForm() async {
    // Prevent saving if repo isn't ready or already saving
    if (!_repoInitialized || _isSaving) return;

    // Validate the form
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; }); // Indicate saving process

      try {
        final String surname = _surnameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String uniqueId = const Uuid().v4(); // Generate UUID
        // Define a placeholder image path for new cards
        const String fakeImagePath = 'assets/images/placeholder_user.png';

        // Create the CardInfo object
        final newCardData = CardInfo(
          uniqueId: uniqueId,
          surname: surname,
          lastName: lastName,
          imagePath: fakeImagePath, // Use placeholder path
          positionIndex: widget.positionIndex, // Use index passed to widget
        );

        print('CreateStoryDialog: Attempting to save...');
        // Save using the repository
        await _repository.saveCardInfo(newCardData);

        print('--- SAVE SUCCESS ---');
        print('Saved Card Info:');
        print('  UUID: ${newCardData.uniqueId}');
        print('  Surname: ${newCardData.surname}');
        print('  Last Name: ${newCardData.lastName}');
        print('  Image Path: ${newCardData.imagePath}');
        print('  Position Index: ${newCardData.positionIndex}');
        print('--------------------');

        // If save is successful, pop the dialog and return true
        if (mounted) {
           Navigator.of(context).pop(true); // Return true on success
        }

      } catch (e, stackTrace) {
        print('CreateStoryDialog: Error saving card data: $e\n$stackTrace');
        // TODO: Show an error message to the user within the dialog?
        if (mounted) {
           setState(() { _isSaving = false; }); // Reset saving state on error
        }
        // Optionally pop with false or show error and stay open
        // Navigator.of(context).pop(false);
      }
      // No finally needed here as pop happens on success/error handling needed

    }
  }
  // --- End submit form ---

  @override
  Widget build(BuildContext context) {
    // Build the AlertDialog structure
    return AlertDialog(
      title: const Text('Create New Story'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for scroll view
            children: <Widget>[
              TextFormField(
                controller: _surnameController,
                enabled: !_isSaving, // Disable field while saving
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                enabled: !_isSaving, // Disable field while saving
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      actions: <Widget>[
        // Show Cancel button only if not saving
        if (!_isSaving)
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(null); // Close and return null
            },
          ),
        // Show progress indicator or button
        ElevatedButton(
          // Disable button while saving or if repo failed init
          onPressed: (_isSaving || !_repoInitialized) ? null : _submitForm,
          child: _isSaving
              ? const SizedBox( // Show progress indicator
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create My Story'),
        ),
      ],
    );
  }
}
