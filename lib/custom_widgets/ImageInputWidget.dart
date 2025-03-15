import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImageInputWidget extends StatefulWidget {
  final Function(String? imagePath, Uint8List? webImage) onImageSelected;
  final String? imagePath;
  final Uint8List? webImage;
  final double height;
  final double width;

  const ImageInputWidget({
    Key? key,
    required this.onImageSelected,
    this.imagePath,
    this.webImage,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  _ImageInputWidgetState createState() => _ImageInputWidgetState();
}

class _ImageInputWidgetState extends State<ImageInputWidget> {
  bool get _isNetworkImage => widget.imagePath != null &&
      (widget.imagePath!.startsWith('http://') || 
       widget.imagePath!.startsWith('https://'));

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? result = await _picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      if (kIsWeb) {
        final Uint8List webImage = await result.readAsBytes();
        widget.onImageSelected(result.name, webImage);
      } else {
        widget.onImageSelected(result.path, null);
      }
    }
  }

  void _clearImage() {
    widget.onImageSelected(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _buildImagePreview(),
        ),
        const SizedBox(height: 20),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (widget.webImage != null) {
      return Image.memory(
        widget.webImage!,
        height: widget.height,
        width: widget.width,
        fit: BoxFit.cover,
      );
    }
    if (widget.imagePath != null) {
      if (_isNetworkImage) {
        return Image.network(
          widget.imagePath!,
          height: widget.height,
          width: widget.width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
      return Image.file(
        File(widget.imagePath!),
        height: widget.height,
        width: widget.width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.photo_library, size: 50, color: Colors.grey),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: (widget.imagePath != null || widget.webImage != null)
          ? _clearImage
          : _pickImage,
      icon: Icon(
        (widget.imagePath != null || widget.webImage != null)
            ? Icons.delete
            : Icons.photo_library,
      ),
      label: Text(
        (widget.imagePath != null || widget.webImage != null)
            ? AppLocalizations.of(context)!.deleteImage
            : AppLocalizations.of(context)!.chooseAnImage,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    );
  }
}