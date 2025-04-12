import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserProfileImage extends StatefulWidget {
  const UserProfileImage({super.key});

  @override
  State<UserProfileImage> createState() => _UserProfileImageState();
}

class _UserProfileImageState extends State<UserProfileImage> {
  String? _imagePath; // Pour Android/iOS (chemin de fichier)
  Uint8List? _webImageBytes; // Pour Web (bytes)
  String? _imageUrl; // URL de l'image utilisateur depuis l'API

  @override
  void initState() {
    super.initState();
    _loadInitialImage();
  }

  /// 📡 **Charge l'image initiale depuis l'API ou SharedPreferences**
  Future<void> _loadInitialImage() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Tenter de charger l'image depuis l'API en priorité
    await _fetchUserImage();

    // 2. Si aucune image n'est trouvée dans l'API, utiliser SharedPreferences comme fallback
    if (_imageUrl == null) {
      if (kIsWeb) {
        String? imageBase64 = prefs.getString('user_picture');
        if (imageBase64 != null) {
          setState(() {
            _webImageBytes = base64Decode(imageBase64);
          });
        }
      } else {
        setState(() {
          _imagePath = prefs.getString('user_picture');
        });
      }
    }
  }

  /// 📡 **Charge l'image depuis une API**
  Future<void> _fetchUserImage() async {
      final prefs = await SharedPreferences.getInstance();

        setState(() {
          _imageUrl = ApiConfig.changePathImage(prefs.getString('user_picture') ?? ''); // Assurez-vous que la clé correspond à votre API
        });
      
  }

  /// 📷 **Permet de sélectionner une image (Web & Mobile)**
  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        String base64String = base64Encode(bytes);
        await prefs.setString('user_picture', base64String);
        setState(() {
          _webImageBytes = bytes;
          _imagePath = null; // Réinitialiser pour éviter les conflits
          _imageUrl = null; // Réinitialiser l'URL API
        });
      } else {
        await prefs.setString('user_picture', pickedFile.path);
        setState(() {
          _imagePath = pickedFile.path;
          _webImageBytes = null; // Réinitialiser pour éviter les conflits
          _imageUrl = null; // Réinitialiser l'URL API
        });
      }
      await _updateUserImage(); // Mettre à jour l'image sur le serveur après sélection
    }
  }

  /// 🔄 **Envoie la nouvelle image à l'API**
  Future<void> _updateUserImage() async {
    if (_imagePath == null && _webImageBytes == null) {
      print("Aucune image à envoyer");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        print("Token d'authentification manquant");
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}account/update-image'),
      );

      // Ajouter les headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Ajouter l'image au champ 'image'
      if (kIsWeb && _webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImageBytes!,
            filename: 'profile_image.jpg',
          ),
        );
      } else if (!kIsWeb && _imagePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _imagePath!,
          ),
        );
      }

      // Envoyer la requête
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody.body);
        if (data['user_picture'] != null) {
          await prefs.setString('user_picture', data['user_picture']);
          setState(() {
            _imageUrl = data['user_picture']; // Mettre à jour l'URL depuis la réponse
            _imagePath = null; // Réinitialiser le chemin local
            _webImageBytes = null; // Réinitialiser les bytes web
          });
        }
        print("Image mise à jour avec succès : $_imageUrl");
      } else {
        print("Erreur lors de la mise à jour de l'image : ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur lors de l'envoi de l'image : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: _getUserImage(),
          child: _imageUrl == null && _imagePath == null && _webImageBytes == null
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickAndSaveImage, // Sélectionne et met à jour l'image
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFB8C00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔄 **Retourne l'image correcte en fonction de la plateforme**
  ImageProvider? _getUserImage() {
    if (_imageUrl != null) {
      return NetworkImage(_imageUrl!);
    } else if (kIsWeb && _webImageBytes != null) {
      return MemoryImage(_webImageBytes!);
    } else if (!kIsWeb && _imagePath != null) {
      return FileImage(File(_imagePath!));
    }
    return null;
  }
}