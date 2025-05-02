import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileImageSelector extends StatefulWidget {
  final Function(File? imageFile) onImageSelected;
  final bool isDisabled;
  final String placeholderImagePath;
  final String? initialImagePath;

  const ProfileImageSelector({
    super.key,
    required this.onImageSelected,
    required this.placeholderImagePath,
    this.initialImagePath,
    this.isDisabled = false,
  });

  @override
  State<ProfileImageSelector> createState() => _ProfileImageSelectorState();
}

class _ProfileImageSelectorState extends State<ProfileImageSelector> {
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeSelectedFile();
  }

  void _initializeSelectedFile() {
    final path = widget.initialImagePath;
    if (path != null && path.isNotEmpty && path != widget.placeholderImagePath) {
      _selectedImageFile = File(path);
      print("ProfileImageSelector: Initialized with image path: $path");
    } else {
      _selectedImageFile = null;
      print("ProfileImageSelector: No valid initial image path provided.");
    }
  }

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
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 7, ratioY: 10),
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Beskär bild',
                toolbarColor: theme.primaryColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: true),
            IOSUiSettings(
                title: 'Beskär bild',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
                doneButtonTitle: 'Klar',
                cancelButtonTitle: 'Avbryt'),
          ],
        );

        if (croppedFile != null) {
          finalResultFile = File(croppedFile.path);
        }
      }

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
            const SnackBar(content: Text('Kunde inte välja eller beskära bild.')));
      }
      if (_selectedImageFile != null) {
        setState(() {
          _selectedImageFile = null;
        });
        widget.onImageSelected(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double previewHeight = 100.0;
    const double previewWidth = previewHeight * (7 / 10);

    Widget imagePlaceholder = Image.asset(
      widget.placeholderImagePath,
      fit: BoxFit.cover,
      width: previewWidth,
      height: previewHeight,
    );

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
              child: _selectedImageFile != null
                  ? Image.file(
                      _selectedImageFile!,
                      fit: BoxFit.cover,
                      width: previewWidth,
                      height: previewHeight,
                      errorBuilder: (context, error, stackTrace) => imagePlaceholder,
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
