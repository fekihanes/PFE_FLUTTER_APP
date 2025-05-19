import 'package:flutter/material.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/view/user/ShowUserInfoPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Adjust path as needed

class TopUsersPage extends StatelessWidget {
  final List<Map<String, dynamic>> bestUsers;

  const TopUsersPage({Key? key, required this.bestUsers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.topUsers,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
      ),
      body: bestUsers.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noData,
                style: GoogleFonts.montserrat(fontSize: 18, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bestUsers.length,
              itemBuilder: (context, index) {
                final user = bestUsers[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      user['user_name'],
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${AppLocalizations.of(context)!.orders}: ${user['order_count']} | ${AppLocalizations.of(context)!.total}: ${user['total_cost']} ${AppLocalizations.of(context)!.dt}',
                      style: GoogleFonts.montserrat(),
                    ),
                    onTap: () {
                      final userObj = UserClass(
                        id: user['user_id'],
                          name: user['user_name'], email: '', phone: '', userPicture: '', role: '', enable: 1, cin: '', salary: '', address: '',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowUserInfoPage(
                            userId: user['user_id'],
                            user: userObj,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}