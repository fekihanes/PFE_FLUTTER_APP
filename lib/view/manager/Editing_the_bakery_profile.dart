import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
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
  final TextEditingController _deliveryFeeController = TextEditingController();
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
    print('initState: Initializing EditingTheBakeryProfile');
    fetchData();
  }

  Future<void> fetchData() async {
    print('fetchData: Fetching bakery data');
    final prefs = await SharedPreferences.getInstance();
    String? idBakery = prefs.getString('my_bakery');

    if (idBakery == null || idBakery.isEmpty) {
      print('fetchData: No bakery ID found, setting default bakery');
      setState(() {
        bakery = Bakery(
          id: -1,
          name: '',
          email: '',
          phone: '',
          image: null,
          openingHours: '{}',
          managerId: _getCurrentManagerId(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deliveryFee: 0,
        );
        _imagePath = null;
        _openingHours = {};
      });
      return;
    } else {
      try {
        final fetchedBakery = await BakeryService().getBakery(context);
        if (fetchedBakery != null) {
          print('fetchData: Bakery fetched successfully, ID: ${fetchedBakery.id}');
          setState(() {
            bakery = fetchedBakery;
            _nameController.text = bakery!.name;
            _emailController.text = bakery!.email;
            _phoneController.text = bakery!.phone;
            _deliveryFeeController.text = bakery!.deliveryFee.toString();
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
          print('fetchData: No bakery data returned, setting default');
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
              deliveryFee: 0.0,
            );
            _imagePath = null;
            _webImage = null;
          });
        }
      } catch (e, stacktrace) {
        print('fetchData: Error fetching bakery data: $e');
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
    print('_getCurrentManagerId: Returning default manager ID: 0');
    return 0;
  }

  void _setImage(String? imagePath, Uint8List? webImage) {
    print('_setImage: Setting image, path: $imagePath, webImage: ${webImage != null ? "present" : "null"}');
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;
      if (imagePath == null && webImage == null) {
        bakery = bakery?.copyWith(image: null);
      }
    });
  }

  void _addNewOpeningDay() {
    if (_selectedDay != null && !_openingHours.containsKey(_selectedDay)) {
      print('_addNewOpeningDay: Adding new opening day: $_selectedDay');
      setState(() {
        _openingHours[_selectedDay!] = {
          'start': '08:00',
          'end': '17:00',
          'deadline': '16:00'
        };
        _selectedDay = null;
        FocusScope.of(context).unfocus();
      });
    }
  }

  void _removeOpeningDay(String day) {
    print('_removeOpeningDay: Removing opening day: $day');
    setState(() {
      _openingHours.remove(day);
    });
  }

  bool _validateOpeningHours() {
    print('_validateOpeningHours: Validating opening hours');
    for (var entry in _openingHours.entries) {
      String day = entry.key;
      Map<String, dynamic> dayData = entry.value;

      String start = dayData['start'];
      String end = dayData['end'];
      String deadline = dayData['deadline'];

      if (start.isEmpty || end.isEmpty || deadline.isEmpty) {
        print('_validateOpeningHours: Empty fields for $day');
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

      TimeOfDay startTime = _parseTimeOfDay(start);
      TimeOfDay endTime = _parseTimeOfDay(end);
      TimeOfDay deadlineTime = _parseTimeOfDay(deadline);

      if (endTime.hour < startTime.hour ||
          (endTime.hour == startTime.hour &&
              endTime.minute <= startTime.minute)) {
        print('_validateOpeningHours: End time before start for $day');
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

      if (deadlineTime.hour > endTime.hour ||
          (deadlineTime.hour == endTime.hour &&
              deadlineTime.minute >= endTime.minute)) {
        print('_validateOpeningHours: Deadline after end for $day');
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
    print('_validateOpeningHours: Validation passed');
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
      print('_convertToHHMM: Error parsing time: $time, returning 00:00');
      return '00:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    print('build: Rendering with isWebLayout: $isWebLayout');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.editBakery,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          NotificationIcon(),
          SizedBox(width: 8),
        ],
        ),
        drawer: const CustomDrawerManager(),
        body: isWebLayout
            ? buildFromWeb(context)
            : buildFromMobile(context),
    );
  }


  Widget buildFromMobile(BuildContext context) {
    print('buildFromMobile: Building mobile layout');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: bakery == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFB8C00),
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildImageInputWidget(),
                    const SizedBox(height: 16),
                    _buildInputName(),
                    const SizedBox(height: 16),
                    _buildInputEmail(),
                    const SizedBox(height: 16),
                    _buildInputPhone(),
                    const SizedBox(height: 16),
                    _buildInputdeliveryFee(),
                    const SizedBox(height: 16),
                    _buildOpeningHours(),
                    const SizedBox(height: 16),
                    _buildContainerLocalization(bakery!),
                    const SizedBox(height: 16),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    print('buildFromWeb: Building web layout');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: bakery == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFB8C00),
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildImageInputWidget(),
                    const SizedBox(height: 24),
                    _buildInputName(),
                    const SizedBox(height: 24),
                    _buildInputEmail(),
                    const SizedBox(height: 24),
                    _buildInputPhone(),
                    const SizedBox(height: 24),
                    _buildInputdeliveryFee(),
                    const SizedBox(height: 24),
                    _buildOpeningHours(),
                    const SizedBox(height: 24),
                    _buildContainerLocalization(bakery!),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageInputWidget() {
    print('_buildImageInputWidget: Building image input widget');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
        child: Center(
          child: ImageInputWidget(
            onImageSelected: _setImage,
            initialImage: bakery?.image,
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }

  Widget _buildInputName() {
    print('_buildInputName: Building name input');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
        child: _buildCustomTextField(
          _nameController,
          AppLocalizations.of(context)!.bakery_name,
          Icons.store,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.requiredField;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildInputEmail() {
    print('_buildInputEmail: Building email input');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
        child: _buildCustomTextField(
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
        ),
      ),
    );
  }

  Widget _buildInputPhone() {
    print('_buildInputPhone: Building phone input');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
        child: _buildCustomTextField(
          _phoneController,
          AppLocalizations.of(context)!.bakery_phone,
          Icons.phone,
          validator: (value) {
            if (value!.length != 8) {
              return AppLocalizations.of(context)!.phoneLengthError;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildInputdeliveryFee() {
    print('_buildInputdeliveryFee: Building delivery fee input');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
        child: _buildCustomTextField(
          _deliveryFeeController,
          AppLocalizations.of(context)!.delivery_fee,
          Icons.local_shipping,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.delivery_fee_required;
            }
            final fee = double.tryParse(value);
            if (fee == null || fee < 0) {
              return AppLocalizations.of(context)!.delivery_fee_invalid;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildOpeningHours() {
    print('_buildOpeningHours: Building opening hours');
    List<String> availableDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ].where((day) => !_openingHours.containsKey(day)).toList();

    final sortedEntries = _openingHours.entries.toList()
      ..sort((a, b) => _orderedDays.indexOf(a.key.toLowerCase()).compareTo(
            _orderedDays.indexOf(b.key.toLowerCase()),
          ));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.hoursofoperation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...sortedEntries.map((entry) {
            String day = entry.key;
            Map<String, dynamic> dayData = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 10.0),
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
                      children: [
                        Text(
                          Traductions()
                              .getTranslatedDay(context, day)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                          child:
                              _buildTimeField(day, 'deadline', dayData['deadline']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 10),
          Container(
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
            padding: const EdgeInsets.all(16.0),
            child: _buildDaySelector(availableDays),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerLocalization(Bakery bakery) {
    print('_buildContainerLocalization: Building localization container');
    if ((bakery.subAdministrativeArea?.isNotEmpty ?? false) &&
        (bakery.administrativeArea?.isNotEmpty ?? false)) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
            children: [
              if (bakery.street != null && bakery.street != '')
                buildAddressRow(
                  Icons.home,
                  AppLocalizations.of(context)!.street,
                  bakery.street ?? '',
                ),
              buildAddressRow(
                Icons.map,
                AppLocalizations.of(context)!.subAdministrativeArea,
                bakery.subAdministrativeArea ?? '',
              ),
              buildAddressRow(
                Icons.place,
                AppLocalizations.of(context)!.administrativeArea,
                bakery.administrativeArea ?? '',
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildAddressRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFB8C00)),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
            print('_buildTimeField: Updated $key for $day to $formattedTime');
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
    print('_buildDaySelector: Building day selector, available days: $availableDays');
    return Row(
      children: [
        DropdownButton<String>(
          value: _selectedDay,
          hint: Text(
            AppLocalizations.of(context)!.select_day,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          items: availableDays.map((day) {
            return DropdownMenuItem(
              value: day,
              child: Text(Traductions().getTranslatedDay(context, day)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDay = value;
              print('_buildDaySelector: Selected day: $value');
            });
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB8C00),
              minimumSize: const Size(double.infinity, 40),
            ),
            onPressed: _addNewOpeningDay,
            child: Text(
              AppLocalizations.of(context)!.add_day,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    print('_buildSaveButton: Building save button, bakery ID: ${bakery?.id}');
    if (bakery?.id == -1) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB8C00),
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: _isSaving
                  ? null
                  : () async {
                      print('_buildSaveButton: Save button pressed');
                      setState(() {
                        _isSaving = true;
                      });

                      if (_formKey.currentState?.validate() ?? false) {
                        if (_openingHours.isEmpty) {
                          print('_buildSaveButton: No opening hours provided');
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
                          print('_buildSaveButton: Opening hours validation failed');
                          setState(() {
                            _isSaving = false;
                          });
                          return;
                        }

                        if (bakery!.id == -1 &&
                            (_imagePath?.isEmpty ?? true) &&
                            _webImage == null) {
                          print('_buildSaveButton: No image provided for new bakery');
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
                          print('_buildSaveButton: Encoded web image to base64');
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
                          deliveryFee: double.parse(_deliveryFeeController.text),
                        );

                        try {
                          if (bakery!.id == -1) {
                            print('_buildSaveButton: Creating new bakery');
                            await BakeryService()
                                .createBakery(context, updatedBakery);
                            fetchData();
                          } else {
                            print('_buildSaveButton: Updating existing bakery');
                            await BakeryService()
                                .updateBakery(context, updatedBakery, oldimage!);
                          }
                        } catch (e) {
                          print('_buildSaveButton: Error updating bakery: $e');
                        }

                        setState(() {
                          _isSaving = false;
                        });
                      } else {
                        print('_buildSaveButton: Form validation failed');
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    },
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      AppLocalizations.of(context)!.save,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB8C00),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          print('_buildSaveButton: Save button pressed');
                          setState(() {
                            _isSaving = true;
                          });

                          if (_formKey.currentState?.validate() ?? false) {
                            if (_openingHours.isEmpty) {
                              print('_buildSaveButton: No opening hours provided');
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
                              print(
                                  '_buildSaveButton: Opening hours validation failed');
                              setState(() {
                                _isSaving = false;
                              });
                              return;
                            }

                            if (bakery!.id == -1 &&
                                (_imagePath?.isEmpty ?? true) &&
                                _webImage == null) {
                              print(
                                  '_buildSaveButton: No image provided for new bakery');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!
                                      .requiredImage),
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
                              print(
                                  '_buildSaveButton: Encoded web image to base64');
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
                              deliveryFee:
                                  double.parse(_deliveryFeeController.text),
                            );

                            try {
                              if (bakery!.id == -1) {
                                print('_buildSaveButton: Creating new bakery');
                                await BakeryService()
                                    .createBakery(context, updatedBakery);
                                fetchData();
                              } else {
                                print('_buildSaveButton: Updating existing bakery');
                                await BakeryService().updateBakery(
                                    context, updatedBakery, oldimage!);
                              }
                            } catch (e) {
                              print('_buildSaveButton: Error updating bakery: $e');
                            }

                            setState(() {
                              _isSaving = false;
                            });
                          } else {
                            print('_buildSaveButton: Form validation failed');
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        },
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppLocalizations.of(context)!.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB8C00),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          print(
                              '_buildSaveButton: Save localization button pressed');
                          setState(() {
                            _isSaving = true;
                          });

                          try {
                            await BakeryService()
                                .updateBakeryLocalization(context, bakery!.id);
                            print(
                                '_buildSaveButton: Localization updated successfully');
                          } catch (e) {
                            print(
                                '_buildSaveButton: Error updating localization: $e');
                          }

                          setState(() {
                            _isSaving = false;
                          });
                          fetchData();
                        },
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppLocalizations.of(context)!.save_new_localization,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCustomTextField(
      TextEditingController controller, String hintText, IconData icon,
      {String? Function(String?)? validator}) {
    return CustomTextField(
      controller: controller,
      labelText: hintText,
      icon: Icon(icon),
      validator: validator,
    );
  }
}