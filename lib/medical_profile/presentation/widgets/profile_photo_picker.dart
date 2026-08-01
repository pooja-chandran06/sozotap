import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';

class ProfilePhotoPicker extends StatelessWidget {
  final String? photoUrl;
  final File? selectedImageFile;
  final ValueChanged<File> onImageSelected;

  const ProfilePhotoPicker({
    super.key,
    this.photoUrl,
    this.selectedImageFile,
    required this.onImageSelected,
  });

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      onImageSelected(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (selectedImageFile != null) {
      imageProvider = FileImage(selectedImageFile!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person_rounded, size: 64, color: AppColors.primary)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: () => _pickImage(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
