import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
      "January","February","March","April","May","June",
      "July","August","September","October","November","December",
    ];
    return months[month];
  }
}
