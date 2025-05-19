import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Descriptions.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/users/RatingService.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PageRatingBakery extends StatefulWidget {
  final Bakery bakery;
  const PageRatingBakery({required this.bakery, super.key});

  @override
  State<PageRatingBakery> createState() => _PageRatingBakeryState();
}

class _PageRatingBakeryState extends State<PageRatingBakery> {
  late Descriptions? myDescription;
  List<Descriptions> descriptions = [];
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  bool isLoading = false;
  bool isBigLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  late TextEditingController _descriptionController;
  int _userRating = 0;
  late bool isWebLayout;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _initializeData();
  }

  void _initializeData() async {
    if (!mounted) return;
    setState(() => isBigLoading = true);
    try {
      if (mounted) {
        await fetchdescriptions();
        myDescription = await RatingService()
            .getMyrate(context, widget.bakery.id.toString());
        if (myDescription != null) {
          _userRating = myDescription!.rate ?? 0;
          _descriptionController.text = myDescription!.description ?? '';
        }
      }
    } finally {
      if (mounted) setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchdescriptions({int page = 1}) async {
    setState(() => isLoading = true);
    final response = await RatingService().getRateBakery(
      context,
      page,
      widget.bakery.id.toString(),
    );
    setState(() {
      isLoading = false;
      if (response != null) {
        descriptions = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        total = response.total;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
      } else {
        descriptions = [];
        currentPage = 1;
        lastPage = 1;
        total = 0;
        prevPageUrl = null;
        nextPageUrl = null;
        Customsnackbar()
            .showErrorSnackbar(context, "Failed to load descriptions.");
      }
    });
  }

  Future<bool> _onBackPressed() async {
    return true;
  }

  Widget _buildUserRatingItem(Descriptions description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.user?.userPicture != null)
              CircleAvatar(
                radius: isWebLayout ? 30 : 20,
                backgroundImage: CachedNetworkImageProvider(
                  description.user!.userPicture!,
                ),
              )
            else
              CircleAvatar(
                radius: isWebLayout ? 30 : 20,
                child: Icon(Icons.person, size: isWebLayout ? 30 : 20),
              ),
            SizedBox(width: isWebLayout ? 8 : 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description.user?.name ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: isWebLayout ? 18 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: isWebLayout ? 8 : 4),
                          Text(
                            description.user?.email ?? '',
                            style: TextStyle(
                              fontSize: isWebLayout ? 14 : 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isWebLayout ? 8 : 4),
                  Text(
                    description.description ?? '',
                    style: TextStyle(
                      fontSize: isWebLayout ? 16 : 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isWebLayout ? 12.0 : 8.0),
                    child: Text(
                      description.updatedAt?.split('T').first ?? '',
                      style: TextStyle(
                        fontSize: isWebLayout ? 12 : 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWebLayout ? 12 : 8,
                vertical: isWebLayout ? 8 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.star,
                      color: Colors.orange, size: isWebLayout ? 24 : 20),
                  SizedBox(width: isWebLayout ? 4 : 2),
                  Text(
                    '${description.rate}',
                    style: TextStyle(
                      fontSize: isWebLayout ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _userRating ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: isWebLayout ? 40 : 30,
          ),
          onPressed: () {
            setState(() {
              _userRating = index + 1;
            });
          },
        );
      }),
    );
  }

  Widget _buildUserRatingSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.your_rating,
                  style: TextStyle(
                    fontSize: isWebLayout ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (myDescription != null)
                  Text(
                    '${AppLocalizations.of(context)!.last_update} : ${myDescription!.updatedAt?.split('T').first ?? ''}',
                    style: TextStyle(
                      fontSize: isWebLayout ? 14 : 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            SizedBox(height: isWebLayout ? 16 : 8),
            _buildStarRating(),
            SizedBox(height: isWebLayout ? 16 : 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.description,
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(fontSize: isWebLayout ? 16 : 14),
              ),
              maxLines: 3,
              style: TextStyle(fontSize: isWebLayout ? 16 : 14),
            ),
            SizedBox(height: isWebLayout ? 16 : 8),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB8C00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWebLayout ? 24 : 16,
                    vertical: isWebLayout ? 12 : 8,
                  ),
                ),
                onPressed: _saveRating,
                child: Text(
                  AppLocalizations.of(context)!.soumettre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWebLayout ? 16 : 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRating() async {
    if (_userRating == 0) {
      Customsnackbar().showErrorSnackbar(context, 'Please select a rating.');
      return;
    }
    if (_descriptionController.text.isEmpty) {
      Customsnackbar()
          .showErrorSnackbar(context, 'Please enter a description.');
      return;
    }

    await RatingService().createOrUpdateRating(
        context, widget.bakery.id.toString(), _userRating, _descriptionController.text);
    _initializeData(); // Refresh data after saving
  }

  Widget buildFromMobile() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildUserRatingSection(context),
                if (descriptions.isNotEmpty)
                  ...descriptions
                      .asMap()
                      .entries
                      .map((entry) => _buildUserRatingItem(entry.value))
                      .toList(),
                if (descriptions.isEmpty && !isLoading)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.noRatingsFound,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00))),
              ],
            ),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget buildFromWeb() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildUserRatingSection(context),
                if (descriptions.isNotEmpty)
                  ...descriptions
                      .asMap()
                      .entries
                      .map((entry) => _buildUserRatingItem(entry.value))
                      .toList(),
                if (descriptions.isEmpty && !isLoading)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.noRatingsFound,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00))),
              ],
            ),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bakery.name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _onBackPressed().then((canPop) {
            if (canPop) Navigator.pop(context);
          }),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isBigLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)))
            : isWebLayout
                ? buildFromWeb()
                : buildFromMobile(),
      ),
    );
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];
    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1);

    pageLinks.add(
      Container(
        padding: EdgeInsets.all(10.0),
        margin: EdgeInsets.symmetric(horizontal: 6),
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
                  fetchdescriptions(page: currentPage);
                }
              : null,
          child: Icon(Icons.arrow_left,
              size: isWebLayout ? 24 : 20,
              color: Colors.black),
        ),
      ),
    );

    for (int i = 1; i <= lastPage; i++) {
      if (i >= currentPage - 3 && i <= currentPage + 3) {
        pageLinks.add(
          Container(
            padding: EdgeInsets.all(isWebLayout ? 8.0 : 6.0),
            margin: EdgeInsets.symmetric(horizontal: isWebLayout ? 4.0 : 3.0),
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
                fetchdescriptions(page: currentPage);
              },
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: isWebLayout ? 16 : 14,
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
        padding: EdgeInsets.all(isWebLayout ? 8.0 : 6.0),
        margin: EdgeInsets.symmetric(horizontal: isWebLayout ? 4.0 : 3.0),
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
                  fetchdescriptions(page: currentPage);
                }
              : null,
          child: Icon(Icons.arrow_right,
              size: isWebLayout ? 24 : 20,
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
}