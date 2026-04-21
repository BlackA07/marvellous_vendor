// lib/features/auth/views/pending_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/app_background.dart';
import '../../dashboard/views/dashboard_screen.dart'; // Dashboard Screen ka import
import 'login_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen(); // Agar by chance user null ho jaye
    }

    return Scaffold(
      body: AppBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vendors')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            // --- Live Real-time Status Check ---
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              String status = snapshot.data!.get('status');

              if (status == 'approved') {
                // Agar status approved ho gaya to automatically Dashboard par bhej dein
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAll(() => const DashboardScreen());
                  Get.snackbar(
                    "Approved! 🎉",
                    "Your account has been approved by Admin. Welcome to your Dashboard!",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 5),
                  );
                });
              } else if (status == 'rejected') {
                // Agar reject ho gaya tab Login par bhej dein
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(() => const LoginScreen());
                  Get.snackbar(
                    "Account Rejected",
                    "Your application was rejected by Admin.",
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                });
              }
            }

            // --- Waiting UI ---
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        size: 80,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Account Under Review",
                        style: GoogleFonts.comicNeue(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Your vendor account request has been successfully submitted. It is currently under review by the Admin.\n\nPlease wait here or check back later. You will be redirected automatically once a decision is made.",
                        style: GoogleFonts.comicNeue(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      const CircularProgressIndicator(
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 20),

                      // Agar user wait nahi karna chahta to wapis login par ja sakta hai
                      TextButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Get.offAll(() => const LoginScreen());
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.blueAccent,
                        ),
                        label: Text(
                          "Back to Login",
                          style: GoogleFonts.comicNeue(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
