import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Result of a successful image attachment upload.
class UploadedImage {
  final String filename;
  final String docRef;

  const UploadedImage({required this.filename, required this.docRef});
}

/// Widget for picking, previewing, and removing images before ticket creation.
///
/// Supports picking from gallery or camera, shows thumbnail grid with delete
/// buttons, and provides upload progress tracking.
class ImageAttachmentPicker extends StatefulWidget {
  /// Called when images are ready to be uploaded (after ticket is created).
  /// Returns list of uploaded image doc_refs.
  final Future<List<String>> Function(List<XFile> images, String ticketId)
      onUpload;

  /// Whether uploads are currently in progress.
  final ValueChanged<bool>? onUploadingChanged;

  const ImageAttachmentPicker({
    super.key,
    required this.onUpload,
    this.onUploadingChanged,
  });

  @override
  State<ImageAttachmentPicker> createState() => ImageAttachmentPickerState();
}

class ImageAttachmentPickerState extends State<ImageAttachmentPicker> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _uploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add image buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _uploading ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _uploading ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Camera'),
            ),
          ],
        ),

        // Upload progress indicator
        if (_uploading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 4),
          Text(
            'Uploading images...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],

        // Thumbnail grid
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final image = _selectedImages[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ImageThumbnail(
                    image: image,
                    onRemove: _uploading
                        ? null
                        : () => _removeImage(index),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Pick with compression: target ~500KB (quality 70 at reduced resolution)
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Returns the selected images for upload after ticket creation.
  List<XFile> get selectedImages => List.unmodifiable(_selectedImages);

  /// Clears all selected images (after successful upload).
  void clear() {
    setState(() {
      _selectedImages.clear();
      _uploadProgress = 0.0;
    });
  }

  /// Sets upload progress (0.0 to 1.0).
  void setUploadProgress(double progress) {
    setState(() {
      _uploadProgress = progress;
    });
  }

  /// Sets uploading state.
  void setUploading(bool uploading) {
    setState(() {
      _uploading = uploading;
    });
    widget.onUploadingChanged?.call(uploading);
  }
}

class _ImageThumbnail extends StatelessWidget {
  final XFile image;
  final VoidCallback? onRemove;

  const _ImageThumbnail({
    required this.image,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 32),
                );
              },
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
