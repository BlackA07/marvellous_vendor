import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/app_background.dart';
import '../../dashboard/views/dashboard_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    return Scaffold(
      body: AppBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vendors')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              String status = snapshot.data!.get('status') ?? 'pending';

              if (status == 'approved') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAll(() => const DashboardScreen());
                  Get.snackbar(
                    "Approved! 🎉",
                    "Your account has been approved. Welcome!",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 5),
                  );
                });
              }

              if (status == 'hold') {
                String holdReason = '';
                try {
                  holdReason = snapshot.data!.get('holdReason') ?? '';
                } catch (_) {}
                if (holdReason.isEmpty)
                  holdReason = 'No reason provided. Contact admin.';

                return _buildStatusScreen(
                  icon: Icons.pause_circle_outline,
                  iconColor: Colors.amberAccent,
                  title: "Application On Hold",
                  message:
                      "Your vendor application has been put on hold by Admin.\nPlease fix the issue and re-apply.",
                  reason: holdReason,
                  reasonColor: Colors.amber.shade800,
                  reasonBgColor: Colors.amber.shade50,
                  reasonBorderColor: Colors.amber.shade200,
                  buttonLabel: "Back to Login",
                  onButton: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(() => const LoginScreen());
                  },
                  // ✅ Hold: Re-Apply button — data rehta hai, sirf pending ho jaata hai
                  extraButtonLabel: "Edit Info & Re-Apply",
                  extraButtonColor: Colors.amber.shade800,
                  onExtraButton: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(() => const SignupScreen());
                  },
                  showProgress: false,
                );
              }

              if (status == 'rejected') {
                String rejectReason = '';
                try {
                  rejectReason = snapshot.data!.get('rejectionReason') ?? '';
                } catch (_) {}
                if (rejectReason.isEmpty)
                  rejectReason = 'No reason provided. Contact admin.';

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(user.uid)
                        .delete();
                  } catch (_) {}
                  try {
                    await user.delete();
                  } catch (_) {}
                });

                return _buildStatusScreen(
                  icon: Icons.cancel_outlined,
                  iconColor: Colors.redAccent,
                  title: "Application Rejected",
                  message:
                      "Your vendor application was rejected by Admin.\nYour previous data has been cleared.",
                  reason: rejectReason,
                  reasonColor: Colors.red.shade800,
                  reasonBgColor: Colors.red.shade50,
                  reasonBorderColor: Colors.red.shade200,
                  buttonLabel: "Back to Login",
                  onButton: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(() => const LoginScreen());
                  },
                  // ✅ Rejected: New Account button
                  extraButtonLabel: "Create New Account",
                  extraButtonColor: Colors.black,
                  onExtraButton: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(() => const SignupScreen());
                  },
                  showProgress: false,
                );
              }
            }

            // Default: Pending
            return _buildStatusScreen(
              icon: Icons.hourglass_empty,
              iconColor: Colors.orangeAccent,
              title: "Account Under Review",
              message:
                  "Your vendor account request has been submitted. It is under review by Admin.\n\n"
                  "You will be redirected automatically once a decision is made.",
              reason: null,
              buttonLabel: "Back to Login",
              onButton: () async {
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => const LoginScreen());
              },
              showProgress: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String? reason,
    Color? reasonColor,
    Color? reasonBgColor,
    Color? reasonBorderColor,
    required String buttonLabel,
    required VoidCallback onButton,
    String? extraButtonLabel,
    Color? extraButtonColor,
    VoidCallback? onExtraButton,
    required bool showProgress,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
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
                Icon(icon, size: 80, color: iconColor),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (reason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: reasonBgColor ?? Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: reasonBorderColor ?? Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: reasonColor ?? Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Reason: $reason",
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: reasonColor ?? Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (showProgress) ...[
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(color: Colors.orangeAccent),
                ],

                const SizedBox(height: 20),

                // ✅ Extra button (Re-Apply / New Account)
                if (extraButtonLabel != null && onExtraButton != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: extraButtonColor ?? Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onExtraButton,
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        extraButtonLabel,
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                TextButton.icon(
                  onPressed: onButton,
                  icon: const Icon(Icons.logout, color: Colors.blueAccent),
                  label: Text(
                    buttonLabel,
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
      ),
    );
  }
}
