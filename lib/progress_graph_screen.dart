import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class ProgressGraphScreen extends StatefulWidget {
  final String title;
  final String dataKey;
  final Color lineColor;

  const ProgressGraphScreen({
    super.key,
    required this.title,
    required this.dataKey,
    required this.lineColor,
  });

  @override
  State<ProgressGraphScreen> createState() => _ProgressGraphScreenState();
}

class _ProgressGraphScreenState extends State<ProgressGraphScreen> {
  final historyRef = FirebaseDatabase.instance.ref("history");

  late int selectedMonth;
  late int currentYear;

  Map<String, dynamic> monthlyData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    currentYear = now.year;
    loadMonthData();
  }

  Future<void> loadMonthData() async {
    setState(() {
      isLoading = true;
      monthlyData = {};
    });

    final snapshot = await historyRef.get();

    if (snapshot.exists) {
      final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final filtered = <String, dynamic>{};

      raw.forEach((key, value) {
        final dateString = key.toString();
        try {
          final date = DateTime.parse(dateString);
          if (date.year == currentYear && date.month == selectedMonth) {
            filtered[dateString] = Map<dynamic, dynamic>.from(value);
          }
        } catch (_) {}
      });

      setState(() {
        monthlyData = filtered;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  List<int> getAvailableMonths() {
    final now = DateTime.now();
    return List.generate(now.month, (index) => index + 1);
  }

  String getMonthName(int month) {
    const months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month];
  }

  List<FlSpot> buildSpots() {
    final entries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final valueMap = Map<dynamic, dynamic>.from(entry.value);
      final rawValue = valueMap[widget.dataKey] ?? 0;
      final yValue = double.tryParse(rawValue.toString()) ?? 0;
      return FlSpot(date.day.toDouble(), yValue);
    }).toList();
  }

  double getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) return 10;
    return maxY + (maxY * 0.2);
  }

  @override
  Widget build(BuildContext context) {
    final spots = buildSpots();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.deepNavy,
              AppColors.navy,
              AppColors.blue,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                decoration: const BoxDecoration(
                  gradient: AppGradients.header,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "View your daily pattern across the selected month",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.lightBlue,
                          labelText: "Select Month",
                          labelStyle: GoogleFonts.poppins(color: AppColors.textDark),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        style: GoogleFonts.poppins(color: AppColors.textDark),
                        items: getAvailableMonths().map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(
                              month == DateTime.now().month
                                  ? "${getMonthName(month)} (This month)"
                                  : getMonthName(month),
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedMonth = value);
                            loadMonthData();
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : spots.isEmpty
                            ? Center(
                          child: Text(
                            "No related data",
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                        )
                            : Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.navy,
                                AppColors.blue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [appShadow()],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${getMonthName(selectedMonth)} Overview",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    minX: 1,
                                    maxX: 31,
                                    minY: 0,
                                    maxY: getMaxY(spots),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: getMaxY(spots) / 5,
                                    ),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.white70,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 5,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                value.toInt().toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        color: AppColors.lightBlue,
                                        barWidth: 4,
                                        dotData: const FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.white.withOpacity(0.14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
