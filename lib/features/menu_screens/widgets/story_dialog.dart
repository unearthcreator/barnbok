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

// --- showCreateStoryDialog function (no changes) ---
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
  const _CreateStoryDialogContent({required this.positionIndex, super.key});

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

  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  static const String fakeImagePath = 'assets/images/baby_foot_ceramic.jpg';

  @override
  void initState() {
    super.initState();
    _surnameController = TextEditingController();
    _lastNameController = TextEditingController();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    // ... (repository initialization logic - no changes)
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

  Future<void> _pickImage() async {
    // ... (_pickImage method - no changes)
    if (_isSaving) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        // imageQuality: 80,
        // maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          print("Image selected: ${pickedFile.path}");
        });
      } else {
        print("Image selection cancelled.");
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunde inte välja bild. Kontrollera behörigheter.'))
          );
      }
    }
  }


  Future<void> _submitForm() async {
   // ... (_submitForm method - no changes)
   if (!_repoInitialized || _isSaving) return;

    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      try {
        final String surname = _surnameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String uniqueId = const Uuid().v4();

        String imagePathToSave = fakeImagePath;
        if (_selectedImageFile != null) {
          // Consider copying file for persistence later
          imagePathToSave = _selectedImageFile!.path;
        }

        final newCardData = CardInfo(
          uniqueId: uniqueId,
          surname: surname,
          lastName: lastName.isEmpty ? null : lastName,
          imagePath: imagePathToSave,
          positionIndex: widget.positionIndex,
        );

        print('CreateStoryDialog: Attempting to save...');
        await _repository.saveCardInfo(newCardData);

        print('--- SAVE SUCCESS ---');
        print('Saved Card Info:');
        print('  UUID: ${newCardData.uniqueId}');
        print('  Surname: ${newCardData.surname}');
        print('  Last Name: ${newCardData.lastName ?? 'N/A'}');
        print('  Image Path: ${newCardData.imagePath}');
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
              const SnackBar(content: Text('Kunde inte spara berättelsen.'))
            );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define placeholder widget with correct styling
    Widget imagePlaceholder = Container(
        width: 75,
        height: 100,
        decoration: BoxDecoration(
            // No background color
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
                image: AssetImage(fakeImagePath),
                fit: BoxFit.contain, // Use contain
            )
        ),
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
              const SizedBox(height: 20),


              // --- Image Picker Section ---
              Text(
                  'Profilbild (valfritt)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // --- WRAPPED Image Preview Area with InkWell ---
                  InkWell(
                    // Call _pickImage on tap, disable if saving
                    onTap: _isSaving ? null : _pickImage,
                    // Apply border radius to InkWell ripple effect
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 75, // Portrait size
                      height: 100,
                      decoration: BoxDecoration(
                        // No border or background color here
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect( // Clip the image content
                        borderRadius: BorderRadius.circular(8.0),
                        child: _selectedImageFile != null
                            ? Image.file(
                                _selectedImageFile!,
                                fit: BoxFit.contain, // Use contain
                                width: 75,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading image file: $error");
                                  return imagePlaceholder;
                                },
                              )
                            : imagePlaceholder, // Show placeholder
                      ),
                    ),
                  ),
                  // --- End WRAPPED Image Preview Area ---

                  const SizedBox(width: 16), // Spacing

                  // Choose Image Button (remains the same)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _pickImage,
                      icon: const Icon(Icons.image_search),
                      label: Text(_selectedImageFile == null ? 'Välj bild' : 'Ändra bild'),
                    ),
                  ),
                ],
              ),
              // --- End Image Picker Section ---

            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
      actions: <Widget>[
        // ... (Actions - no changes) ...
        if (!_isSaving)
          TextButton(
            child: const Text('Avbryt'),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
        ElevatedButton(
          onPressed: (_isSaving || !_repoInitialized) ? null : _submitForm,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Skapa min berättelse'),
        ),
      ],
    );
  }
}