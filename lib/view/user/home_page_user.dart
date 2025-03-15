import 'package:flutter/material.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
  // Assure-toi de bien avoir cette page

class HomePageUser extends StatefulWidget {
  const HomePageUser({super.key});

  @override
  State<HomePageUser> createState() => _HomePageUserState();
}

class _HomePageUserState extends State<HomePageUser> {
  Future<void> _logout() async {
    await AuthService().logout(context);
    // Redirection vers la page de connexion après déconnexion
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenue sur la page d\'accueil utilisateur'),
      ),
    );
  }
}
