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

  Widget _buildUserRatingItem(Descriptions description) {
    return Card(
      color: Colors.white,
      shadowColor: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [

                  if (description.user?.userPicture != null)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: CachedNetworkImageProvider(
                        description.user!.userPicture!,
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person),
                    ),
                  const SizedBox(width: 8),
                  Column(
                    children: [

                  Text(
                    description.user?.name ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    description.user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  ],),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.description ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      description.updatedAt?.split('T').first ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      )),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${description.rate}',
                    style: const TextStyle(
                      fontSize: 20,
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
            size: 40,
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
  return Card(
    color: Colors.white,
    shadowColor: Colors.black,
    margin: const EdgeInsets.all(16),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (myDescription != null)
                Text(
                  '${AppLocalizations.of(context)!.last_update} : ${myDescription!.updatedAt?.split('T').first ?? ''}',
                  style: const TextStyle(color: Colors.grey),
                )
            ],
          ),
          const SizedBox(height: 16),
          _buildStarRating(),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.description,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB8C00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _saveRating,
              child: Text(AppLocalizations.of(context)!.soumettre),
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

    await RatingService().createOrUpdateRating(context,
        widget.bakery.id.toString(), _userRating, _descriptionController.text);
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: prevPageUrl != null
                ? () => fetchdescriptions(page: currentPage - 1)
                : null,
          ),
          Text('Page $currentPage of $lastPage'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: nextPageUrl != null
                ? () => fetchdescriptions(page: currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bakery.name),
      ),
      backgroundColor: const Color(0xFFE5E7EB),
      body: isBigLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildUserRatingSection(context),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildUserRatingItem(descriptions[index]),
                    childCount: descriptions.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPaginationControls(),
                ),
              ],
            ),
    );
  }
}
