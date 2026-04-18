import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String userKey;

  const ProfileScreen({super.key, required this.userKey});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final stepGoalController = TextEditingController();
  final calorieGoalController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isEditMode = false;
  String message = "";

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    try {
      final ref = FirebaseDatabase.instance.ref("users/${widget.userKey}");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final defaultGoals =
        Map<dynamic, dynamic>.from(data["defaultGoals"] ?? {});

        nameController.text = data["name"]?.toString() ?? "";
        stepGoalController.text = defaultGoals["stepGoal"]?.toString() ?? "";
        calorieGoalController.text =
            defaultGoals["calorieGoal"]?.toString() ?? "";
      }

      setState(() => isLoading = false);
    } catch (_) {
      setState(() {
        isLoading = false;
        message = "Failed to load profile";
      });
    }
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final stepGoalText = stepGoalController.text.trim();
    final calorieGoalText = calorieGoalController.text.trim();

    if (name.isEmpty || stepGoalText.isEmpty || calorieGoalText.isEmpty) {
      setState(() => message = "Please fill all fields");
      return;
    }

    final stepGoal = int.tryParse(stepGoalText);
    final calorieGoal = int.tryParse(calorieGoalText);

    if (stepGoal == null || calorieGoal == null) {
      setState(() => message = "Goals must be numbers");
      return;
    }

    setState(() {
      isSaving = true;
      message = "";
    });

    try {
      await FirebaseDatabase.instance.ref("users/${widget.userKey}").update({
        "name": name,
      });

      await FirebaseDatabase.instance
          .ref("users/${widget.userKey}/defaultGoals")
          .update({
        "stepGoal": stepGoal,
        "calorieGoal": calorieGoal,
      });

      setState(() {
        isSaving = false;
        isEditMode = false;
        message = "Profile edited";
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          content: Text(
            "Profile edited",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
    } catch (_) {
      setState(() {
        isSaving = false;
        message = "Failed to save profile";
      });
    }
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.2),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    stepGoalController.dispose();
    calorieGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Set your default goals and personal details",
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
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.white,
                            AppColors.lightBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [appShadow()],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            readOnly: !isEditMode,
                            style: GoogleFonts.poppins(),
                            decoration: decoration("Name"),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: stepGoalController,
                            readOnly: !isEditMode,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(),
                            decoration: decoration("Default Daily Step Goal"),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: calorieGoalController,
                            readOnly: !isEditMode,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(),
                            decoration:
                            decoration("Default Daily Calorie Goal"),
                          ),
                          const SizedBox(height: 18),
                          if (message.isNotEmpty)
                            Text(
                              message,
                              style: GoogleFonts.poppins(
                                color: message == "Profile edited"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isEditMode
                                  ? (isSaving ? null : saveProfile)
                                  : () => setState(() {
                                isEditMode = true;
                                message = "";
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                isEditMode ? "Save" : "Edit",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
