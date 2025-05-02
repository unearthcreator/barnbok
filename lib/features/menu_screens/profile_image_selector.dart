import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageSelector extends StatefulWidget {
  // Callback function to notify the parent widget when an image is selected/changed.
  final Function(File? imageFile) onImageSelected;
  // Flag to disable the picker controls (e.g., while parent is saving).
  final bool isDisabled;
  // Path for the default placeholder image.
  final String placeholderImagePath;

  const ProfileImageSelector({
    super.key,
    required this.onImageSelected,
    required this.placeholderImagePath,
    this.isDisabled = false, // Default to enabled
  });

  @override
  State<ProfileImageSelector> createState() => _ProfileImageSelectorState();
}

class _ProfileImageSelectorState extends State<ProfileImageSelector> {
  // State variable local to this widget to hold the selected image file.
  File? _selectedImageFile;
  // ImagePicker instance local to this widget.
  final ImagePicker _picker = ImagePicker();

  // Method to handle picking an image (without cropping for now).
  Future<void> _pickImage() async {
    // Do nothing if the widget is disabled.
    if (widget.isDisabled) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      File? newlySelectedFile; // Temporary variable

      if (pickedFile != null) {
        newlySelectedFile = File(pickedFile.path);
        print("ProfileImageSelector: Image selected: ${pickedFile.path}");
      } else {
        // User canceled the picker - explicitly set to null if needed,
        // though newlySelectedFile is already null here.
        print("ProfileImageSelector: Image selection cancelled.");
      }

      // Update the local state to refresh the preview.
      setState(() {
        _selectedImageFile = newlySelectedFile;
      });

      // Notify the parent widget about the selected file (or null if cancelled).
      widget.onImageSelected(_selectedImageFile);

    } catch (e) {
      print("ProfileImageSelector: Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunde inte välja bild. Kontrollera behörigheter.'))
        );
      }
      // Notify parent that selection failed / resulted in null
      // Only call if the previous state wasn't already null, to avoid redundant calls
      if (_selectedImageFile != null) {
         setState(() { _selectedImageFile = null; }); // Clear local preview on error too
         widget.onImageSelected(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define placeholder widget using the path passed in constructor
    Widget imagePlaceholder = Container(
        width: 75,
        height: 100,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
                image: AssetImage(widget.placeholderImagePath),
                fit: BoxFit.contain,
            )
        ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Clickable Image Preview Area
        InkWell(
          onTap: widget.isDisabled ? null : _pickImage, // Use local _pickImage
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            width: 75,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _selectedImageFile != null // Use local _selectedImageFile
                  ? Image.file(
                      _selectedImageFile!,
                      fit: BoxFit.contain,
                      width: 75,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        print("ProfileImageSelector: Error loading image file: $error");
                        // Optionally call onImageSelected(null) if load fails after selection?
                        // For now, just show placeholder
                        return imagePlaceholder;
                      },
                    )
                  : imagePlaceholder, // Show placeholder
            ),
          ),
        ),

        const SizedBox(width: 16), // Spacing

        // Choose/Change Image Button
        Expanded(
          child: ElevatedButton.icon(
            // Disable if globally disabled OR if no image selected yet? No, allow picking always if not disabled.
            onPressed: widget.isDisabled ? null : _pickImage, // Use local _pickImage
            icon: const Icon(Icons.image_search),
            // Label depends on local state
            label: Text(_selectedImageFile == null ? 'Välj bild' : 'Ändra bild'),
          ),
        ),
      ],
    );
  }
}