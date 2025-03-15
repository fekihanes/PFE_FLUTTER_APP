import 'package:flutter/material.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/RoleWidget.dart';
import 'package:flutter_application/services/admin/admin_service.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({super.key});

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  List<UserClass> users = [];
  late String selectedRole;
  late String selectedStatus;
  int currentPage = 1;
  int lastPage = 1;
  bool isLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    selectedRole = l10n.allRoles;
    selectedStatus = l10n.allStates;
    if (users.isEmpty) fetchUsers();
  }

  Future<void> fetchUsers({int page = 1}) async {
    setState(() => isLoading = true);

    final l10n = AppLocalizations.of(context)!;
    final response = await AdminService().searchUsers(
      context,
      query: _searchController.text.trim(),
      role: selectedRole == l10n.allRoles ? null : selectedRole,
      enable: selectedStatus == l10n.allStates
          ? null
          : (selectedStatus == l10n.enabled ? 1 : 0),
      page: page,
    );

    setState(() {
      isLoading = false;
      if (response != null) {
        users = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
      } else {
        users = [];
        currentPage = 1;
        lastPage = 1;
        prevPageUrl = null;
        nextPageUrl = null;
      }
    });
  }

  Future<void> _logout() async {
    await AuthService().logout(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose of the controller when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.userManagement,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize:20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFE5E7EB),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Set mainAxisSize to min
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFormSearch(), // Affiche la barre de recherche et les filtres
                    const SizedBox(height: 10),
                    _buildUserList(), // Affiche la liste des utilisateurs
                  ],
                ),
              ),
            ),
            _buildPagination(), // Affiche la pagination
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (isLoading) {
      return const Center(
        heightFactor: 15,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        heightFactor: 20,
        child: Text(
          AppLocalizations.of(context)!.noUserFound,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: users.map((user) {
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
                    backgroundImage: NetworkImage(user.userPicture ?? ''),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name, // Accessing name directly
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(user.email), // Accessing email directly
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    RoleWidget(role: user.role),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.enable == 1
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.enable == 1
                            ? AppLocalizations.of(context)!.enabled
                            : AppLocalizations.of(context)!.disabled,
                        style: TextStyle(
                            color: user.enable == 1 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Spacer(),
                    Switch(
                      value: user.enable == 1, // Using direct user.enable check
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (bool value) async {
                        await AdminService()
                            .updateUserStatus(user.id, value ? 1 : 0, context);
                        setState(() {
                          user.enable =
                              value ? 1 : 0; // Directly updating enable
                        });
                      },
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            String selectedRole =
                                user.role; // Accessing role directly
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(context)!.modifyRole,
                                    style: const TextStyle(
                                      color: Color(0xFFFB8C00),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        user.name, // Accessing name directly
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        transitionBuilder: (Widget child,
                                            Animation<double> animation) {
                                          return ScaleTransition(
                                              scale: animation, child: child);
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          key: ValueKey<String>(selectedRole),
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedRole = 'manager';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    selectedRole == 'manager'
                                                        ? Colors.blueAccent
                                                        : Colors.blue[100],
                                                minimumSize: const Size(
                                                    double.infinity, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(FontAwesomeIcons.userTie,
                                                      color: selectedRole ==
                                                              'manager'
                                                          ? Colors.white
                                                          : Colors.blueAccent,
                                                      ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'manager',
                                                    style: TextStyle(
                                                      color: selectedRole ==
                                                              'manager'
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
                                                  selectedRole = 'admin';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    selectedRole == 'admin'
                                                        ? Colors.deepOrange
                                                        : Colors.orange[100],
                                                minimumSize: const Size(
                                                    double.infinity, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.admin_panel_settings,
                                                      color: selectedRole == 'admin'
                                                            ? Colors.white
                                                            : Colors.deepOrange,
                                                      ),
                                               
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'admin',
                                                    style: TextStyle(
                                                      color: selectedRole ==
                                                              'admin'
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
                                                  selectedRole = 'user';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    selectedRole == 'user'
                                                        ? Colors.green
                                                        : Colors.green[100],
                                                minimumSize: const Size(
                                                    double.infinity, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.person,
                                                      color:
                                                        selectedRole == 'user'
                                                            ? Colors.white
                                                            : Colors.green,
                                                      ),
                                                 
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'user',
                                                    style: TextStyle(
                                                      color:
                                                          selectedRole == 'user'
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
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await AdminService().updateUserRole(
                                            user.id, selectedRole, context);

                                        setState(() {
                                          user.role =
                                              selectedRole; // Directly updating role
                                        });
                                        fetchUsers(page: currentPage);
                                        Navigator.of(context).pop();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFB8C00),
                                        minimumSize: const Size(100, 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.save,
                                        style: const TextStyle(
                                            color: Colors.white),
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
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                AppLocalizations.of(context)!.confirmation,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                '${AppLocalizations.of(context)!.deleteConfirmation} ${user.name} ?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Ferme la boîte de dialogue
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await AdminService()
                                        .deleteUser(user.id, context);
                                    setState(() {
                                      users.remove(user);
                                    });
                                    Navigator.of(context)
                                        .pop(); // Ferme la boîte de dialogue
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                    style: const TextStyle(
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
              controller: _searchController,
              onChanged: (value) {
                // Rechercher et mettre à jour la liste des utilisateurs lorsqu'il y a un changement
                fetchUsers(page: currentPage);
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchUser,
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
                      fetchUsers(
                          page:
                              currentPage); // Trigger search when role changes
                    },
                    items: [
                      AppLocalizations.of(context)!.allRoles,
                      'admin',
                      'manager',
                      'user'
                    ]
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[400],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!; // Update the selected status
                      });
                      fetchUsers(
                          page:
                              currentPage); // Trigger search when status changes
                    },
                    items: [
                      AppLocalizations.of(context)!.allStates,
                      AppLocalizations.of(context)!.enabled,
                      'Disabled'
                    ]
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[400],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];

    // Couleur pour la flèche quand elle est cliquable
    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1); // 10% plus clair

    // Affichage de la flèche "Précédent"
    pageLinks.add(
      Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: prevPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: GestureDetector(
          onTap: prevPageUrl != null
              ? () {
                  setState(() {
                    currentPage--;
                  });
                  fetchUsers(
                      page:
                          currentPage); // Charge les utilisateurs pour la page précédente
                }
              : null, // Si prevPageUrl est null, on ne permet pas l'action
          child: const Icon(
            Icons.arrow_left,
            color: Colors.black,
          ),
        ),
      ),
    );
    
    // Affichage des numéros de page
for (int i = 1; i <= lastPage; i++) {
  // Check if i is within the range of currentPage - 3 to currentPage + 3
  if (i >= (currentPage - 3).clamp(1, lastPage) && i <= (currentPage + 3).clamp(1, lastPage)) {
    pageLinks.add(
      GestureDetector(
        onTap: () {
          setState(() {
            currentPage = i;
          });
          fetchUsers(page: currentPage); // Charge les utilisateurs pour la page correspondante
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: (currentPage == i) ? arrowColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Text(
            '$i',
            style: TextStyle(
              color: (currentPage == i) ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
// Affichage de la flèche "Suivant"
    pageLinks.add(
      Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: nextPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: GestureDetector(
          onTap: nextPageUrl != null
              ? () {
                  setState(() {
                    currentPage++;
                  });
                  fetchUsers(
                      page:
                          currentPage); // Charge les utilisateurs pour la page suivante
                }
              : null, // Si nextPageUrl est null, on ne permet pas l'action
          child: const Icon(
            Icons.arrow_right,
            color: Colors.black,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageLinks,
      ),
    );
  }
}
