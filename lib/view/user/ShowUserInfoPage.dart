import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/services/users/user_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ShowUserInfoPage extends StatefulWidget {
  final int userId;
  final UserClass? user; // Optional: Pass UserClass directly to skip fetching

  const ShowUserInfoPage({
    Key? key,
    required this.userId,
    this.user,
  }) : super(key: key);

  @override
  _ShowUserInfoPageState createState() => _ShowUserInfoPageState();
}

class _ShowUserInfoPageState extends State<ShowUserInfoPage> {
  UserClass? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.user != null) {
        // Use provided UserClass if available
        setState(() {
          _user = widget.user;
          _isLoading = false;
        });
      } else {
        // Fetch user from UserService
        final userService = UserService();
        final user = await userService.getUserbyId(widget.userId, context);
        setState(() {
          _user = user;
          _isLoading = false;
        });
        if (user == null) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.errorFetchingUser;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${AppLocalizations.of(context)!.errorFetchingUser}: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  Widget _buildUserImage() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _user?.userPicture != null && _user!.userPicture!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: ApiConfig.changePathImage(_user!.userPicture!),
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, progress) => Center(
                    child: CircularProgressIndicator(
                      value: progress.progress,
                      color: const Color(0xFFFB8C00),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.grey, size: 50),
                  ),
                )
              : Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.grey, size: 50),
                ),
        ),
      ),
    );
  }

  Widget _buildUserDetails() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)));
    }
    if (_user == null) {
      return Center(child: Text(AppLocalizations.of(context)!.noUserFound, style: const TextStyle(color: Colors.black54, fontSize: 16)));
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.userDetails,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(AppLocalizations.of(context)!.user, _user!.name),
            _buildDetailRow(AppLocalizations.of(context)!.email, _user!.email),
            _buildDetailRow(AppLocalizations.of(context)!.phone, _user!.phone),
            _buildDetailRow(AppLocalizations.of(context)!.role, _user!.role),
            _buildDetailRow(AppLocalizations.of(context)!.cin, _user!.cin),
            _buildDetailRow(AppLocalizations.of(context)!.salary, _user!.salary ?? AppLocalizations.of(context)!.notSpecified),
            _buildDetailRow(AppLocalizations.of(context)!.address, _user!.address),
            // _buildDetailRow(
            //   AppLocalizations.of(context)!.bakeryId,
            //   _user!.bakeryId != null ? _user!.bakeryId.toString() : AppLocalizations.of(context)!.notSpecified,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.userDetails,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserImage(),
            const SizedBox(height: 20),
            _buildUserDetails(),
          ],
        ),
      ),
    );
  }
}