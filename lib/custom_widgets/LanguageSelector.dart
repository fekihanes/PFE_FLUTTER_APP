import 'package:flutter/material.dart';
import 'package:flutter_application/main.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Assurez-vous d'avoir cette dépendance
import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // Import AppLocalizations

class LanguageSelector extends StatefulWidget {
  @override
  _LanguageSelectorState createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String selectedLanguage = 'fr'; // Langue par défaut

  final Map<String, String> languages = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };

  final Map<String, String> flags = {
    'fr': 'assets/flags/france.png',
    'en': 'assets/flags/usa.png',
    'ar': 'assets/flags/saudi-arabia.png',
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();  // Charger la préférence de langue lors du démarrage
  }

  // Charger la langue depuis SharedPreferences
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLanguage = prefs.getString('language') ?? 'fr'; // Langue par défaut 'fr'
    });
  }

  // Changer la langue et enregistrer la préférence dans SharedPreferences
  Future<void> _changeLanguage(String newLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguage); // Enregistrer la langue choisie
    setState(() {
      selectedLanguage = newLanguage; // Mettre à jour l'état de l'interface
    });

    // Notify the app about the locale change
    localeNotifier.value = Locale(newLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.language, // Remplace par AppLocalizations.of(context)!.language si nécessaire
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLanguage,
                isExpanded: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _changeLanguage(newValue);  // Changer la langue et sauvegarder la préférence
                  }
                },
                items: languages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Image.asset(
                          flags[entry.key]!,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag),
                        ),
                        const SizedBox(width: 10),
                        Text(entry.value),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
