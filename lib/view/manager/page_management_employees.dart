import 'package:flutter/material.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/RoleWidget.dart';
import 'package:flutter_application/services/manager/manager_service.dart';
import 'package:flutter_application/classes/Paginated/PaginatedUserResponse.dart';
import 'package:flutter_application/services/manager/managment_employees.dart';
import 'package:flutter_application/view/manager/Add_Employee_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePageManager extends StatefulWidget {
  const HomePageManager({super.key});

  @override
  State<HomePageManager> createState() => _HomePageManagerState();
}

class _HomePageManagerState extends State<HomePageManager> {
  List<UserClass> users = [];
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  bool isLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  final TextEditingController _searchController = TextEditingController();

  // Cette méthode fetchUsers prend en charge la recherche avec les filtres
  Future<void> fetchUsers({int page = 1}) async {
    setState(() {
      isLoading = true;
    });

    PaginatedUserResponse? response = await ManagementEmployeesService().searchemployees(
      context,
      query: _searchController.text.trim(),
      page: page,
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      setState(() {
        users = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        total = response.total;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
      });
    } else {
      setState(() {
        users = [];
        currentPage = 1;
        lastPage = 1;
        total = 0;
        prevPageUrl = null;
        nextPageUrl = null;
      });
    }
  }



  @override
  void initState() {
    super.initState();    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ManagerService().havebakery(context);
    });
    fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.employeeManagement,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
      ),
      drawer: const CustomDrawerManager(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContEmployee(),
            const SizedBox(height: 20),
            _buildInput(),
            const SizedBox(height: 20),
            _buildListEmployee(),
            _buildPagination(), // Added pagination
          ],
        ),
      ),
    );
  }

  Widget _buildContEmployee() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.totalEmployees,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Removed `const` here as total.toString() is a runtime operation
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchByEmail,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) {
        fetchUsers(); // Re-fetch users on search input change
      },
    );
  }

  Widget _buildListEmployee() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noUserFound,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(user.userPicture ?? ''),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    RoleWidget(role: user.role),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        String selectedRole = user.role;
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
                                    duration: const Duration(milliseconds: 500),
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
                                              selectedRole = 'patissier';
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                selectedRole == 'patissier'
                                                    ? Colors.blueAccent
                                                    : Colors.blue[100],
                                            minimumSize:
                                                const Size(double.infinity, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.cake,
                                                color:
                                                    selectedRole == 'patissier'
                                                        ? Colors.white
                                                        : Colors.blueAccent,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                Traductions().traductionrole(context, 'patissier'), // Use translation
                                                style: TextStyle(
                                                  color: selectedRole == 'patissier'
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
                                              selectedRole = 'boulanger';
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                selectedRole == 'boulanger'
                                                    ? const Color(0xFF795548)
                                                    : const Color(0xFF795548)
                                                        .withOpacity(0.1),
                                            minimumSize:
                                                const Size(double.infinity, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(FontAwesomeIcons.breadSlice,
                                                  color: selectedRole == 'boulanger'
                                                      ? Colors.white
                                                      : const Color(0xFF795548)),
                                              const SizedBox(width: 10),
                                              Text(
                                                Traductions().traductionrole(context, 'boulanger'), // Use translation
                                                style: TextStyle(
                                                  color: selectedRole == 'boulanger'
                                                      ? Colors.white
                                                      : const Color(0xFF795548),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedRole = 'caissier';
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                selectedRole == 'caissier'
                                                    ? Colors.deepOrange
                                                    : Colors.orange[100],
                                            minimumSize:
                                                const Size(double.infinity, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.monetization_on,
                                                color:
                                                    selectedRole == 'caissier'
                                                        ? Colors.white
                                                        : Colors.deepOrange,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                Traductions().traductionrole(context, 'caissier'), // Use translation
                                                style: TextStyle(
                                                  color: selectedRole == 'caissier'
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
                                              selectedRole = 'livreur';
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                selectedRole == 'livreur'
                                                    ? Colors.purple
                                                    : Colors.purple[100],
                                            minimumSize:
                                                const Size(double.infinity, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.local_shipping,
                                                color: selectedRole == 'livreur'
                                                    ? Colors.white
                                                    : Colors.purple,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                Traductions().traductionrole(context, 'livreur'), // Use translation
                                                style: TextStyle(
                                                  color: selectedRole == 'livreur'
                                                      ? Colors.white
                                                      : Colors.purple,
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
                                            minimumSize:
                                                const Size(double.infinity, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person,
                                                color: selectedRole == 'user'
                                                    ? Colors.white
                                                    : Colors.green,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                Traductions().traductionrole(context, 'user'), // Use translation
                                                style: TextStyle(
                                                  color: selectedRole == 'user'
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
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await ManagementEmployeesService().updateUserRole(
                                        user.id, selectedRole, context);
                                    fetchUsers(page: currentPage);
                                    setState(() {
                                      user.role =
                                          selectedRole; // Directly updating role
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
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];

    // Couleur pour la flèche quand elle est cliquable
    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1); // 10% plus clair
    pageLinks.add(const Spacer()); // Affichage de la flèche "Précédent"
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
      if (i >= (currentPage - 3).clamp(1, lastPage) &&
          i <= (currentPage + 3).clamp(1, lastPage)) {
        pageLinks.add(
          GestureDetector(
            onTap: () {
              setState(() {
                currentPage = i;
              });
              fetchUsers(
                  page:
                      currentPage); // Charge les utilisateurs pour la page correspondante
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
    pageLinks.add(const Spacer());
    pageLinks.add(IconButton(
      icon: Container(
        width: 50, // Set the width of the container
        height: 50, // Set the height of the container
        decoration: BoxDecoration(
          color: const Color(0xFFFB8C00), // Background color
          borderRadius: BorderRadius.circular(8), // Rounded border
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.5), // Shadow color (adjust opacity)
              spreadRadius: 2, // Spread of the shadow
              blurRadius: 5, // Blur radius
              offset: const Offset(0, 3), // Shadow position
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      onPressed: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => AddEmployeePage()));
        fetchUsers();
      },
    ));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  pageLinks, // Utilisation correcte de la liste de widgets
            ),
          ),
        ],
      ),
    );
  }
}
