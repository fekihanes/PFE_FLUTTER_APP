import 'package:flutter/material.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/RoleWidget.dart';
import 'package:flutter_application/classes/Paginated/PaginatedUserResponse.dart';
import 'package:flutter_application/custom_widgets/user_role_dialog.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/manager/managment_employees.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
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

    PaginatedUserResponse? response = await ManagementEmployeesService().searchUsers(
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
      BakeryService().havebakery(context);
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
          AppLocalizations.of(context)!.adding_employees,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContUsers(),
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

  Widget _buildContUsers() {
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
            AppLocalizations.of(context)!.totalUsers,
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
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: Colors.black),
                  onPressed: (){
                    showUserRoleDialog(context, user, fetchUsers, currentPage);
                  }
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
