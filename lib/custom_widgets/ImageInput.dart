import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImageInputWidget extends StatefulWidget {
  final Function(String? imagePath, Uint8List? webImage) onImageSelected;
  final String? initialImage; // Peut être une URL
  final double height; // Paramètre height
  final double width;  // Paramètre width

  const ImageInputWidget({
    Key? key,
    required this.onImageSelected,
    this.initialImage,
    required this.height, // Receive height
    required this.width, String? imagePath, Uint8List? webImage,  // Receive width
  }) : super(key: key);

  @override
  _ImageInputWidgetState createState() => _ImageInputWidgetState();
}

class _ImageInputWidgetState extends State<ImageInputWidget> {
  String? _imagePath;
  Uint8List? _webImage;
  bool get _isNetworkImage => widget.initialImage != null &&
      (widget.initialImage!.startsWith('http://') || widget.initialImage!.startsWith('https://'));

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImage;
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? result = await _picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      if (kIsWeb) {
        final Uint8List webImage = await result.readAsBytes();
        setState(() {
          _webImage = webImage;
          _imagePath = result.name; // Stocker le nom du fichier
        });
        widget.onImageSelected(result.name, webImage); // Envoyer les deux valeurs
      } else {
        setState(() {
          _imagePath = result.path;
          _webImage = null;
        });
        widget.onImageSelected(result.path, null);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imagePath = null;
      _webImage = null;
    });
    widget.onImageSelected(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _webImage != null
              ? Image.memory(
                  _webImage!,
                  height: widget.height, // Use parameter height
                  width: widget.width,   // Use parameter width
                  fit: BoxFit.cover,
                )
              : (_imagePath != null && _imagePath!.isNotEmpty)
                  ? (_isNetworkImage
                      ? Image.network(
                          _imagePath!,
                          height: widget.height, // Use parameter height
                          width: widget.width,   // Use parameter width
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                          },
                        )
                      : Image.file(
                          File(_imagePath!),
                          height: widget.height, // Use parameter height
                          width: widget.width,   // Use parameter width
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                          },
                        ))
                  : Container(
                      height: widget.height, // Use parameter height
                      width: widget.width,   // Use parameter width
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.photo_library, size: 50, color: Colors.grey),
                    ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _imagePath != null || _webImage != null ? _clearImage : _pickImage,
          icon: Icon(_imagePath != null || _webImage != null ? Icons.delete : Icons.photo_library),
          label: Text(
            (_imagePath != null && _imagePath!.isNotEmpty) || _webImage != null
                ? AppLocalizations.of(context)!.deleteImage
                : AppLocalizations.of(context)!.chooseAnImage,
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
      ],
    );
  }
}
