import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'app_theme.dart';
import 'bluetooth_connection_screen.dart';
import 'bluetooth_service.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'progress_graph_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userKey;

  const HomeScreen({super.key, required this.userKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  Future<void> saveDailyHistory(
      Map data,
      int stepGoal,
      int calorieGoal,
      ) async {
    final today = DateTime.now().toString().substring(0, 10);
    final historyRef = FirebaseDatabase.instance.ref("history/$today");

    await historyRef.update({
      "steps": data["steps"] ?? 0,
      "calories": data["calories"] ?? 0,
      "weight": data["weight"] ?? 0,
      "stepGoal": stepGoal,
      "calorieGoal": calorieGoal,
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(
        userKey: widget.userKey,
        saveHistory: saveDailyHistory,
      ),
      const HistoryScreen(),
      ProfileScreen(userKey: widget.userKey),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [appShadow()],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  final String userKey;
  final Future<void> Function(Map, int, int) saveHistory;

  const Dashboard({
    super.key,
    required this.userKey,
    required this.saveHistory,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ble = BluetoothService.instance;

  @override
  void initState() {
    super.initState();
    // Auto-connect on startup. If already connected this is a no-op
    // (BluetoothService guards against duplicate connections).
    ble.connectAndListen();
  }

  Future<void> _showEditTodayGoalDialog(
      BuildContext context,
      int currentStepGoal,
      int currentCalorieGoal,
      ) async {
    final stepController =
    TextEditingController(text: currentStepGoal.toString());
    final calorieController =
    TextEditingController(text: currentCalorieGoal.toString());

    final today = DateTime.now().toString().substring(0, 10);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          "Edit Today's Goals",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "These goals will apply only for today ($today). Your default profile goals will not change.",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: stepController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Today's Step Goal",
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: calorieController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Today's Calorie Goal",
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              final stepGoal = int.tryParse(stepController.text.trim());
              final calorieGoal =
              int.tryParse(calorieController.text.trim());

              if (stepGoal == null || calorieGoal == null) return;

              await FirebaseDatabase.instance
                  .ref("users/${widget.userKey}/dailyGoals/$today")
                  .set({
                "stepGoal": stepGoal,
                "calorieGoal": calorieGoal,
              });

              if (!mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.navy,
                  content: Text(
                    "Today's goals updated",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              );

              setState(() {});
            },
            child: Text("Save", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseDatabase.instance.ref("users/${widget.userKey}");

    return StreamBuilder<Map<String, dynamic>>(
      stream: ble.sensorStream,
      initialData: ble.lastData,
      builder: (context, bleSnap) {
        final data = bleSnap.data ?? ble.lastData;

        final steps = data["steps"] ?? 0;
        final calories = data["calories"] ?? 0;
        final temp = data["temperature"] ?? 0;
        final humidity = data["humidity"] ?? 0;
        final weight = data["weight"] ?? 0;
        final fall = data["fall"] ?? false;

        if (fall == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  "Warning",
                  style:
                  GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                content: Text(
                  "Fall detected from smart shoe.",
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK", style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            );
          });
        }

        return StreamBuilder<DatabaseEvent>(
          stream: user.onValue,
          builder: (context, userSnap) {
            if (!userSnap.hasData ||
                userSnap.data?.snapshot.value == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = Map<dynamic, dynamic>.from(
              userSnap.data!.snapshot.value as Map,
            );

            final defaultGoals =
            Map<dynamic, dynamic>.from(userData["defaultGoals"] ?? {});
            final dailyGoals =
            Map<dynamic, dynamic>.from(userData["dailyGoals"] ?? {});

            final today = DateTime.now().toString().substring(0, 10);
            final todayGoals = dailyGoals[today] != null
                ? Map<dynamic, dynamic>.from(dailyGoals[today])
                : <dynamic, dynamic>{};

            final int stepGoal =
            (todayGoals["stepGoal"] ?? defaultGoals["stepGoal"] ?? 1)
            as int;
            final int calGoal = (todayGoals["calorieGoal"] ??
                defaultGoals["calorieGoal"] ??
                1) as int;

            final String name = (userData["name"] ?? "User").toString();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.saveHistory(data, stepGoal, calGoal);
            });

            double stepPercent = stepGoal > 0 ? steps / stepGoal : 0;
            double calPercent = calGoal > 0 ? calories / calGoal : 0;

            if (stepPercent > 1) stepPercent = 1;
            if (calPercent > 1) calPercent = 1;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.fromLTRB(20, 40, 20, 90),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFAE58C),
                            Color(0xFFFFF4BF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Text(
                          "Hello, $name",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.fromLTRB(18, 30, 18, 24),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Let's track your\nfitness today",
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                height: 1.08,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Live values are now coming from the shoe through Bluetooth.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [appShadow()],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Goals",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Step Goal: $stepGoal",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    "Calorie Goal: $calGoal",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showEditTodayGoalDialog(
                                          context,
                                          stepGoal,
                                          calGoal,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.navy,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        "Edit Today's Goals",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _progressCard(
                              title: "Daily Steps",
                              subtitle: "Goal tracking",
                              value: "$steps",
                              unit: "steps",
                              percentText:
                              "${(stepPercent * 100).toStringAsFixed(0)}%",
                              goalText: "Goal: $stepGoal",
                              percent: stepPercent,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.navy,
                                  AppColors.blue,
                                  AppColors.softBlue,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _progressCard(
                              title: "Calories Burned",
                              subtitle: "Daily energy output",
                              value: "$calories",
                              unit: "kcal",
                              percentText:
                              "${(calPercent * 100).toStringAsFixed(0)}%",
                              goalText: "Goal: $calGoal",
                              percent: calPercent,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0C356A),
                                  Color(0xFF3B6EA5),
                                  Color(0xFF7DA0CA),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Environment",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniCard(
                                    icon: Icons.thermostat_rounded,
                                    iconColor: Colors.redAccent,
                                    value: "$temp°C",
                                    label: "Temperature",
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _miniCard(
                                    icon: Icons.water_drop_rounded,
                                    iconColor: Colors.blue,
                                    value: "$humidity%",
                                    label: "Humidity",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.lightBlue,
                                    Colors.white,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [appShadow()],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color:
                                      AppColors.navy.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.monitor_weight_rounded,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current body weight",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$weight kg",
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(
                              "Quick Actions",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 118,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ActionTile(
                                    icon: Icons.location_on_rounded,
                                    title: "View Shoe Location",
                                    subtitle: "Open live location map",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const MapScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 14),
                                  ActionTile(
                                    icon: Icons
                                        .local_fire_department_rounded,
                                    title: "Calorie Progress",
                                    subtitle: "Monthly calories graph",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const ProgressGraphScreen(
                                            title:
                                            "My Calories Burning Progress",
                                            dataKey: "calories",
                                            lineColor: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 14),
                                  ActionTile(
                                    icon:
                                    Icons.directions_walk_rounded,
                                    title: "Step Progress",
                                    subtitle: "Monthly steps graph",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const ProgressGraphScreen(
                                            title:
                                            "My Stepcount Progress",
                                            dataKey: "steps",
                                            lineColor: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            // ── BLE status / connection button ──────
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BluetoothConnectionScreen(
                                          userKey: widget.userKey,
                                          showBackButton: true,
                                        ),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 350),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: ble.isConnected
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius:
                                  BorderRadius.circular(18),
                                  border: Border.all(
                                    color: ble.isConnected
                                        ? Colors.green.shade300
                                        : Colors.red.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (ble.isConnected
                                          ? Colors.green
                                          : Colors.red)
                                          .withOpacity(0.10),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      ble.isConnected
                                          ? Icons
                                          .bluetooth_connected_rounded
                                          : Icons
                                          .bluetooth_disabled_rounded,
                                      color: ble.isConnected
                                          ? Colors.green.shade600
                                          : Colors.red.shade400,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      ble.isConnected
                                          ? "Connected to Smart Shoe"
                                          : "Connect to Smart Shoe",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: ble.isConnected
                                            ? Colors.green.shade700
                                            : Colors.red.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _progressCard({
    required String title,
    required String subtitle,
    required String value,
    required String unit,
    required String percentText,
    required String goalText,
    required double percent,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [appShadow()],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  percentText,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  goalText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 66,
            lineWidth: 14,
            percent: percent,
            progressColor: AppColors.orangeAccent,
            backgroundColor: Colors.white.withOpacity(0.35),
            circularStrokeCap: CircularStrokeCap.round,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF1F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [appShadow()],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<ActionTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => pressed = false),
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppGradients.cardBlue,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [appShadow()],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}