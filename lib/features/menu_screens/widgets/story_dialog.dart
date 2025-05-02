import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

// Import the selector widget
import 'package:barnbok/features/menu_screens/profile_image_selector.dart';

// Adjust paths as needed
import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';


// --- MODIFIED showCreateStoryDialog function ---
Future<bool?> showCreateStoryDialog(
  BuildContext context,
  int positionIndex, { // positionIndex still relevant for new cards
  CardInfo? existingCard, // Optional: Pass card data if editing
}) async {
  final result = await showDialog<bool?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Pass both index and optional existing card data
      return _CreateStoryDialogContent(
        positionIndex: positionIndex,
        existingCard: existingCard, // Pass it down
      );
    },
  );
  return result;
}


// --- MODIFIED StatefulWidget ---
class _CreateStoryDialogContent extends StatefulWidget {
  final int positionIndex;
  final CardInfo? existingCard; // Added optional existing card data

  const _CreateStoryDialogContent({
    required this.positionIndex,
    this.existingCard, // Added to constructor
    super.key,
  });

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

  // State variable to hold the file selected by ProfileImageSelector *during this session*
  File? _finalSelectedImageFile;

  // Placeholder path - still needed for default when creating
  static const String fakeImagePath = 'assets/images/baby_foot_ceramic.jpg';

  // Helper getter to easily check if we are editing
  bool get isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers - pre-fill if editing
    _surnameController = TextEditingController(text: widget.existingCard?.surname ?? '');
    _lastNameController = TextEditingController(text: widget.existingCard?.lastName ?? '');
    // Note: Initial image is handled by passing initialImagePath to ProfileImageSelector

    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    // ... (no changes needed here) ...
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


  // --- MODIFIED submit form ---
  Future<void> _submitForm() async {
    if (!_repoInitialized || _isSaving) return;

    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      try {
        // --- Determine details based on mode (Create vs Edit) ---
        final String surname = _surnameController.text.trim();
        final String lastName = _lastNameController.text.trim();

        // Use existing ID if editing, otherwise generate a new one
        final String uniqueId = widget.existingCard?.uniqueId ?? const Uuid().v4();

        // Use existing positionIndex if editing, otherwise use the one passed for new card
        final int positionIndex = widget.existingCard?.positionIndex ?? widget.positionIndex;

        // Determine image path: Start with existing or default, override only if a NEW file was selected
        String imagePathToSave = widget.existingCard?.imagePath ?? fakeImagePath;
        if (_finalSelectedImageFile != null) {
          // A new image was selected during this session, use its path
          imagePathToSave = _finalSelectedImageFile!.path;
        }
        // --- End determining details ---

        // Create the CardInfo object with determined details
        final cardDataToSave = CardInfo(
          uniqueId: uniqueId,
          surname: surname,
          lastName: lastName.isEmpty ? null : lastName, // Store null if empty
          imagePath: imagePathToSave,
          positionIndex: positionIndex,
          // Optional: Handle other fields like serverId if necessary for updates
          // serverId: widget.existingCard?.serverId,
        );

        print('CreateStoryDialog: Attempting to save (${isEditing ? "Edit" : "Create"})...');
        // Assuming repository handles create vs update based on uniqueId/key
        await _repository.saveCardInfo(cardDataToSave);

        print('--- SAVE SUCCESS (${isEditing ? "Edit" : "Create"}) ---');
        print('Saved Card Info:');
        print('  UUID: ${cardDataToSave.uniqueId}');
        print('  Surname: ${cardDataToSave.surname}');
        print('  Last Name: ${cardDataToSave.lastName ?? 'N/A'}');
        print('  Image Path: ${cardDataToSave.imagePath}');
        print('  Position Index: ${cardDataToSave.positionIndex}');
        print('--------------------');

        if (mounted) {
          Navigator.of(context).pop(true); // Return true on success
        }

      } catch (e, stackTrace) {
        print('CreateStoryDialog: Error saving card data: $e\n$stackTrace');
        if (mounted) {
          setState(() { _isSaving = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kunde inte ${isEditing ? "spara ändringar" : "skapa berättelsen"}.')) // Adjust msg
            );
        }
      }
    }
  }
  // --- End submit form ---

        // --- MODIFIED build method ---
      @override
      Widget build(BuildContext context) {
        // Define standard label style for reuse
        final labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]);
        // Define size for color circles
        const double circleDiameter = 30.0;

        return AlertDialog(
          title: Text(
            isEditing ? 'Redigera berättelse' : 'Skapa ny berättelse',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 10.0),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // Keep children aligned left
                children: <Widget>[
                  // --- First Name Field ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('Förnamn', style: labelStyle), // Use defined style
                  ),
                  TextFormField(
                    controller: _surnameController,
                    enabled: !_isSaving,
                    decoration: InputDecoration( /* ... */ ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) { /* ... */ },
                  ),
                  const SizedBox(height: 16),

                  // --- Last Name Field ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('Efternamn (valfritt)', style: labelStyle), // Use defined style
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    enabled: !_isSaving,
                    decoration: InputDecoration( /* ... */ ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),

                  // --- Image Picker Section ---
                  Text(
                      'Profilbild (valfritt)',
                      style: labelStyle, // Use defined style
                  ),
                  const SizedBox(height: 8),
                  ProfileImageSelector(
                    initialImagePath: widget.existingCard?.imagePath,
                    placeholderImagePath: fakeImagePath,
                    isDisabled: _isSaving,
                    onImageSelected: (File? selectedImage) {
                      setState(() { _finalSelectedImageFile = selectedImage; });
                      print("CreateStoryDialog: Received image update: ${_finalSelectedImageFile?.path}");
                    },
                  ),
                  // --- End Image Picker Section ---

                  // --- ADDED Theme Selection Section ---
                  const SizedBox(height: 20), // Spacing before Theme section
                  Text(
                    'Theme', // Or "Tema" for Swedish
                    style: labelStyle, // Use defined style
                  ),
                  const SizedBox(height: 8),
                  Row(
                    // You might want MainAxisAlignment.spaceAround or .spaceBetween
                    // if you want them to spread out more automatically.
                    // Using SizedBox provides fixed spacing.
                    children: [
                        // Light Blue Circle
                        Container(
                          width: circleDiameter,
                          height: circleDiameter,
                          decoration: const BoxDecoration(
                            color: Colors.lightBlueAccent, // Or Colors.lightBlue
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10), // Spacing between circles

                        // Pink Circle
                        Container(
                          width: circleDiameter,
                          height: circleDiameter,
                          decoration: const BoxDecoration(
                            color: Colors.pinkAccent, // Or Colors.pink
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Purple Circle
                        Container(
                          width: circleDiameter,
                          height: circleDiameter,
                          decoration: const BoxDecoration(
                            color: Colors.purpleAccent, // Or Colors.purple
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Red Circle
                        Container(
                          width: circleDiameter,
                          height: circleDiameter,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent, // Or Colors.red
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Green Circle
                        Container(
                          width: circleDiameter,
                          height: circleDiameter,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent, // Or Colors.green
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  // --- End Theme Selection Section ---

                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
          actions: <Widget>[
            if (!_isSaving)
              TextButton(
                child: const Text('Avbryt'),
                onPressed: () { Navigator.of(context).pop(null); },
              ),
            ElevatedButton(
              onPressed: (_isSaving || !_repoInitialized) ? null : _submitForm,
              child: _isSaving
                  ? const SizedBox(/* ... progress indicator ... */)
                  : Text(isEditing ? 'Spara' : 'Skapa min berättelse'),
            ),
          ],
        );
      }
}