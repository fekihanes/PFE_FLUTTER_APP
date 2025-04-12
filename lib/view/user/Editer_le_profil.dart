
import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/UserProfileImageState.dart';
class EditerLeProfil extends StatefulWidget {
  const EditerLeProfil({super.key});

  @override
  State<EditerLeProfil> createState() => _EditerLeProfilState();
}

class _EditerLeProfilState extends State<EditerLeProfil> {

  @override
  void initState() {
    super.initState();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Profil utilisateur")),
    body: Center(child: UserProfileImage()),
  );
}

}
