import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/classes/PrimaryMaterialActivity.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
import 'package:flutter_application/services/emloyees/PrimaryMaterialActivitiesService.dart';
import 'package:flutter_application/services/manager/managment_employees.dart';
import 'package:flutter_application/services/users/user_service.dart';
import 'package:flutter_application/view/user/ShowUserInfoPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PrimaryMaterialDetailsPage extends StatefulWidget {
  final PrimaryMaterial material;

  const PrimaryMaterialDetailsPage({
    Key? key,
    required this.material,
  }) : super(key: key);

  @override
  _PrimaryMaterialDetailsPageState createState() => _PrimaryMaterialDetailsPageState();
}

class _PrimaryMaterialDetailsPageState extends State<PrimaryMaterialDetailsPage> {
  List<PrimaryMaterialActivity> activities = [];
  bool isLoading = true;
  String? errorMessage;
  Map<int, UserClass?> _userCache = {};
  List<UserClass> employees = [];
  String? timePeriod = 'all_time';
  int? selectedEmployeeId;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchActivities();
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await ManagementEmployeesService().searchemployees(
        context,
        page: 1,
      );
      if (response != null) {
        setState(() {
          employees = response.data;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'errorFetchingEmployees'}: $e')),
      );
    }
  }

  Future<void> _fetchActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await PrimaryMaterialActivitiesService().getActivitiesByMaterialId(
        context,
        widget.material.id,
        timePeriod: timePeriod,
        employeeId: selectedEmployeeId,
        specificDate: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null,
      );
      setState(() {
        activities = response?.data ?? [];
        isLoading = false;
      });
      if (activities.isEmpty) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.noActivitiesFound;
        });
      }
      for (var activity in activities) {
        if (!_userCache.containsKey(activity.userId)) {
          _fetchUser(activity.userId);
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '${AppLocalizations.of(context)!.errorFetchingData}: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  Future<void> _fetchUser(int userId) async {
    if (_userCache[userId] == null) {
      final userService = UserService();
      final user = await userService.getUserbyId(userId, context);
      setState(() {
        _userCache[userId] = user;
      });
    }
  }

  List<FlSpot> _getChartData() {
    final sortedActivities = activities
      ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    double cumulativeQuantity = 0;
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedActivities.length; i++) {
      final activity = sortedActivities[i];
      if (activity.type == 'Ajout') {
        cumulativeQuantity += activity.quantity;
      } else if (activity.type == 'Retrait') {
        cumulativeQuantity -= activity.quantity;
      }
      spots.add(FlSpot(i.toDouble(), cumulativeQuantity));
    }
    return spots;
  }

  bool _isNewActivity(PrimaryMaterialActivity activity) {
    final now = DateTime.now();
    final difference = now.difference(activity.createdAt ?? DateTime.now());
    return difference.inHours <= 24;
  }

  Widget _buildMaterialImage({required bool isWeb}) {
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
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: widget.material.image.isNotEmpty ? ApiConfig.changePathImage(widget.material.image) : '',
              width: isWeb ? 250 : 200,
              height: isWeb ? 250 : 200,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialDetails({required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.materialName,
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.material.name,
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.materialCost,
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${double.parse(widget.material.cost).toStringAsFixed(3)} ${AppLocalizations.of(context)!.currency}',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalQuantity,
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.material.reelQuantity.toStringAsFixed(3)} ${widget.material.unit}',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTrend({required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)!.activityTrend,
              style: TextStyle(
                fontSize: isWeb ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)))
              : errorMessage != null
                  ? Center(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isWeb ? 18 : 16,
                        ),
                      ),
                    )
                  : Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        height: isWeb ? 300 : 250,
                        padding: const EdgeInsets.all(16.0),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final date = activities.isNotEmpty && value.toInt() < activities.length
                                        ? DateFormat('MM-dd').format(activities[value.toInt()].createdAt ?? DateTime.now())
                                        : '';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        date,
                                        style: TextStyle(
                                          fontSize: isWeb ? 14 : 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    );
                                  },
                                  interval: activities.length > 5 ? activities.length / 5 : 1,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: isWeb ? 14 : 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey.withOpacity(0.5)),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getChartData(),
                                isCurved: true,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFB8C00), Color(0xFFFFA726)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                barWidth: 5,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 6,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: const Color(0xFFFB8C00),
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFB8C00).withOpacity(0.3),
                                      const Color(0xFFFFA726).withOpacity(0.1),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                shadow: const Shadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 10,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final index = touchedSpot.x.toInt();
                                    if (index >= 0 && index < activities.length) {
                                      final activity = activities[index];
                                      final date = DateFormat('yyyy-MM-dd HH:mm').format(activity.createdAt ?? DateTime.now());
                                      final quantityText = '${activity.quantity} ${widget.material.unit} (${activity.type})';
                                      final priceText = activity.priceFacture != null
                                          ? '${activity.priceFacture!.toStringAsFixed(3)} ${AppLocalizations.of(context)!.currency}'
                                          : '';
                                      final user = _userCache[activity.userId];
                                      final userName = user?.name ?? 'Loading...';
                                      final userEmail = user?.email ?? 'Loading...';
                                      final userRole = user?.role ?? 'Loading...';
                                      return LineTooltipItem(
                                        '',
                                        const TextStyle(),
                                        children: [
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.date}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '$date\n',
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.description}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${activity.libelle}\n',
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.quantity}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '$quantityText\n',
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.action}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${activity.action}\n',
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.justification}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${activity.justification}\n',
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (activity.priceFacture != null)
                                            TextSpan(
                                              text: '${AppLocalizations.of(context)!.invoicePrice}: ',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (activity.priceFacture != null)
                                            TextSpan(
                                              text: '$priceText\n',
                                              style: const TextStyle(
                                                color: Color(0xFFFB8C00),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.user}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '$userName\n',
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.email}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '$userEmail\n',
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${AppLocalizations.of(context)!.role}: ',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: userRole,
                                            style: const TextStyle(
                                              color: Color(0xFFFB8C00),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return null;
                                  }).toList();
                                },
                              ),
                              handleBuiltInTouches: true,
                            ),
                            minY: _getChartData().isNotEmpty
                                ? _getChartData().map((e) => e.y).reduce((a, b) => a < b ? a : b) - 10
                                : 0,
                            maxY: _getChartData().isNotEmpty
                                ? _getChartData().map((e) => e.y).reduce((a, b) => a > b ? a : b) + 10
                                : 100,
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildFilters({required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.timePeriod,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  value: timePeriod,
                  items: [
                    DropdownMenuItem(value: 'this_day', child: Text(AppLocalizations.of(context)!.thisDay)),
                    DropdownMenuItem(value: 'this_week', child: Text(AppLocalizations.of(context)!.thisWeek)),
                    DropdownMenuItem(value: 'this_month', child: Text(AppLocalizations.of(context)!.thisMonth)),
                    DropdownMenuItem(value: 'all_time', child: Text(AppLocalizations.of(context)!.allTime)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      timePeriod = value;
                      if (value != 'this_day') selectedDate = null;
                      _fetchActivities();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.employee,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  value: selectedEmployeeId,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(AppLocalizations.of(context)!.allEmployees),
                    ),
                    ...employees.map((employee) => DropdownMenuItem(
                          value: employee.id,
                          child: Text(employee.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedEmployeeId = value;
                      _fetchActivities();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (timePeriod == 'this_day')
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.selectDate,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFFFB8C00)),
              ),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                    _fetchActivities();
                  });
                }
              },
              controller: TextEditingController(
                text: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : '',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityDetails({required bool isWeb}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(12.0),
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
          child: Text(
            AppLocalizations.of(context)!.activityDetails,
            style: TextStyle(
              fontSize: isWeb ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        _buildFilters(isWeb: isWeb),
        isLoading
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(12.0),
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
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00))),
              )
            : errorMessage != null
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
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
                    child: Center(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isWeb ? 18 : 16,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final user = _userCache[activity.userId];
                      final userName = user?.name ?? 'Loading...';
                      final userEmail = user?.email ?? 'Loading...';
                      final userRole = user?.role ?? 'Loading...';
                      final userPhone = user?.phone ?? 'Loading...';
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${AppLocalizations.of(context)!.date}: ${DateFormat('yyyy-MM-dd HH:mm').format(activity.createdAt ?? DateTime.now())}',
                                        style: TextStyle(
                                          fontSize: isWeb ? 16 : 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    if (_isNewActivity(activity))
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.newLabel,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isWeb ? 14 : 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppLocalizations.of(context)!.description}: ${activity.libelle}',
                                            style: TextStyle(
                                              fontSize: isWeb ? 18 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${AppLocalizations.of(context)!.quantity}: ${activity.quantity} ${widget.material.unit} (${activity.type})',
                                            style: TextStyle(
                                              fontSize: isWeb ? 16 : 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${AppLocalizations.of(context)!.action}: ${activity.action}',
                                            style: TextStyle(
                                              fontSize: isWeb ? 16 : 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${AppLocalizations.of(context)!.justification}: ${activity.justification}',
                                            style: TextStyle(
                                              fontSize: isWeb ? 16 : 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          if (activity.priceFacture != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                '${AppLocalizations.of(context)!.invoicePrice}: ${activity.priceFacture!.toStringAsFixed(3)} ${AppLocalizations.of(context)!.currency}',
                                                style: TextStyle(
                                                  fontSize: isWeb ? 16 : 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ShowUserInfoPage(
                                          userId: activity.userId,
                                          user: _userCache[activity.userId],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)!.userDetails,
                                                style: TextStyle(
                                                  fontSize: isWeb ? 16 : 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${AppLocalizations.of(context)!.user}: $userName',
                                                style: TextStyle(
                                                  fontSize: isWeb ? 16 : 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              Text(
                                                '${AppLocalizations.of(context)!.email}: $userEmail',
                                                style: TextStyle(
                                                  fontSize: isWeb ? 16 : 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              Text(
                                                '${AppLocalizations.of(context)!.role}: $userRole',
                                                style: TextStyle(
                                                  fontSize: isWeb ? 16 : 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              Text(
                                                '${AppLocalizations.of(context)!.phone}: $userPhone',
                                                style: TextStyle(
                                                  fontSize: isWeb ? 16 : 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.info_outline, color: Color(0xFFFB8C00)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ],
    );
  }

  Future<bool> _onBackPressed() async {
    return true; // Allow navigation back by default
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.materialDetails,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _onBackPressed().then((canPop) {
            if (canPop) Navigator.pop(context);
          }),
        ),
        actions: const [
          NotificationIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildMaterialImage(isWeb: false),
            const SizedBox(height: 16),
            _buildMaterialDetails(isWeb: false),
            const SizedBox(height: 16),
            _buildActivityTrend(isWeb: false),
            const SizedBox(height: 16),
            _buildActivityDetails(isWeb: false),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildMaterialImage(isWeb: true),
            const SizedBox(height: 24),
            _buildMaterialDetails(isWeb: true),
            const SizedBox(height: 24),
            _buildActivityTrend(isWeb: true),
            const SizedBox(height: 24),
            _buildActivityDetails(isWeb: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}