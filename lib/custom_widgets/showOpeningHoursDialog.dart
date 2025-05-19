  import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Bakery.dart';
  import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showOpeningHoursDialog(BuildContext context,Bakery bakery) {
    final localization = AppLocalizations.of(context)!;
    final daysOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    Map<String, dynamic> openingHours;
    try {
      openingHours = jsonDecode(bakery.openingHours ?? '{}');
    } catch (e) {
      openingHours = {};
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localization.openingHours,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: openingHours.isEmpty
              ? const Text('Opening hours not available.')
              : Table(
                  border: TableBorder.all(color: Colors.grey),
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[200]),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Day',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Start',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'End',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Deadline',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...daysOrder.map((day) {
                      final schedule = openingHours[day] as Map<String, dynamic>?;
                      return TableRow(
                        children: [
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: Text(day.capitalize()),
                          // ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(schedule?['start'] ?? 'Closed'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(schedule?['end'] ?? 'Closed'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(schedule?['deadline'] ?? 'N/A'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(localization.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  