import 'dart:io'; // Still needed for File type in state and callback
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // No longer needed here
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

// Import the new widget
import 'package:barnbok/features/menu_screens/profile_image_selector.dart';

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

  // --- REMOVED image picker state/logic ---
  // File? _selectedImageFile;         // REMOVED
  // final ImagePicker _picker = ImagePicker(); // REMOVED

  // --- ADDED state variable to hold the file passed back from the selector ---
  File? _finalSelectedImageFile;

  // Keep placeholder path accessible for submitForm default
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

  // --- REMOVED _pickImage method ---
  // Future<void> _pickImage() async { ... } // REMOVED

  Future<void> _submitForm() async {
    if (!_repoInitialized || _isSaving) return;

    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      try {
        final String surname = _surnameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String uniqueId = const Uuid().v4();

        String imagePathToSave = fakeImagePath; // Use the constant defined here
        // --- UPDATED to use the state variable holding the callback result ---
        if (_finalSelectedImageFile != null) {
          imagePathToSave = _finalSelectedImageFile!.path;
        }
        // --- End determining image path ---

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
        // ... (rest of print statements - no changes)
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
    // --- REMOVED imagePlaceholder definition ---
    // Widget imagePlaceholder = Container(...); // REMOVED

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
                 // ... (rest of TextFormField - no changes)
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
                // ... (rest of TextFormField - no changes)
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

              // --- REPLACED Row with the new ProfileImageSelector widget ---
              ProfileImageSelector(
                placeholderImagePath: fakeImagePath, // Pass the placeholder path
                isDisabled: _isSaving, // Pass the disabled state
                onImageSelected: (File? selectedImage) {
                  // Update the dialog's state variable when the selector provides a file
                  setState(() {
                    _finalSelectedImageFile = selectedImage;
                  });
                  print("CreateStoryDialog: Received image update: ${_finalSelectedImageFile?.path}");
                },
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