import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Traductions {
  traductionrole(BuildContext context, String role) {
    switch (role) {
      case 'caissier':
        return AppLocalizations.of(context)!.caissier;
      case 'livreur':
        return AppLocalizations.of(context)!.livreur;
      case 'patissier':
        return AppLocalizations.of(context)!.patissier;
      case 'boulanger':
        return AppLocalizations.of(context)!.boulanger;
      case 'admin':
        return AppLocalizations.of(context)!.admin;
      case 'manager':
        return AppLocalizations.of(context)!.manager;
      default:
        return AppLocalizations.of(context)!.user;
    }
  }

  String getTranslatedDay(BuildContext context, String day) {
    switch (day) {
      case 'monday':
        return AppLocalizations.of(context)!.monday;
      case 'tuesday':
        return AppLocalizations.of(context)!.tuesday;
      case 'wednesday': // Added missing case
        return AppLocalizations.of(context)!.wednesday;
      case 'thursday':
        return AppLocalizations.of(context)!.thursday;
      case 'friday':
        return AppLocalizations.of(context)!.friday;
      case 'saturday':
        return AppLocalizations.of(context)!.saturday;
      case 'sunday':
        return AppLocalizations.of(context)!.sunday;
      default:
        return day;
    }
  }

  String getTranslatedkey(BuildContext context, String key) {
    switch (key) {
      case 'start':
        return AppLocalizations.of(context)!.start;
      case 'end':
        return AppLocalizations.of(context)!.end;
      case 'deadline':
        return AppLocalizations.of(context)!.deadline;
      default:
        return key;
    }
  }

  String getToDayName(BuildContext context, DateTime date) {
  //     DateTime today = DateTime.now();
  // print(getEnglishDayName(today));
    List<String> days = [
      AppLocalizations.of(context)!.sunday,
      AppLocalizations.of(context)!.monday,
      AppLocalizations.of(context)!.tuesday,
      AppLocalizations.of(context)!.wednesday,
      AppLocalizations.of(context)!.thursday,
      AppLocalizations.of(context)!.friday,
      AppLocalizations.of(context)!.saturday
    ];
    return days[date.weekday % 7]; // % 7 pour que Dimanche soit bien indexé à 0
  }
  String getEnglishDayName(DateTime date) {
  List<String> days = [
    "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"
  ];
  return days[date.weekday % 7]; // % 7 pour que Dimanche soit bien indexé à 0
}


}
