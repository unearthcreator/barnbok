// lib/features/menu_screens/widgets/create_story_dialog.dart

import 'dart:io'; // Import for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

// Adjust paths as needed
import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';

// --- showCreateStoryDialog function remains the same ---
Future<bool?> showCreateStoryDialog(BuildContext context, int positionIndex) async {
  final result = await showDialog<bool?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _CreateStoryDialogContent(positionIndex: positionIndex);
    },
  );
  return result;
}


class _CreateStoryDialogContent extends StatefulWidget {
  final int positionIndex;
  const _CreateStoryDialogContent({required this.positionIndex, super.key}); // Added key

  @override
  State<_CreateStoryDialogContent> createState() => _CreateStoryDialogContentState();
}

class _CreateStoryDialogContentState extends State<_CreateStoryDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _surnameController;
  late final TextEditingController _lastNameController;
  bool _isSaving = false;
  late final CardDataRepository _repository;
  bool _repoInitialized = false;

  // --- NEW STATE VARIABLE for selected image ---
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker

  // Placeholder path (remains useful)
  static const String fakeImagePath = 'assets/images/baby_foot_ceramic.jpg';


  @override
  void initState() {
    super.initState();
    _surnameController = TextEditingController();
    _lastNameController = TextEditingController();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    // ... (repository initialization logic remains the same)
    try {
      if (!Hive.isBoxOpen(HiveCardDataRepository.boxName)) {
        print("CreateStoryDialog: Warning - Box was not open.");
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
    // Trigger a rebuild if initialization state changes after frame build
    if (mounted) {
        setState(() {});
    }
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // --- NEW METHOD: Pick Image ---
  Future<void> _pickImage() async {
    // Ensure user isn't saving while picking
    if (_isSaving) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Or ImageSource.camera
        // Optional: Add constraints like imageQuality or maxWidth/maxHeight
        // imageQuality: 80,
        // maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          print("Image selected: ${pickedFile.path}");
        });
      } else {
        // User canceled the picker
        print("Image selection cancelled.");
      }
    } catch (e) {
      // Handle potential errors (e.g., permissions denied)
      print("Error picking image: $e");
      // Optionally show a snackbar or alert to the user
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kunde inte välja bild. Kontrollera behörigheter.')) // Could not pick image. Check permissions.
          );
      }
    }
  }
  // --- End Pick Image Method ---


  // --- UPDATED submit form ---
  Future<void> _submitForm() async {
    if (!_repoInitialized || _isSaving) return;

    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      try {
        final String surname = _surnameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String uniqueId = const Uuid().v4();

        // --- Determine image path to save ---
        String imagePathToSave = fakeImagePath; // Default to placeholder
        if (_selectedImageFile != null) {
          // IMPORTANT: Using the direct path from the picker might point to a
          // temporary file. For long-term storage, you should ideally COPY
          // the file to your app's private directory (e.g., using path_provider)
          // and save THAT path. For simplicity now, we save the picker's path.
          imagePathToSave = _selectedImageFile!.path;
        }
        // --- End determining image path ---

        final newCardData = CardInfo(
          uniqueId: uniqueId,
          surname: surname,
          lastName: lastName.isEmpty ? null : lastName,
          imagePath: imagePathToSave, // Use the determined path
          positionIndex: widget.positionIndex,
        );

        print('CreateStoryDialog: Attempting to save...');
        await _repository.saveCardInfo(newCardData);

        print('--- SAVE SUCCESS ---');
        print('Saved Card Info:');
        print('  UUID: ${newCardData.uniqueId}');
        print('  Surname: ${newCardData.surname}');
        print('  Last Name: ${newCardData.lastName ?? 'N/A'}');
        print('  Image Path: ${newCardData.imagePath}'); // Will show selected path or placeholder
        print('  Position Index: ${newCardData.positionIndex}');
        print('--------------------');

        if (mounted) {
          Navigator.of(context).pop(true);
        }

      } catch (e, stackTrace) {
        print('CreateStoryDialog: Error saving card data: $e\n$stackTrace');
        if (mounted) {
          setState(() { _isSaving = false; });
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kunde inte spara berättelsen.')) // Could not save story.
          );
        }
      }
    }
  }
  // --- End submit form ---

  @override
  Widget build(BuildContext context) {
    // Define placeholder widget separately for clarity
    Widget imagePlaceholder = Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8), // Rounded corners
            image: const DecorationImage(
                image: AssetImage(fakeImagePath), // Show placeholder inside
                fit: BoxFit.cover)),
        // child: Icon(Icons.person, size: 40, color: Colors.grey[400]), // Alternative: show icon
        );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      // Increased vertical padding slightly to accommodate image picker
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 10.0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              // --- First Name (No changes) ---
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Förnamn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              ),
              TextFormField(
                controller: _surnameController,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  hintText: '(Obligatoriskt)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Obligatorisk';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Last Name (No changes) ---
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Efternamn (valfritt)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              ),
              TextFormField(
                controller: _lastNameController,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  hintText: '(valfritt)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20), // Increased spacing before image picker


              // --- NEW: Image Picker Section ---
              Text(
                  'Profilbild (valfritt)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
                children: [
                  // Image Preview Area
                  Container(
                    width: 80, // Set fixed size for preview
                    height: 80,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8), // Match placeholder
                    ),
                    child: _selectedImageFile != null
                        ? ClipRRect( // Clip image to rounded corners
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                _selectedImageFile!,
                                fit: BoxFit.cover, // Cover the area
                                width: 80,
                                height: 80,
                                errorBuilder: (context, error, stackTrace) {
                                    // Show placeholder if image file fails to load
                                    print("Error loading image file: $error");
                                    return imagePlaceholder;
                                },
                                ),
                            )
                        : imagePlaceholder, // Show placeholder if no image selected
                    ),

                  const SizedBox(width: 16), // Spacing between preview and button

                  // Choose Image Button
                  Expanded( // Allow button to take remaining space if needed (optional)
                    child: ElevatedButton.icon(
                       // Changed to icon button for better look
                      onPressed: _isSaving ? null : _pickImage, // Disable while saving
                      icon: const Icon(Icons.image_search),
                      label: Text(_selectedImageFile == null ? 'Välj bild' : 'Ändra bild'), // Choose / Change Image
                      style: ElevatedButton.styleFrom(
                         // Add some style if desired
                      ),
                    ),
                  ),
                ],
              ),
              // --- End Image Picker Section ---

            ],
          ),
        ),
      ),
      // Actions Padding adjusted if needed
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
      actions: <Widget>[
        if (!_isSaving)
          TextButton(
            child: const Text('Avbryt'),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
        ElevatedButton(
          // Disable button if repo not ready OR if saving
          onPressed: (_isSaving || !_repoInitialized) ? null : _submitForm,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Skapa min berättelse'),
        ),
      ],
    );
  }
}