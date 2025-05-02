import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileImageSelector extends StatefulWidget {
  final Function(File? imageFile) onImageSelected;
  final bool isDisabled;
  final String placeholderImagePath;

  const ProfileImageSelector({
    super.key,
    required this.onImageSelected,
    required this.placeholderImagePath,
    this.isDisabled = false,
  });

  @override
  State<ProfileImageSelector> createState() => _ProfileImageSelectorState();
}

class _ProfileImageSelectorState extends State<ProfileImageSelector> {
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (widget.isDisabled) return;

    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      File? finalResultFile;

      if (pickedFile != null) {
        print("ProfileImageSelector: Image selected: ${pickedFile.path}");

        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          // --- CHANGE 1: Update Aspect Ratio Here ---
          aspectRatio: const CropAspectRatio(ratioX: 7, ratioY: 10), // Changed from 3:4 to 7:10
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Beskär bild',
                toolbarColor: theme.primaryColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: true, // Keep locked
                hideBottomControls: false
            ),
            IOSUiSettings(
                title: 'Beskär bild',
                aspectRatioLockEnabled: true, // Keep locked
                resetAspectRatioEnabled: false,
                aspectRatioPickerButtonHidden: true,
                doneButtonTitle: 'Klar',
                cancelButtonTitle: 'Avbryt'
            ),
          ],
        );

        if (croppedFile != null) {
          finalResultFile = File(croppedFile.path);
          print("ProfileImageSelector: Image cropped: ${croppedFile.path}");
        } else {
          print("ProfileImageSelector: Image cropping cancelled.");
        }

      } else {
        print("ProfileImageSelector: Image selection cancelled.");
      }

      setState(() {
        _selectedImageFile = finalResultFile;
      });
      widget.onImageSelected(_selectedImageFile);

    } catch (e) {
      print("ProfileImageSelector: Error picking/cropping image: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Kunde inte välja eller beskära bild.'))
        );
      }
      if (_selectedImageFile != null) {
         setState(() { _selectedImageFile = null; });
         widget.onImageSelected(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- CHANGE 2: Update Preview Dimensions ---
    const double previewHeight = 100.0;
    const double previewWidth = previewHeight * (7 / 10); // Calculate width based on 7:10 ratio

    Widget imagePlaceholder = Container(
        width: previewWidth,  // Use calculated width
        height: previewHeight, // Use defined height
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
                image: AssetImage(widget.placeholderImagePath),
                fit: BoxFit.contain, // Contain is fine for placeholder
            )
        ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: widget.isDisabled ? null : _pickImage,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            width: previewWidth,  // Use calculated width
            height: previewHeight, // Use defined height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              // Optional: Add a subtle border if needed for visual separation
              // border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _selectedImageFile != null
                  ? Image.file(
                      _selectedImageFile!,
                      fit: BoxFit.cover, // Cover should work well now
                      width: previewWidth,  // Use calculated width
                      height: previewHeight, // Use defined height
                      errorBuilder: (context, error, stackTrace) {
                        print("ProfileImageSelector: Error loading image file: $error");
                        return imagePlaceholder;
                      },
                    )
                  : imagePlaceholder,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.isDisabled ? null : _pickImage,
            icon: const Icon(Icons.image_search),
            label: Text(_selectedImageFile == null ? 'Välj bild' : 'Ändra bild'),
          ),
        ),
      ],
    );
  }
}