import 'package:flutter/material.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({super.key});

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  List<Map<String, String>> users = [
    {
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'Admin',
      'enble': 'Actif'
    },
    {
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'role': 'Manager',
      'enble': 'Inactif'
    },
    {
      'name': 'Mike Johnson',
      'email': 'mike@example.com',
      'role': 'Utilisateur',
      'enble': 'Actif'
    },
    {
      'name': 'Alice Brown',
      'email': 'alice@example.com',
      'role': 'Caissier',
      'enble': 'Actif'
    },
    {
      'name': 'Bob White',
      'email': 'bob@example.com',
      'role': 'Livreur',
      'enble': 'Inactif'
    },
    {
      'name': 'Charlie Black',
      'email': 'charlie@example.com',
      'role': 'Pâtissier',
      'enble': 'Actif'
    },
    {
      'name': 'Dave Green',
      'email': 'dave@example.com',
      'role': 'Boulanger',
      'enble': 'Inactif'
    },
  ];
  String selectedRole = 'Tous les rôles';
  String selectedStatus = 'Tous les états';

  Future<void> _logout() async {
    await AuthService().logout(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFE5E7EB),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFormSearch(),
              const SizedBox(height: 10),
              _buildUserList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                    items: ['Tous les rôles', 'Admin', 'Manager', 'Utilisateur']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(
                                role,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'arial',
                                    fontSize: 18),
                              ),
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[400],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    dropdownColor: Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                    items: ['Tous les états', 'Actif', 'Inactif']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'arial',
                                    fontSize: 18),
                              ),
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[400],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    dropdownColor: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      children: users.map((user) {
        Color roleColor;
        Color backGroundRoleColor;
        switch (user['role']) {
          case 'Caissier':
            roleColor = const Color(0xFFFB8C00);
            backGroundRoleColor = Colors.orange[100]!;
            break;
          case 'Livreur':
            roleColor = const Color(0xFF795548);
            backGroundRoleColor = Colors.brown[100]!;
            break;
          case 'Pâtissier':
            roleColor = const Color(0xFF2196F3);
            backGroundRoleColor = Colors.blue[100]!;
            break;
          case 'Boulanger':
            roleColor = const Color(0xFF4CAF50);
            backGroundRoleColor = Colors.green[100]!;
            break;
          case 'Admin':
            roleColor = Colors.red;
            backGroundRoleColor = Colors.red[100]!;
            break;
          case 'Manager':
            roleColor = Colors.blue;
            backGroundRoleColor = Colors.blue[100]!;
            break;
          default:
            roleColor = Colors.green;
            backGroundRoleColor = Colors.green[100]!;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        NetworkImage('https://via.placeholder.com/150'),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(user['email']!),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: backGroundRoleColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user['role']!,
                          style: TextStyle(
                              color: roleColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Animation du statut avec changement d'état
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user['enble'] == 'Actif'
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['enble']!,
                      style: TextStyle(
                        color: user['enble'] == 'Actif'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Switch animé
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Spacer(),
                    Switch(
                      value: user['enble'] == 'Actif',
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (bool value) {
                        setState(() {
                          user['enble'] = value ? 'Actif' : 'Inactif';
                        });
                      },
                    ),
                    SizedBox(width: 5),
IconButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedRole = user['role']!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Modifier le Rôle',
                style: TextStyle(
                  color: Color(0xFFFB8C00),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nom d\'utilisateur :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user['name']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      key: ValueKey<String>(selectedRole),
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedRole = 'Manager';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedRole == 'Manager'
                                ? Colors.blueAccent // Blue for Manager
                                : Colors.blue[100], // Light Blue for unselected
                            minimumSize: Size(double.infinity, 50), // Height of the button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: selectedRole == 'Manager'
                                    ? Colors.white
                                    : Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Manager',
                                style: TextStyle(
                                  color: selectedRole == 'Manager'
                                      ? Colors.white
                                      : Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedRole = 'Admin';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedRole == 'Admin'
                                ? Colors.deepOrange // Orange for Admin
                                : Colors.orange[100], // Light Orange for unselected
                            minimumSize: Size(double.infinity, 50), // Height of the button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield,
                                color: selectedRole == 'Admin'
                                    ? Colors.white
                                    : Colors.deepOrange,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  color: selectedRole == 'Admin'
                                      ? Colors.white
                                      : Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedRole = 'Utilisateur';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedRole == 'Utilisateur'
                                ? Colors.green // Green for Utilisateur
                                : Colors.green[100], // Light Green for unselected
                            minimumSize: Size(double.infinity, 50), // Height of the button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                color: selectedRole == 'Utilisateur'
                                    ? Colors.white
                                    : Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Utilisateur',
                                style: TextStyle(
                                  color: selectedRole == 'Utilisateur'
                                      ? Colors.white
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      user['role'] = selectedRole;
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB8C00),
                    minimumSize: Size(100, 50), // Height for "Save" button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  },
  icon: const Icon(Icons.edit, color: Colors.white),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFB8C00),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),
),
   const SizedBox(width: 5),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text(
                                'Confirmation',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              content: const Text(
                                'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Ferme la boîte de dialogue
                                  },
                                  child: const Text(
                                    'Annuler',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      users.remove(user);
                                    });
                                    Navigator.of(context)
                                        .pop(); // Ferme la boîte de dialogue
                                  },
                                  child: const Text(
                                    'Supprimer',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
