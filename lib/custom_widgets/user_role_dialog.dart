import 'package:flutter/material.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/services/manager/managment_employees.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays a dialog to view user information and modify their role.
void showUserRoleDialog(
  BuildContext context,
  UserClass user,
  Function fetchUsers,
  int currentPage,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String selectedRole = user.role;
      return StatefulBuilder(
        builder: (context, setState) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400.0),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              title: Text(
                AppLocalizations.of(context)!.modifyRole,
                style: const TextStyle(
                  color: Color(0xFFFB8C00),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User Information Section
                    _buildUserInfoTile(
                      icon: Icons.person,
                      label: AppLocalizations.of(context)!.userName,
                      value: user.name,
                      context: context,
                    ),
                    _buildUserInfoTile(
                      icon: Icons.badge,
                      label: AppLocalizations.of(context)!.cin,
                      value: user.cin,
                      context: context,
                    ),
                    _buildUserInfoTile(
                      icon: Icons.location_on,
                      label: AppLocalizations.of(context)!.adresse,
                      value: user.address,
                      context: context,
                    ),
                    _buildUserInfoTile(
                      icon: Icons.email,
                      label: AppLocalizations.of(context)!.email,
                      value: user.email,
                      context: context,
                    ),
                    _buildUserInfoTile(
                      icon: Icons.phone,
                      label: AppLocalizations.of(context)!.phone,
                      value: user.phone,
                      context: context,
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () async {
                          final phoneUrl = 'tel:${user.phone}';
                          if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                            await launchUrl(Uri.parse(phoneUrl));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cannot make call to ${user.phone}'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Role Selection Section
                    Text(
                      AppLocalizations.of(context)!.selectRole,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Column(
                        key: ValueKey<String>(selectedRole),
                        children: [
                          _buildRoleButton(
                            role: 'patissier',
                            selectedRole: selectedRole,
                            icon: Icons.cake,
                            color: Colors.blueAccent,
                            label: Traductions().traductionrole(context, 'patissier'),
                            onPressed: () => setState(() => selectedRole = 'patissier'),
                          ),
                          const SizedBox(height: 10),
                          _buildRoleButton(
                            role: 'boulanger',
                            selectedRole: selectedRole,
                            icon: FontAwesomeIcons.breadSlice,
                            color: const Color(0xFF795548),
                            label: Traductions().traductionrole(context, 'boulanger'),
                            onPressed: () => setState(() => selectedRole = 'boulanger'),
                          ),
                          const SizedBox(height: 10),
                          _buildRoleButton(
                            role: 'caissier',
                            selectedRole: selectedRole,
                            icon: Icons.monetization_on,
                            color: Colors.deepOrange,
                            label: Traductions().traductionrole(context, 'caissier'),
                            onPressed: () => setState(() => selectedRole = 'caissier'),
                          ),
                          const SizedBox(height: 10),
                          _buildRoleButton(
                            role: 'livreur',
                            selectedRole: selectedRole,
                            icon: Icons.local_shipping,
                            color: Colors.purple,
                            label: Traductions().traductionrole(context, 'livreur'),
                            onPressed: () => setState(() => selectedRole = 'livreur'),
                          ),
                          const SizedBox(height: 10),
                          _buildRoleButton(
                            role: 'special_customer',
                            selectedRole: selectedRole,
                            icon: Icons.star,
                            color: Colors.teal,
                            label: Traductions().traductionrole(context, 'special_customer'),
                            onPressed: () => setState(() => selectedRole = 'special_customer'),
                          ),
                          const SizedBox(height: 10),
                          _buildRoleButton(
                            role: 'user',
                            selectedRole: selectedRole,
                            icon: Icons.person,
                            color: Colors.green,
                            label: Traductions().traductionrole(context, 'user'),
                            onPressed: () => setState(() => selectedRole = 'user'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await ManagementEmployeesService().updateUserRole(user.id, selectedRole, context);
                    fetchUsers(page: currentPage);
                    setState(() {
                      user.role = selectedRole;
                    });
                    fetchUsers(page: currentPage);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB8C00),
                    minimumSize: const Size(100, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.save,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Builds a styled tile for displaying user information with an icon and optional trailing widget.
Widget _buildUserInfoTile({
  required IconData icon,
  required String label,
  required String value,
  required BuildContext context,
  Widget? trailing,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    padding: const EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: Color(0xFFFB8C00), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}

/// Builds a role selection button with dynamic styling based on selection state.
Widget _buildRoleButton({
  required String role,
  required String selectedRole,
  required IconData icon,
  required Color color,
  required String label,
  required VoidCallback onPressed,
}) {
  bool isSelected = role == selectedRole;
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: isSelected ? color : color.withOpacity(0.1),
      foregroundColor: isSelected ? Colors.white : color,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: isSelected ? 4 : 0,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.white : color,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}