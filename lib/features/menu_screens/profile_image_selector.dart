import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileImageSelector extends StatefulWidget {
  final Function(File? imageFile) onImageSelected;
  final bool isDisabled;
  final String placeholderImagePath;
  // --- 1. ADD initialImagePath parameter ---
  final String? initialImagePath;

  const ProfileImageSelector({
    super.key,
    required this.onImageSelected,
    required this.placeholderImagePath,
    this.initialImagePath, // Make it optional
    this.isDisabled = false,
  });
  // --- End Change ---

  @override
  State<ProfileImageSelector> createState() => _ProfileImageSelectorState();
}

class _ProfileImageSelectorState extends State<ProfileImageSelector> {
  File? _selectedImageFile; // This will now be initialized based on initialImagePath
  final ImagePicker _picker = ImagePicker();

  // --- 3. ADD initState to handle initial image ---
  @override
  void initState() {
    super.initState();
    _initializeSelectedFile();
  }

  void _initializeSelectedFile() {
    final path = widget.initialImagePath;
    // Check if we have a valid path AND it's different from the placeholder
    if (path != null && path.isNotEmpty && path != widget.placeholderImagePath) {
      // Assume it's a file path if it's not the known asset placeholder
      // A check like !path.startsWith('assets/') could also work
      File potentialFile = File(path);
      // Optional: Check if the file actually exists before setting state?
      // This adds a synchronous file system check, might be slow.
      // For now, we optimistically assume the path is valid if it was saved.
      // if (potentialFile.existsSync()) {
      _selectedImageFile = potentialFile;
      print("ProfileImageSelector: Initialized with image path: $path");
      // } else {
      //   print("ProfileImageSelector: Initial image path file does not exist: $path");
      //   _selectedImageFile = null;
      // }
    } else {
      // No initial image or it's the placeholder, start with null state
      _selectedImageFile = null;
      print("ProfileImageSelector: No valid initial image path provided.");
    }
    // NO setState needed here, build hasn't run yet.
    // DO NOT call widget.onImageSelected, this is just initial state setup.
  }
  // --- End Change ---


  // --- _pickImage method (no changes needed) ---
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
        final CroppedFile? croppedFile = await ImageCropper().cropImage(/* ... Cropper Config ... */
         sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 7, ratioY: 10),
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Beskär bild',
                toolbarColor: theme.primaryColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: true,
                hideBottomControls: false
            ),
            IOSUiSettings(
                title: 'Beskär bild',
                aspectRatioLockEnabled: true,
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

      // Only update state and call callback IF the result is different from current state
      // This prevents calling the callback unnecessarily if the user cancels
      if (finalResultFile?.path != _selectedImageFile?.path) {
          setState(() {
            _selectedImageFile = finalResultFile;
          });
          widget.onImageSelected(_selectedImageFile);
      }

    } catch (e) {
      print("ProfileImageSelector: Error picking/cropping image: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Kunde inte välja eller beskära bild.'))
        );
      }
      // Reset state and notify parent only if there was an image before the error
      if (_selectedImageFile != null) {
         setState(() { _selectedImageFile = null; });
         widget.onImageSelected(null);
      }
    }
  }

  // --- build method (no changes needed) ---
  @override
  Widget build(BuildContext context) {
    const double previewHeight = 100.0;
    const double previewWidth = previewHeight * (7 / 10);

    Widget imagePlaceholder = Container( /* ... Placeholder definition ... */ );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: widget.isDisabled ? null : _pickImage,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            width: previewWidth,
            height: previewHeight,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              // Build method automatically uses the _selectedImageFile state,
              // which is now initialized correctly in initState.
              child: _selectedImageFile != null
                  ? Image.file(
                      _selectedImageFile!,
                      fit: BoxFit.cover,
                      width: previewWidth,
                      height: previewHeight,
                      errorBuilder: (context, error, stackTrace) {
                        print("ProfileImageSelector: Error loading image file: $error");
                        // If file load fails, revert state and show placeholder?
                        // Maybe just show placeholder on error.
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           // Avoid calling setState during build
                            if (mounted && _selectedImageFile != null) {
                              setState(() { _selectedImageFile = null; });
                               widget.onImageSelected(null); // Also notify parent? Risky during build.
                            }
                         });
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