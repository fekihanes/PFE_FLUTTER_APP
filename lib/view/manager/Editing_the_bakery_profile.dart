import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/services/manager/manager_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class EditingTheBakeryProfile extends StatefulWidget {
  const EditingTheBakeryProfile({super.key});

  @override
  State<EditingTheBakeryProfile> createState() =>
      _EditingTheBakeryProfileState();
}

class _EditingTheBakeryProfileState extends State<EditingTheBakeryProfile> {
  bool _isSaving = false;

  Bakery? bakery;
  String? _imagePath;
  String? oldimage;
  Uint8List? _webImage;
  Map<String, dynamic> _openingHours = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedDay;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const List<String> _orderedDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    String? idBakery = prefs.getString('my_bakery');

    if (idBakery == null || idBakery.isEmpty) {
      setState(() {
        bakery = Bakery(
          id: -1,
          name: '',
          email: '',
          phone: '',
          image: null, // Initialiser à null au lieu de chaîne vide
          openingHours: '{}',
          managerId: _getCurrentManagerId(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _imagePath = null; // Reset correct
        _openingHours = {};
      });
      return;
    } else {
      try {
        final fetchedBakery = await ManagerService().getBakery(context);
        if (fetchedBakery != null) {
          setState(() {
            bakery = fetchedBakery;
            _nameController.text = bakery!.name;
            _emailController.text = bakery!.email;
            _phoneController.text = bakery!.phone;
            _imagePath = bakery!.image;
            oldimage = bakery!.image;
            _openingHours = {};
            Map<String, dynamic> storedHours = jsonDecode(bakery!.openingHours);
            storedHours.forEach((day, data) {
              _openingHours[day] = {
                'start': _convertToHHMM(data['start'] ?? '08:00'),
                'end': _convertToHHMM(data['end'] ?? '17:00'),
                'deadline': _convertToHHMM(data['deadline'] ?? '16:00'),
              };
            });
          });
        } else {
          setState(() {
            bakery = Bakery(
              id: -1,
              name: '',
              email: '',
              phone: '',
              image: '',
              openingHours: '{}',
              managerId: _getCurrentManagerId(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            _imagePath = null;
            _webImage = null;
          });
        }
      } catch (e, stacktrace) {
        print('Error fetching bakery data: $e');
        print(stacktrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getCurrentManagerId() {
    // Implémentez la logique réelle ici (ex: SharedPreferences)
    return 0; // Exemple
  }

  void _setImage(String? imagePath, Uint8List? webImage) {
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;

      // Forcer le rafraîchissement de l'état
      if (imagePath == null && webImage == null) {
        bakery = bakery?.copyWith(image: null);
      }
    });
  }

  void _addNewOpeningDay() {
    if (_selectedDay != null && !_openingHours.containsKey(_selectedDay)) {
      setState(() {
        _openingHours[_selectedDay!] = {
          'start': '08:00', // Valeur par défaut
          'end': '17:00', // Valeur par défaut
          'deadline': '16:00' // Valeur par défaut
        };
        _selectedDay = null;
        FocusScope.of(context).unfocus(); // Fermer le clavier
      });
    }
  }

  void _removeOpeningDay(String day) {
    setState(() {
      _openingHours.remove(day);
    });
  }

  bool _validateOpeningHours() {
    for (var entry in _openingHours.entries) {
      String day = entry.key;
      Map<String, dynamic> dayData = entry.value;

      String start = dayData['start'];
      String end = dayData['end'];
      String deadline = dayData['deadline'];

      // Ensure all fields are filled
      if (start.isEmpty || end.isEmpty || deadline.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.fillAllFields} for ${Traductions().getTranslatedDay(context, day)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Parse times
      TimeOfDay startTime = _parseTimeOfDay(start);
      TimeOfDay endTime = _parseTimeOfDay(end);
      TimeOfDay deadlineTime = _parseTimeOfDay(deadline);

      // Validate that end time is after start time
      if (endTime.hour < startTime.hour ||
          (endTime.hour == startTime.hour &&
              endTime.minute <= startTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.endAfterStart} for ${Traductions().getTranslatedDay(context, day)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Validate that deadline is before end time
      if (deadlineTime.hour > endTime.hour ||
          (deadlineTime.hour == endTime.hour &&
              deadlineTime.minute >= endTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.deadlineBeforeEnd} for ${Traductions().getTranslatedDay(context, day)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final format = time.split(':');
    final hour = int.parse(format[0]);
    final minute = int.parse(format[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _convertToHHMM(String time) {
    try {
      TimeOfDay parsed = _parseTimeOfDay(time);
      return "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '00:00'; // default if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Corrected availableDays list with all weekdays
    List<String> availableDays = [
      'monday',
      'tuesday',
      'wednesday', // Added missing Wednesday
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ].where((day) => !_openingHours.containsKey(day)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.editBakery,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
      ),
      drawer: const CustomDrawerManager(),
      body: bakery == null
          ? const Center(
              child: CircularProgressIndicator(
              color: Color(0xFFFB8C00),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildImageInputWidget(),
                    const SizedBox(height: 20),
                    _buildInputName(),
                    const SizedBox(height: 20),
                    _buildInputEmail(),
                    const SizedBox(height: 20),
                    _buildInputPhone(),
                    const SizedBox(height: 20),
                    _buildOpeningHours(availableDays),
                    const SizedBox(height: 20),
                    _buildContainerLocalization(bakery!),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageInputWidget() {
    return Center(
      child: ImageInputWidget(
        onImageSelected: _setImage,
        initialImage: bakery?.image,
        width: MediaQuery.of(context).size.width * 0.8,
        height: 200,
      ),
    );
  }

  Widget _buildInputName() {
    return _buildCustomTextField(
      _nameController,
      AppLocalizations.of(context)!.bakery_name,
      Icons.store,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.requiredField;
        }
        return null;
      },
    );
  }

  Widget _buildInputEmail() {
    return _buildCustomTextField(
      _emailController,
      AppLocalizations.of(context)!.bakery_email,
      Icons.email,
      validator: (value) {
        final emailRegExp =
            RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
        if (!emailRegExp.hasMatch(value!)) {
          return AppLocalizations.of(context)!.invalidEmail;
        }
        return null;
      },
    );
  }

  Widget _buildInputPhone() {
    return _buildCustomTextField(
      _phoneController,
      AppLocalizations.of(context)!.bakery_phone,
      Icons.phone,
      validator: (value) {
        if (value!.length != 8) {
          return AppLocalizations.of(context)!.phoneLengthError;
        }
        return null;
      },
    );
  }

  Widget _buildOpeningHours(List<String> availableDays) {
    // Trier les entrées selon l'ordre des jours
    final sortedEntries = _openingHours.entries.toList()
      ..sort((a, b) => _orderedDays.indexOf(a.key.toLowerCase()).compareTo(
            _orderedDays.indexOf(b.key.toLowerCase()),
          ));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.hoursofoperation,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 10),
          ...sortedEntries.map((entry) {
            String day = entry.key;
            Map<String, dynamic> dayData = entry.value;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        Traductions()
                            .getTranslatedDay(context, day)
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _removeOpeningDay(day);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(day, 'start', dayData['start']),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTimeField(day, 'end', dayData['end']),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTimeField(
                            day, 'deadline', dayData['deadline']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          _buildDaySelector(availableDays),
        ],
      ),
    );
  }

  Widget _buildContainerLocalization(Bakery bakery) {
    if ((bakery.subAdministrativeArea?.isNotEmpty ?? false) &&
        (bakery.administrativeArea?.isNotEmpty ?? false)) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Column(
              children: [
                if (bakery.street != null && bakery.street != '')
                  buildAddressRow(Icons.home, "Rue", bakery.street ?? ''),
                buildAddressRow(
                    Icons.map, "Sous-zone", bakery.subAdministrativeArea ?? ''),
                buildAddressRow(
                    Icons.place, "Région", bakery.administrativeArea ?? ''),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          )
        ],
      );
    } else {
      return SizedBox.shrink(); // Évite un espace vide inutile
    }
  }

  Widget buildAddressRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFB8C00)),
          SizedBox(width: 10),
          Text(
            '$label : ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(String day, String key, String initialValue) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: _formatTimeForDisplay(initialValue),
      ),
      decoration: InputDecoration(
        labelText: Traductions().getTranslatedkey(context, key).toUpperCase(),
      ),
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: _parseTimeOfDay(initialValue),
        );
        if (pickedTime != null) {
          String formattedTime =
              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
          setState(() {
            _openingHours[day][key] = formattedTime;
          });
        }
      },
    );
  }

  String _formatTimeForDisplay(String time) {
    List<String> parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    TimeOfDay timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return timeOfDay.format(context);
  }

  Widget _buildDaySelector(List<String> availableDays) {
    return Row(
      children: [
        DropdownButton<String>(
          value: _selectedDay,
          hint: Text(AppLocalizations.of(context)!.select_day,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          items: availableDays.map((day) {
            return DropdownMenuItem(
              value: day,
              child: Text(Traductions().getTranslatedDay(context, day)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDay = value;
            });
          },
        ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFB8C00)),
          onPressed: _addNewOpeningDay,
          child: Text(AppLocalizations.of(context)!.add_day,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    if (bakery?.id == -1) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFB8C00),
          ),
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() {
                    _isSaving = true;
                  });

                  if (_formKey.currentState?.validate() ?? false) {
                    if (_openingHours.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .requiredOpeningHours),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _isSaving = false;
                      });
                      return;
                    }
                    if (!_validateOpeningHours()) {
                      setState(() {
                        _isSaving = false;
                      });
                      return;
                    }

                    if (bakery!.id == -1 &&
                        (_imagePath?.isEmpty ?? true) &&
                        _webImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(AppLocalizations.of(context)!.requiredImage),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _isSaving = false;
                      });
                      return;
                    }

                    String image = _imagePath ?? '';
                    if (kIsWeb && _webImage != null) {
                      image = base64Encode(_webImage!);
                    }

                    Bakery updatedBakery = Bakery(
                      id: bakery!.id,
                      name: _nameController.text,
                      email: _emailController.text,
                      phone: _phoneController.text,
                      image: image,
                      openingHours: jsonEncode(_openingHours),
                      managerId: bakery!.managerId,
                      createdAt: bakery!.createdAt,
                      updatedAt: DateTime.now(),
                    );

                    try {
                      if (bakery!.id == -1) {
                        await ManagerService()
                            .createBakery(context, updatedBakery);
                        fetchData();
                      } else {
                        await ManagerService()
                            .updateBakery(context, updatedBakery, oldimage!);
                      }
                    } catch (e) {
                      print('Error updating bakery: $e');
                    }

                    setState(() {
                      _isSaving = false;
                    });
                  }
                },
          child: _isSaving
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
                  AppLocalizations.of(context)!.save,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFB8C00),
            ),
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() {
                      _isSaving = true;
                    });

