import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/RoleWidget.dart';
import 'package:flutter_application/custom_widgets/user_role_dialog.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/classes/Paginated/PaginatedUserResponse.dart';
import 'package:flutter_application/services/manager/managment_employees.dart';
import 'package:flutter_application/view/manager/employee/Add_Employee_page.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
import 'package:flutter_application/view/manager/employee/ManagerCashierSalesPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> fetchUsers({int page = 1}) async {
    print('fetchUsers: Fetching employees for page $page, query: ${_searchController.text.trim()}');
    setState(() {
      isLoading = true;
    });

    PaginatedUserResponse? response =
        await ManagementEmployeesService().searchemployees(
      context,
      query: _searchController.text.trim(),
      page: page,
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      print('fetchUsers: Fetched ${response.data.length} employees, total: ${response.total}');
      setState(() {
        users = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        total = response.total;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
      });
    } else {
      print('fetchUsers: No employees found');
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
    print('initState: Initializing HomePageManager');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('initState: Checking bakery existence');
      BakeryService().havebakery(context);
    });
    fetchUsers();
  }

  @override
  void dispose() {
    print('dispose: Disposing HomePageManager');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    print('build: Rendering with isWebLayout: $isWebLayout');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.employeeManagement,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          NotificationIcon(),
          SizedBox(width: 8),
        ],
      ),
      drawer: const CustomDrawerManager(),
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    print('buildFromMobile: Building mobile layout');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildContEmployee(),
                  const SizedBox(height: 16),
                  _buildInput(),
                  const SizedBox(height: 16),
                  _buildListEmployee(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    print('buildFromWeb: Building web layout');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildContEmployee(),
                  const SizedBox(height: 24),
                  _buildInput(),
                  const SizedBox(height: 24),
                  _buildListEmployee(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildContEmployee() {
    print('_buildContEmployee: Building total employees container, total: $total');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
      ),
    );
  }

  Widget _buildInput() {
    print('_buildInput: Building search input');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
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
            print('_buildInput: Search query changed: $value');
            fetchUsers();
          },
        ),
      ),
    );
  }

  Widget _buildListEmployee() {
    print('_buildListEmployee: Building employee list, isLoading: $isLoading, user count: ${users.length}');
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        height: 300,
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
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        height: 300,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 300,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return GestureDetector(
              onTap: user.role == 'caissier'
                  ? () async {
                      print('_buildListEmployee: Navigating to CashierSalesPage for user: ${user.name}');
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final bakeryId = prefs.getString('my_bakery');
                
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ManagerCashierSalesPage(
                              bakeryId: bakeryId!,
                              employeeId: user.id.toString(),
                            ),
                          ),
                        );
                     
                    }
                  :null,
                  
              child: Container(
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
                    ClipOval(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: user.userPicture != null &&
                                user.userPicture!.isNotEmpty
                            ? Image.network(
                                ApiConfig.changePathImage(user.userPicture!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFFB8C00)),
                                    ),
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
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
                        const SizedBox(height: 8),
                        RoleWidget(role: user.role),
                        const SizedBox(height: 8),
                        if (user.role == 'special_customer') ...[
                          DropdownButton<String>(
                            value: user.selected_price,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                print(
                                    '_buildListEmployee: Updating selected price for ${user.name} to $newValue');
                                setState(() {
                                  user.selected_price = newValue;
                                });
                                ManagementEmployeesService().update_selected_price(
                                    user.id, newValue, context);
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'gros',
                                child: Text(AppLocalizations.of(context)!.price_gros),
                              ),
                              DropdownMenuItem(
                                value: 'details',
                                child: Text(AppLocalizations.of(context)!.price_details),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                      onPressed: () {
                        print('_buildListEmployee: Opening role dialog for user: ${user.name}');
                        showUserRoleDialog(context, user, fetchUsers, currentPage);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPagination() {
    print('_buildPagination: Building pagination, currentPage: $currentPage, lastPage: $lastPage');
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: prevPageUrl != null
                  ? const Color(0xFFFB8C00)
                  : const Color(0xFFFB8C00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: GestureDetector(
              onTap: prevPageUrl != null
                  ? () {
                      print('_buildPagination: Navigating to previous page: ${currentPage - 1}');
                      setState(() {
                        currentPage--;
                      });
                      fetchUsers(page: currentPage);
                    }
                  : null,
              child: const Icon(
                Icons.arrow_left,
                color: Colors.black,
              ),
            ),
          ),
          for (int i = 1; i <= lastPage; i++)
            if (i >= (currentPage - 3).clamp(1, lastPage) &&
                i <= (currentPage + 3).clamp(1, lastPage))
              GestureDetector(
                onTap: () {
                  print('_buildPagination: Navigating to page: $i');
                  setState(() {
                    currentPage = i;
                  });
                  fetchUsers(page: currentPage);
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: (currentPage == i)
                        ? const Color(0xFFFB8C00)
                        : Colors.grey[300],
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
          Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: nextPageUrl != null
                  ? const Color(0xFFFB8C00)
                  : const Color(0xFFFB8C00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: GestureDetector(
              onTap: nextPageUrl != null
                  ? () {
                      print('_buildPagination: Navigating to next page: ${currentPage + 1}');
                      setState(() {
                        currentPage++;
                      });
                      fetchUsers(page: currentPage);
                    }
                  : null,
              child: const Icon(
                Icons.arrow_right,
                color: Colors.black,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFB8C00),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              print('_buildPagination: Navigating to AddEmployeePage');
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => AddEmployeePage()));
              fetchUsers();
            },
          ),
        ],
      ),
    );
  }
}