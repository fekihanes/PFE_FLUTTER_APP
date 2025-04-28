import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Paginated/PaginatedUserResponse.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/services/manager/managment_employees.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application/services/emloyees/InvoiceService.dart';
import 'package:intl/intl.dart';

class PageFactureParMois extends StatefulWidget {
  const PageFactureParMois({super.key});

  @override
  State<PageFactureParMois> createState() => _PageFactureParMoisState();
}

class _PageFactureParMoisState extends State<PageFactureParMois> {
  List<UserClass> users = [];
  List<UserClass> specialCustomers = [];
  bool isLoading = false;
  bool isBigLoading = false;
  int totalUsers = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  String? prevPageUrl;
  String? nextPageUrl;
  UserClass? selectedUser;
  UserClass? dropdownValue;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    if (!mounted) return;
    setState(() => isBigLoading = true);
    try {
      await Future.wait([
        fetchUsers(),
        _fetchSpecialCustomers(),
      ]);
    } finally {
      if (mounted) setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchUsers({int page = 1}) async {
    setState(() {
      isLoading = true;
    });

    PaginatedUserResponse? response =
        await ManagementEmployeesService().searchUsers(
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
        totalUsers = response.total;
      });
    } else {
      setState(() {
        users = [];
        currentPage = 1;
        lastPage = 1;
        total = 0;
        prevPageUrl = null;
        nextPageUrl = null;
        totalUsers = 0;
      });
    }
  }

  Future<void> _fetchSpecialCustomers() async {
    try {
      final customers = await ManagementEmployeesService().getSpecialCustomerUsers(context);
      if (mounted) {
        setState(() {
          specialCustomers = (customers as List<UserClass>?) ?? [];
          dropdownValue = null; // No automatic selection
          selectedUser = null;
        });
      }
    } catch (e) {
      if (mounted) {
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && context.mounted) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isStartDate) {
          _dateDebutController.text = formattedDate;
        } else {
          _dateFinController.text = formattedDate;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const CustomDrawerManager(),
      body: isBigLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.monthlyInvoice,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFB8C00)),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.loadingMessage),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: Column(
        children: [
          _buildInput(),
          _buildDateInput(),
          const SizedBox(height: 8),
          Expanded(
            child: _buildUserList(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
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
              onChanged: (value) => fetchUsers(page: 1),
            ),
          ),
          const SizedBox(width: 8),
Expanded(
  flex: 1,
  child: DropdownButtonFormField<UserClass?>(
    value: dropdownValue,
    hint: Text(
      AppLocalizations.of(context)!.selectCustomer,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 16,
      ),
    ),
    items: [
      // "No one selected" option
      DropdownMenuItem<UserClass?>(
        value: null,
        child: Text(
          AppLocalizations.of(context)!.noOneSelected,
          style: const TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      // User options
      ...specialCustomers.map((UserClass user) {
        return DropdownMenuItem<UserClass?>(
          value: user,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }).toList(),
    ],
    onChanged: (UserClass? newValue) {
      setState(() {
        dropdownValue = newValue;
        selectedUser = newValue;
      });
    },
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    style: const TextStyle(
      color: Colors.black,
      fontSize: 16,
    ),
    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
    dropdownColor: Colors.white,
    elevation: 2,
    borderRadius: BorderRadius.circular(12),
    isExpanded: true,
  ),
),
        ],
      ),
    );
  }

  Widget _buildDateInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _dateDebutController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.startDate,
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onTap: () => _selectDate(context, true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _dateFinController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.endDate,
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onTap: () => _selectDate(context, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (users.isEmpty && !isLoading) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noUsersFound,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      selectedUser = user;
                      dropdownValue = specialCustomers.contains(user) ? user : null;
                    });
                  },
                ),
              );
            },
          );
  }

  Widget _buildPagination() {
    return Column(
      children: [
        _buildPageLinks(),
        if (selectedUser != null)
          SizedBox(
            height: 200,
            child: _buildSelectedUserInfo(
              context: context,
              selectedUser: selectedUser!,
              dateDebutController: _dateDebutController,
              dateFinController: _dateFinController,
            ),
          ),
      ],
    );
  }

  Widget _buildPageLinks() {
    List<Widget> pageLinks = [];

    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.3);

    pageLinks.add(const Spacer());
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
                  fetchUsers(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_left, color: Colors.black),
        ),
      ),
    );

    for (int i = 1; i <= lastPage; i++) {
      if (i >= (currentPage - 3).clamp(1, lastPage) &&
          i <= (currentPage + 3).clamp(1, lastPage)) {
        pageLinks.add(
          GestureDetector(
            onTap: () {
              setState(() {
                currentPage = i;
              });
              fetchUsers(page: currentPage);
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: currentPage == i ? arrowColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: currentPage == i ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }

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
                  fetchUsers(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_right, color: Colors.black),
        ),
      ),
    );
    pageLinks.add(const Spacer());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pageLinks,
    );
  }

  Widget _buildSelectedUserInfo({
    required BuildContext context,
    required UserClass selectedUser,
    required TextEditingController dateDebutController,
    required TextEditingController dateFinController,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectedUser,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserInfoRow(
                            icon: FontAwesomeIcons.user,
                            label: AppLocalizations.of(context)!.name,
                            value: selectedUser.name,
                          ),
                          const SizedBox(height: 8),
                          _buildUserInfoRow(
                            icon: FontAwesomeIcons.envelope,
                            label: AppLocalizations.of(context)!.email,
                            value: selectedUser.email,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildGenerateButton(context, selectedUser),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(icon, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context, UserClass selectedUser) {
    return ElevatedButton.icon(
      icon: const FaIcon(FontAwesomeIcons.fileInvoice, color: Colors.white),
      label: Text(
        AppLocalizations.of(context)!.generateInvoice,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: _dateDebutController.text.isEmpty ||
              _dateFinController.text.isEmpty ||
              selectedUser == null
          ? null
          : () async {
              try {
                final invoice = await InvoiceService().generateInvoiceParMois(
                  context: context,
                  userId: selectedUser.id,
                  dateDebut: _dateDebutController.text,
                  dateFin: _dateFinController.text,
                );
                if (invoice != null && context.mounted) {
                  await InvoiceService().printInvoice(
                    context: context,
                    invoiceId: invoice['invoice_id'],
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${AppLocalizations.of(context)!.errorOccurred}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
    );
  }
}