                    if (_formKey.currentState?.validate() ?? false) {
                      if (_openingHours.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .requiredOpeningHours),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isSaving = false;
                        });
                        return;
                      }
                      if (!_validateOpeningHours()) {
                        setState(() {
                          _isSaving = false;
                        });
                        return;
                      }

                      if (bakery!.id == -1 &&
                          (_imagePath?.isEmpty ?? true) &&
                          _webImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.requiredImage),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isSaving = false;
                        });
                        return;
                      }

                      String image = _imagePath ?? '';
                      if (kIsWeb && _webImage != null) {
                        image = base64Encode(_webImage!);
                      }

                      Bakery updatedBakery = Bakery(
                        id: bakery!.id,
                        name: _nameController.text,
                        email: _emailController.text,
                        phone: _phoneController.text,
                        image: image,
                        openingHours: jsonEncode(_openingHours),
                        managerId: bakery!.managerId,
                        createdAt: bakery!.createdAt,
                        updatedAt: DateTime.now(),
                      );

                      try {
                        if (bakery!.id == -1) {
                          await ManagerService()
                              .createBakery(context, updatedBakery);
                          fetchData();
                        } else {
                          await ManagerService()
                              .updateBakery(context, updatedBakery, oldimage!);
                        }
                      } catch (e) {
                        print('Error updating bakery: $e');
                      }

                      setState(() {
                        _isSaving = false;
                      });
                    }
                  },
            child: _isSaving
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    AppLocalizations.of(context)!.save,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFB8C00),
            ),
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() {
                      _isSaving = true;
                    });

                    try {
                      await ManagerService()
                          .updateBakeryLocalization(context, bakery!.id);
                    } catch (e) {}

                    setState(() {
                      _isSaving = false;
                    });
                    fetchData();
                  },
            child: _isSaving
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    AppLocalizations.of(context)!.save_new_localization,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        ],
      );
    }
  }

  Widget _buildCustomTextField(
      TextEditingController controller, String hintText, IconData icon,
      {String? Function(String?)? validator}) {
    return CustomTextField(
      controller: controller,
      labelText: hintText, // Use hintText here
      icon: icon,
      validator: validator,
    );
  }
}
