import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/traductions.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.bakeryManagement,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      body: isBigLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFFB8C00)),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.loadingMessage),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  color: const Color(0xFFE5E7EB),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(32),
                          // padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                          child: Column(
                            children: [
                              _buildContbakeries(),
                              SizedBox(height: constraints.maxHeight * 0.015),
                              _buildFormSearch(),
                              SizedBox(height: constraints.maxHeight * 0.015),
                              _buildbakeryList(constraints),
                            ],
                          ),
                        ),
                      ),
                      _buildPagination(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildbakeryList(BoxConstraints constraints) {
    if (isLoading) {
      return const Center(
        heightFactor: 15,
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00))),
      );
    }

    if (bakeries.isEmpty) {
      return Center(
        heightFactor: 20,
        child: Text(
          AppLocalizations.of(context)!.nobakeryFound,
          style: TextStyle(
            fontSize: constraints.maxWidth < 600 ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    int crossAxisCount;
    double childAspectRatio;

    // Déterminer le crossAxisCount en fonction de la largeur de l'écran
    if (constraints.maxWidth < 600) {
      crossAxisCount = 1; // Téléphone
      childAspectRatio =
          (constraints.maxWidth / 1) / (constraints.maxHeight * 0.58);
    } else if (constraints.maxWidth < 900) {
      crossAxisCount = 2; // Tablette
      childAspectRatio =
          (constraints.maxWidth / 2) / (constraints.maxHeight * 0.58);
    } else if (constraints.maxWidth < 1200) {
      crossAxisCount = 3; // Web
      childAspectRatio =
          (constraints.maxWidth / 3) / (constraints.maxHeight * 0.6);
    } else {
      crossAxisCount = 4; // TV
      childAspectRatio =
          (constraints.maxWidth / 4) / (constraints.maxHeight * 0.6);
    }

    // S'assurer que le childAspectRatio reste dans des limites raisonnables
    childAspectRatio = childAspectRatio.clamp(0.5, 1.5);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: constraints.maxWidth * 0.02,
        mainAxisSpacing: constraints.maxHeight * 0.015,
        childAspectRatio:
            childAspectRatio, // Utiliser la valeur calculée dynamiquement
      ),
      itemCount: bakeries.length,
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(16.0),
          // padding: EdgeInsets.all(constraints.maxWidth * 0.03),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PageAccueilBakery(bakery: bakeries[index], products_selected: {},)),
            ),
            child: _ShowinfoBakery(bakeries[index], constraints),
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
        Stack(
          children: [
            CachedNetworkImage(
              imageUrl: ApiConfig.changePathImage(bakery.image ?? ''),
              width: double.infinity,
              height: constraints.maxHeight * 0.3, // Reduced image height
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) => Center(
                child: CircularProgressIndicator(
                  value: progress.progress,
                  color: const Color(0xFFFB8C00),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.store, size: 40), // Smaller icon
              ),
              imageBuilder: (context, imageProvider) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4), // Smaller padding
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(1, 1)),
                  ],
                ),
                child: Text(
                  isOpen
                      ? AppLocalizations.of(context)!.open
                      : AppLocalizations.of(context)!.closed,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: constraints.maxHeight * 0.01),
        Text(
          bakery.name.toUpperCase(),
          style: TextStyle(
            fontSize: constraints.maxWidth < 600 ? 12 : 14, // Smaller font
            fontWeight: FontWeight.bold,
            color: const Color(0xFF795548),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        if (bakery.street != null && bakery.street != '')
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Colors.grey, size: 16), // Smaller icon
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    bakery.street ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey), // Smaller font
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RatingStars(
              value: bakery.avgRating ?? 0.0,
              starBuilder: (index, color) =>
                  Icon(Icons.star, color: color, size: 14), // Smaller stars
              starCount: 5,
              starSize: 14,
              valueLabelVisibility: false, // Hide value label to save space
              maxValue: 5,
              starSpacing: 1,
              starOffColor: const Color(0xffe7e8ea),
              starColor: Colors.yellow,
            ),
            const SizedBox(width: 4),
            Text(
              '(${bakery.ratingsCount.toString()})',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async{
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PageRatingBakery(bakery: bakery),
                  ),
                );
                _initializeData();
              },
              child: Row(
                children: [
                   Icon(Icons.star,
                      color: Colors.white, size: 14), // Smaller icon
                   Text(
                    'Évaluer', // Shortened text
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB8C00),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2), // Smaller button
                // minimumSize: const Size(0, 0), // Allow smaller size
              ),
            ),
          ],
        ),
        SizedBox(height: constraints.maxHeight * 0.005),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time,
                    color: Colors.grey, size: 14), // Smaller icon
                const SizedBox(width: 4),
                Text(
                  "${getOpeningHours(bakery, 'start') ?? '-'} - ${getOpeningHours(bakery, 'end') ?? '-'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city,
                    color: Colors.grey, size: 14), // Smaller icon
                const SizedBox(width: 4),
                Text(
                  '${bakery.distance?.toStringAsFixed(2) ?? '-'} km',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String? getOpeningHours(Bakery bakery, String key) {
    try {
      Map<String, dynamic> storedHours =
          jsonDecode(bakery.openingHours);
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

  Widget _buildPagination() {
    List<Widget> pageLinks = [];
    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1);

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
                  setState(() => currentPage--);
                  fetchbakeries(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_left, color: Colors.black),
        ),
      ),
    );

    for (int i = 1; i <= lastPage; i++) {
      if (i >= currentPage - 3 && i <= currentPage + 3) {
        pageLinks.add(
          GestureDetector(
            onTap: () {
              setState(() => currentPage = i);
              fetchbakeries(page: currentPage);
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
                  setState(() => currentPage++);
                  fetchbakeries(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_right, color: Colors.black),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center, children: pageLinks),
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
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchbakery,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                bool isSmallScreen = constraints.maxWidth < 600;
                return isSmallScreen
                    ? Column(
                        children: [
                          _buildDropdown(subAdministrativeArea, (value) {
                            setState(() => subAdministrativeArea = value!);
                            fetchbakeries();
                          }, constraints),
                          const SizedBox(height: 10),
                          _buildDropdown(administrativeArea, (value) {
                            setState(() => administrativeArea = value!);
                            fetchbakeries();
                          }, constraints),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child:
                                _buildDropdown(subAdministrativeArea, (value) {
                              setState(() => subAdministrativeArea = value!);
                              fetchbakeries();
                            }, constraints),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdown(administrativeArea, (value) {
                              setState(() => administrativeArea = value!);
                              fetchbakeries();
                            }, constraints),
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
          const DropdownMenuItem(
              value: 'Loading...', child: Text('Loading...')),
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[400],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
      ),
    );
  }

  Widget _buildContbakeries() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.total_bakeries,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            total.toString(),
            style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
