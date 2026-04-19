import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ref = FirebaseDatabase.instance.ref("history");

  Map<dynamic, dynamic> historyData = {};
  bool isLoading = true;
  String? selectedDate;
  bool showDateList = false;
  final Map<String, GlobalKey> itemKeys = {};

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final sortedEntries = data.entries.toList()
        ..sort((a, b) => b.key.toString().compareTo(a.key.toString()));

      historyData = {for (var entry in sortedEntries) entry.key: entry.value};

      for (var key in historyData.keys) {
        itemKeys[key.toString()] = GlobalKey();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void scrollToSelectedDate(String date) {
    final key = itemKeys[date];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateList = historyData.keys.map((e) => e.toString()).toList();

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
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "History",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Review your daily smart shoe results",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.86),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: selectedDate == null
                            ? AppColors.softGrey
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [appShadow()],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setState(() {
                                showDateList = !showDateList;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate ?? "Select a date",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                                ],
                              ),
                            ),
                          ),
                          if (showDateList)
                            Container(
                              width: double.infinity,
                              constraints:
                              const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: AppColors.softGrey,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: dateList.length,
                                itemBuilder: (context, index) {
                                  final date = dateList[index];
                                  return ListTile(
                                    title: Text(
                                      date,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedDate = date;
                                        showDateList = false;
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        scrollToSelectedDate(date);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ListView(
                    children: historyData.entries.map((entry) {
                      final date = entry.key.toString();
                      final values =
                      Map<dynamic, dynamic>.from(entry.value as Map);
                      final isSelected = selectedDate == date;

                      int steps = values["steps"] ?? 0;
                      int stepGoal = values["stepGoal"] ?? 1;
                      int percent = ((steps / stepGoal) * 100).round();
                      if (percent > 100) percent = 100;

                      return Container(
                        key: itemKeys[date],
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                            colors: [
                              Color(0xFFFAE58C),
                              Color(0xFFFFF4BF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : const LinearGradient(
                            colors: [
                              AppColors.softBlue,
                              AppColors.lightBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [appShadow()],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    date,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Steps: ${values["steps"] ?? 0}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    "Calories: ${values["calories"] ?? 0}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    "Weight: ${values["weight"] ?? 0} kg",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    "Step Goal: ${values["stepGoal"] ?? 0}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    "Calorie Goal: ${values["calorieGoal"] ?? 0}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "$percent%",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
