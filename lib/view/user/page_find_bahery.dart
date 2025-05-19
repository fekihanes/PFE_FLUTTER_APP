import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_user.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/LocationService.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/users/bakeries_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/user/passe_commandes/page_Accueil_bakery.dart';
import 'package:flutter_application/view/user/page_rating_bakery.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';

class PageFindBahery extends StatefulWidget {
  const PageFindBahery({super.key});

  @override
  State<PageFindBahery> createState() => _PageFindBaheryState();
}

class _PageFindBaheryState extends State<PageFindBahery> {
  List<Bakery> bakeries = [];
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  bool isLoading = false;
  bool isBigLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  late TextEditingController _searchController;
  String? latitude;
  String? longitude;
  String? subAdministrativeArea;
  String? administrativeArea;
  Timer? _debounceTimer;
  late bool isWebLayout;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController = TextEditingController();
  }

  void _initializeData() async {
    if (!mounted) return;
    setState(() => isBigLoading = true);
    try {
      await get_data();
      if (mounted) await fetchbakeries();
    } finally {
      if (mounted) setState(() => isBigLoading = false);
    }
  }

  Future<void> get_data() async {
    try {
      Position? position = await LocationService.getCurrentPosition();
      if (position == null || !mounted) return;

      final addressDetails = await LocationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
        subAdministrativeArea =
            addressDetails["subAdministrativeArea"] ?? 'Unknown area';
        administrativeArea =
            addressDetails["administrativeArea"] ?? 'Unknown region';
      });
    } catch (e) {
      if (mounted) {
        Customsnackbar()
            .showErrorSnackbar(context, "Location error: ${e.toString()}");
      }
    }
  }

  Future<void> fetchbakeries({int page = 1}) async {
    setState(() => isLoading = true);
    final response = await BakeriesService().BakeryGeoLocator(
      context,
      page,
      _searchController.text.trim(),
      latitude ?? '0',
      longitude ?? '0',
      subAdministrativeArea ?? '',
      administrativeArea ?? '',
    );
    setState(() {
      isLoading = false;
      if (response != null) {
        bakeries = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        total = response.total;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
      } else {
        bakeries = [];
        currentPage = 1;
        lastPage = 1;
        total = 0;
        prevPageUrl = null;
        nextPageUrl = null;
        Customsnackbar().showErrorSnackbar(context, "Failed to load bakeries.");
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

  Future<bool> _onBackPressed() async {
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      fetchbakeries(page: currentPage);
    });
  }

  Widget _buildbakeryList(BoxConstraints constraints) {
    if (isLoading) {
      return Container(
        height: constraints.maxHeight * 0.5,
        margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.03),
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

    if (bakeries.isEmpty) {
      return Container(
        height: constraints.maxHeight * 0.5,
        margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.03),
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
            AppLocalizations.of(context)!.nobakeryFound,
            style: TextStyle(
              fontSize: constraints.maxWidth > 1200
                  ? 20
                  : (constraints.maxWidth > 600 ? 18 : 16),
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    int crossAxisCount;
    if (constraints.maxWidth < 600) {
      crossAxisCount = 1;
    } else if (constraints.maxWidth < 900) {
      crossAxisCount = 2;
    } else if (constraints.maxWidth < 1200) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth * 0.03,
        vertical: constraints.maxHeight * 0.01,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: constraints.maxWidth * 0.02,
        mainAxisSpacing: constraints.maxHeight * 0.015,
      ),
      itemCount: bakeries.length,
      itemBuilder: (context, index) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxWidth < 600 ? 300 : 350,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PageAccueilBakery(
                    bakery: bakeries[index],
                    products_selected: {},
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _ShowinfoBakery(bakeries[index], constraints),
              ),
            ),
          ),
        );
      },
    );
  }

  bool showetap(String start, String end) {
    TimeOfDay startTime = _parseTimeOfDay(start);
    TimeOfDay endTime = _parseTimeOfDay(end);
    TimeOfDay timeNow = TimeOfDay.now();
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;
    int nowMinutes = timeNow.hour * 60 + timeNow.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  Widget _ShowinfoBakery(Bakery bakery, BoxConstraints constraints) {
    bool isOpen = showetap(
      getOpeningHours(bakery, 'start') ?? '00:00',
      getOpeningHours(bakery, 'end') ?? '00:00',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: ApiConfig.changePathImage(bakery.image ?? ''),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, progress) => Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                    color: const Color(0xFFFB8C00),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.store,
                    size: constraints.maxWidth > 1200 ? 40 : (constraints.maxWidth > 600 ? 35 : 30),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 8 : 6,
                    vertical: constraints.maxWidth > 600 ? 4 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    isOpen ? AppLocalizations.of(context)!.open : AppLocalizations.of(context)!.closed,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxWidth > 600 ? 12 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 16.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  bakery.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: constraints.maxWidth > 600 ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF795548),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bakery.street != null && bakery.street != '')
                  Row(
                    children: [
                      Icon(Icons.location_on, size: constraints.maxWidth > 600 ? 14 : 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bakery.street ?? '',
                          style: TextStyle(fontSize: constraints.maxWidth > 600 ? 12 : 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    RatingStars(
                      value: bakery.avgRating ?? 0.0,
                      starSize: constraints.maxWidth > 600 ? 14 : 12,
                      starBuilder: (index, color) => Icon(Icons.star, color: color, size: constraints.maxWidth > 600 ? 14 : 12),
                      starCount: 5,
                      valueLabelVisibility: false,
                      maxValue: 5,
                      starSpacing: 1,
                      starOffColor: const Color(0xffe7e8ea),
                      starColor: Colors.yellow,
                    ),
                    const Spacer(),
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          backgroundColor: const Color(0xFFFB8C00),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: FittedBox(
                          child: Row(
                            children: [
                              Icon(Icons.star, size: constraints.maxWidth > 600 ? 14 : 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Évaluer',
                                style: TextStyle(fontSize: constraints.maxWidth > 600 ? 12 : 10, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PageRatingBakery(bakery: bakery)),
                          );
                          _initializeData();
                        },
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    _buildInfoRow(
                      Icons.access_time,
                      "${getOpeningHours(bakery, 'start')} - ${getOpeningHours(bakery, 'end')}",
                      constraints,
                    ),
                    _buildInfoRow(
                      Icons.location_city,
                      '${bakery.distance?.toStringAsFixed(3)} km',
                      constraints,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, BoxConstraints constraints) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: constraints.maxWidth > 600 ? 14 : 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: constraints.maxWidth > 600 ? 12 : 10),
        ),
      ],
    );
  }

  String? getOpeningHours(Bakery bakery, String key) {
    try {
      Map<String, dynamic> storedHours = jsonDecode(bakery.openingHours);
      DateTime now = DateTime.now();
      String searchDay = Traductions().getEnglishDayName(now);
      late Map<String, dynamic> openingHours = {};

      storedHours.forEach((day, data) {
        openingHours[day] = {
          'start': _convertToHHMM(data['start'] ?? '08:00'),
          'end': _convertToHHMM(data['end'] ?? '17:00'),
          'deadline': _convertToHHMM(data['deadline'] ?? '16:00'),
        };
      });

      if (openingHours.containsKey(searchDay) &&
          openingHours[searchDay]!.containsKey(key)) {
        return openingHours[searchDay][key];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  String _convertToHHMM(String time) {
    try {
      TimeOfDay parsed = _parseTimeOfDay(time);
      return "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '00:00';
    }
  }

  Widget _buildPagination(BoxConstraints constraints) {
    List<Widget> pageLinks = [];
    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1);

    pageLinks.add(
      Container(
        padding: EdgeInsets.all(
            constraints.maxWidth > 1200 ? 10.0 : (isWebLayout ? 8.0 : 6.0)),
        margin: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 1200 ? 6.0 : (isWebLayout ? 4.0 : 3.0)),
        decoration: BoxDecoration(
          color: prevPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: prevPageUrl != null
              ? () {
                  setState(() => currentPage--);
                  fetchbakeries(page: currentPage);
                }
              : null,
          child: Icon(Icons.arrow_left,
              size: constraints.maxWidth > 1200
                  ? 28
                  : (isWebLayout ? 24 : 20),
              color: Colors.black),
        ),
      ),
    );

    for (int i = 1; i <= lastPage; i++) {
      if (i >= currentPage - 3 && i <= currentPage + 3) {
        pageLinks.add(
          Container(
            padding: EdgeInsets.all(
                constraints.maxWidth > 1200 ? 10.0 : (isWebLayout ? 8.0 : 6.0)),
            margin: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth > 1200 ? 6.0 : (isWebLayout ? 4.0 : 3.0)),
            decoration: BoxDecoration(
              color: currentPage == i ? arrowColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(5.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                setState(() => currentPage = i);
                fetchbakeries(page: currentPage);
              },
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: constraints.maxWidth > 1200
                      ? 18
                      : (isWebLayout ? 16 : 14),
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
        padding: EdgeInsets.all(
            constraints.maxWidth > 1200 ? 10.0 : (isWebLayout ? 8.0 : 6.0)),
        margin: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 1200 ? 6.0 : (isWebLayout ? 4.0 : 3.0)),
        decoration: BoxDecoration(
          color: nextPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: nextPageUrl != null
              ? () {
                  setState(() => currentPage++);
                  fetchbakeries(page: currentPage);
                }
              : null,
          child: Icon(Icons.arrow_right,
              size: constraints.maxWidth > 1200
                  ? 28
                  : (isWebLayout ? 24 : 20),
              color: Colors.black),
        ),
      ),
    );

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageLinks,
      ),
    );
  }

  Widget _buildFormSearch(BoxConstraints constraints) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.03),
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
        padding: EdgeInsets.all(isWebLayout ? 12.0 : 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchbakery,
                prefixIcon: Icon(Icons.search,
                    size: constraints.maxWidth > 1200
                        ? 28
                        : (isWebLayout ? 24 : 20),
                    color: Colors.black),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                labelStyle: TextStyle(
                    fontSize: constraints.maxWidth > 1200
                        ? 18
                        : (isWebLayout ? 16 : 14)),
              ),
            ),
            SizedBox(height: isWebLayout ? 10 : 8),
            LayoutBuilder(
              builder: (context, innerConstraints) {
                bool isSmallScreen = innerConstraints.maxWidth < 600;
                return isSmallScreen
                    ? Column(
                        children: [
                          _buildDropdown(subAdministrativeArea, (value) {
                            setState(() => subAdministrativeArea = value!);
                            fetchbakeries();
                          }, innerConstraints),
                          SizedBox(height: isWebLayout ? 10 : 8),
                          _buildDropdown(administrativeArea, (value) {
                            setState(() => administrativeArea = value!);
                            fetchbakeries();
                          }, innerConstraints),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(subAdministrativeArea, (value) {
                              setState(() => subAdministrativeArea = value!);
                              fetchbakeries();
                            }, innerConstraints),
                          ),
                          SizedBox(width: isWebLayout ? 10 : 8),
                          Expanded(
                            child: _buildDropdown(administrativeArea, (value) {
                              setState(() => administrativeArea = value!);
                              fetchbakeries();
                            }, innerConstraints),
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String? value, Function(String?) onChanged, BoxConstraints constraints) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: [
        if (value != null)
          DropdownMenuItem(value: value, child: Text(value))
        else
          DropdownMenuItem(
              value: 'Loading...',
              child: Text('Loading...',
                  style: TextStyle(
                      fontSize: constraints.maxWidth > 1200
                          ? 16
                          : (isWebLayout ? 14 : 12)))),
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[400],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
        contentPadding: EdgeInsets.symmetric(
            horizontal: isWebLayout ? 12 : 8, vertical: isWebLayout ? 8 : 6),
        labelStyle: TextStyle(
            fontSize: constraints.maxWidth > 1200
                ? 16
                : (isWebLayout ? 14 : 12)),
      ),
      style: TextStyle(
          fontSize: constraints.maxWidth > 1200
              ? 16
              : (isWebLayout ? 14 : 12)),
    );
  }

  Widget _buildContbakeries(BoxConstraints constraints) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.03),
      padding: EdgeInsets.all(isWebLayout ? 16.0 : 12.0),
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
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.total_bakeries,
              style: TextStyle(
                color: Colors.grey,
                fontSize: constraints.maxWidth > 1200
                    ? 18
                    : (isWebLayout ? 16 : 14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: isWebLayout ? 10 : 8),
          Text(
            total.toString(),
            style: TextStyle(
              color: Colors.black,
              fontSize: constraints.maxWidth > 1200
                  ? 26
                  : (isWebLayout ? 24 : 20),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFromMobile() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.01),
          children: [
            _buildContbakeries(constraints),
            SizedBox(height: constraints.maxHeight * 0.012),
            _buildFormSearch(constraints),
            SizedBox(height: constraints.maxHeight * 0.012),
            _buildbakeryList(constraints),
            SizedBox(height: constraints.maxHeight * 0.02),
            _buildPagination(constraints),
          ],
        );
      },
    );
  }

  Widget buildFromWeb() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.01),
          children: [
            _buildContbakeries(constraints),
            SizedBox(height: constraints.maxHeight * 0.015),
            _buildFormSearch(constraints),
            SizedBox(height: constraints.maxHeight * 0.015),
            _buildbakeryList(constraints),
            SizedBox(height: constraints.maxHeight * 0.02),
            _buildPagination(constraints),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.bakeryManagement,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
    
      ),
      drawer: CustomDraweruser(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isBigLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFB8C00)),
                    SizedBox(height: isWebLayout ? 20 : 16),
                    Text(
                      AppLocalizations.of(context)!.loadingMessage,
                      style: TextStyle(
                          fontSize: isWebLayout ? 16 : 14),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return isWebLayout ? buildFromWeb() : buildFromMobile();
                },
              ),
      ),
    );
  }
}