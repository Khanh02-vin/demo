import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_theme.dart';
import 'app_button.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImageSelected;
  final String? initialImagePath;
  final String title;
  final String subtitle;
  final bool showPreview;
  final bool isSelecting;
  final bool showImageSourceDialog;
  final Function()? onLoading;
  final Function()? onComplete;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.initialImagePath,
    this.title = 'Scan an Orange',
    this.subtitle = 'Take a picture or select from gallery',
    this.showPreview = true,
    this.isSelecting = false,
    this.showImageSourceDialog = true,
    this.onLoading,
    this.onComplete,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _image = File(widget.initialImagePath!);
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    if (widget.onLoading != null) {
      widget.onLoading!();
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      setState(() {
        _isLoading = false;
      });

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _image = imageFile;
        });
        widget.onImageSelected(imageFile);
        
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (!widget.showImageSourceDialog) {
      // If dialog is disabled, default to camera
      _getImage(ImageSource.camera);
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Image Source',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildOptionButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () {
                          Navigator.pop(context);
                          _getImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: _buildOptionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () {
                          Navigator.pop(context);
                          _getImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                AppButton(
                  text: 'Cancel',
                  type: ButtonType.text,
                  onPressed: () => Navigator.pop(context),
                  fullWidth: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.cardLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              label,
              style: AppTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.showPreview && _image != null)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.defaultShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        else if (widget.showPreview)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: AppTheme.cardLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.defaultShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_camera,
                    size: 50,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    widget.title,
                    style: AppTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                    child: Text(
                      widget.subtitle,
                      style: AppTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppTheme.spacingMd),
        if (_image == null || !widget.isSelecting)
          AppButton(
            text: _image == null ? 'Select Image' : 'Change Image',
            icon: _image == null ? Icons.add_photo_alternate : Icons.refresh,
            isLoading: _isLoading,
            onPressed: _showImageSourceDialog,
            type: _image == null ? ButtonType.primary : ButtonType.secondary,
          ),
      ],
    );
  }
} 