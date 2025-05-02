import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

// Import the selector widget
import 'package:barnbok/features/menu_screens/profile_image_selector.dart'; // Ensure path is correct

// Adjust paths as needed
import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';


// --- showCreateStoryDialog function (no changes) ---
Future<bool?> showCreateStoryDialog(
  BuildContext context,
  int positionIndex, {
  CardInfo? existingCard,
}) async {
  final result = await showDialog<bool?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _CreateStoryDialogContent(
        positionIndex: positionIndex,
        existingCard: existingCard,
      );
    },
  );
  return result;
}


class _CreateStoryDialogContent extends StatefulWidget {
  final int positionIndex;
  final CardInfo? existingCard;

  const _CreateStoryDialogContent({
    required this.positionIndex,
    this.existingCard,
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

  File? _finalSelectedImageFile;

  static const String fakeImagePath = 'assets/images/baby_foot_ceramic.jpg';

  // --- Theme Selection State ---
  // List of available theme colors
  final List<Color> _availableColors = const [
    Colors.lightBlueAccent, // Default selected
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.greenAccent,
  ];
  // State variable to hold the currently selected color
  late Color _selectedThemeColor;
  // --- End Theme Selection State ---

  bool get isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();

    _surnameController = TextEditingController(text: widget.existingCard?.surname ?? '');
    _lastNameController = TextEditingController(text: widget.existingCard?.lastName ?? '');

    // --- Initialize Theme ---
    // TODO: Later, load from widget.existingCard?.themeColor if available
    _selectedThemeColor = _availableColors[0]; // Default to the first color (Light Blue Accent)
    // --- End Theme Init ---

    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    // ... (no changes) ...
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


  Future<void> _submitForm() async {
     // ... (submitForm logic - no changes for now, theme saving needs adding later) ...
     if (!_repoInitialized || _isSaving) return;

    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      try {
        final String surname = _surnameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String uniqueId = widget.existingCard?.uniqueId ?? const Uuid().v4();
        final int positionIndex = widget.existingCard?.positionIndex ?? widget.positionIndex;

        String imagePathToSave = widget.existingCard?.imagePath ?? fakeImagePath;
        if (_finalSelectedImageFile != null) {
          imagePathToSave = _finalSelectedImageFile!.path;
        }
        // TODO: Add logic here to get the selected theme color value
        // String themeColorValue = _selectedThemeColor.value.toRadixString(16); // Example

        final cardDataToSave = CardInfo(
          uniqueId: uniqueId,
          surname: surname,
          lastName: lastName.isEmpty ? null : lastName,
          imagePath: imagePathToSave,
          positionIndex: positionIndex,
          // TODO: Add themeColor field to CardInfo and pass value here
          // themeColor: themeColorValue,
        );

        print('CreateStoryDialog: Attempting to save (${isEditing ? "Edit" : "Create"})...');
        await _repository.saveCardInfo(cardDataToSave);

        print('--- SAVE SUCCESS (${isEditing ? "Edit" : "Create"}) ---');
        // ... (print statements) ...

        if (mounted) {
          Navigator.of(context).pop(true);
        }

      } catch (e, stackTrace) {
        print('CreateStoryDialog: Error saving card data: $e\n$stackTrace');
        if (mounted) {
          setState(() { _isSaving = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kunde inte ${isEditing ? "spara ändringar" : "skapa berättelsen"}.'))
            );
        }
      }
    }
  }

  // --- Helper method to build each color circle ---
  Widget _buildColorCircle(Color color) {
    const double circleDiameter = 30.0;
    const double borderThickness = 2.0;
    final bool isSelected = _selectedThemeColor == color;

    return InkWell(
      onTap: () {
        if (!_isSaving) { // Prevent changing theme while saving
          setState(() {
            _selectedThemeColor = color;
            print("Theme color selected: $color");
            // TODO: Need to store this selected color value for saving
          });
        }
      },
      customBorder: const CircleBorder(), // Make ripple effect circular
      child: Container(
        width: circleDiameter + (borderThickness * 2) + 4, // Diameter + border + padding
        height: circleDiameter + (borderThickness * 2) + 4,
        padding: const EdgeInsets.all(2.0), // Padding between border and inner circle
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Show border only if selected
          border: isSelected
              ? Border.all(color: Colors.black54, width: borderThickness)
              : Border.all(color: Colors.transparent, width: borderThickness), // Keep space consistent
        ),
        child: Container(
          width: circleDiameter,
          height: circleDiameter,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // Optional: Add a slight inner shadow or border to all circles for definition
            // border: Border.all(color: Colors.black12, width: 0.5)
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- First Name ---
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Förnamn', style: labelStyle),
              ),
              TextFormField( /* ... */ ),
              const SizedBox(height: 16),

              // --- Last Name ---
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Efternamn (valfritt)', style: labelStyle),
              ),
              TextFormField( /* ... */ ),
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

              // --- MODIFIED Theme Selection Section ---
              const SizedBox(height: 20),
              Text('Theme', style: labelStyle), // Or "Tema"
              const SizedBox(height: 8),
              // Use Wrap for better spacing flexibility if needed, Row is fine too
              Wrap(
                spacing: 10.0, // Horizontal space between circles
                runSpacing: 10.0, // Vertical space if wrapping occurs
                children: _availableColors.map((color) => _buildColorCircle(color)).toList(),
              ),
              // --- End Theme Selection Section ---

            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
      actions: <Widget>[
          // ... (actions remain the same) ...
           if (!_isSaving)
             TextButton(
               child: const Text('Avbryt'),
               onPressed: () { Navigator.of(context).pop(null); },
             ),
           ElevatedButton(
             onPressed: (_isSaving || !_repoInitialized) ? null : _submitForm,
             child: _isSaving
                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                 : Text(isEditing ? 'Spara' : 'Skapa min berättelse'),
           ),
      ],
    );
  }
}