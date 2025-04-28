import 'package:flutter/material.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RoleWidget extends StatelessWidget {
  final String role;

  const RoleWidget({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // Déclarer les variables
    Color roleColor;
    Color backGroundRoleColor;
    Icon roleIcon;

    // Logique pour le style des rôles
    switch (role) {
      case 'special_customer':
        roleColor =  Colors.teal;
        backGroundRoleColor = Colors.teal[100]!;
        roleIcon = const Icon(Icons.monetization_on,
            color: Colors.teal, size: 20);
        break;
      case 'caissier':
        roleColor = const Color(0xFFFB8C00);
        backGroundRoleColor = Colors.orange[100]!;
        roleIcon = const Icon(Icons.monetization_on,
            color: Color(0xFFFB8C00), size: 20);
        break;
      case 'livreur':
        roleColor =  Colors.purple;
        backGroundRoleColor = Colors.purple[100]!;
        roleIcon = const Icon(Icons.local_shipping,
            color: Colors.purple, size: 20);
        break;
      case 'patissier':
        roleColor = const Color(0xFF2196F3);
        backGroundRoleColor = Colors.blue[100]!;
        roleIcon = const Icon(Icons.cake,
            color: Color(0xFF2196F3), size: 20);
        break;
      case 'boulanger':
        roleColor = const Color(0xFF795548);
        backGroundRoleColor = const Color(0xFF795548).withOpacity(0.1);
        roleIcon = const Icon(FontAwesomeIcons.breadSlice,
            color: Color(0xFF795548), size: 20);
        break;
      case 'admin':
        roleColor = Colors.red;
        backGroundRoleColor = Colors.red[100]!;
        roleIcon = const Icon(Icons.admin_panel_settings,
            color: Colors.red, size: 20);
        break;
      case 'manager':
        roleColor = Colors.blue;
        backGroundRoleColor = Colors.blue[100]!;
        roleIcon = const Icon(FontAwesomeIcons.userTie,
            color: Colors.blue, size: 20);
        break;
      default:
        roleColor = Colors.green;
        backGroundRoleColor = Colors.green[100]!;
        roleIcon = const Icon(Icons.person,
            color: Colors.green, size: 20);
    }

    // Construction de l'affichage
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backGroundRoleColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          roleIcon,
          const SizedBox(width: 4),
          Text(
            Traductions().traductionrole(context,role),// Affichage du rôle
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

}
