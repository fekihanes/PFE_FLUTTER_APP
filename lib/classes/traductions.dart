import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Traductions {
    traductionrole (BuildContext context, String role){
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
}