// lib/features/splash/views/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/views/login_screen.dart';
import '../../auth/views/pending_approval_screen.dart';
import '../../dashboard/views/dashboard_screen.dart'; // ✅ Dashboard Import add kiya

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // 3 seconds ka splash delay
    await Future.delayed(const Duration(seconds: 3));

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Agar user login nahi hai to Login screen par bhejein
      Get.offAll(() => const LoginScreen());
    } else {
      // Agar user login hai to Firestore se uska status check karein
      try {
        DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(currentUser.uid)
            .get();

        if (vendorDoc.exists) {
          String status = vendorDoc.get('status');
          if (status == 'pending') {
            Get.offAll(() => const PendingApprovalScreen());
          } else if (status == 'approved') {
            // ✅ FIX: Auto-login ke baad DashboardScreen par navigate karein
            Get.offAll(() => const DashboardScreen());
          } else {
            // Agar rejected hai to signout karke Login par bhejein
            await FirebaseAuth.instance.signOut();
            Get.offAll(() => const LoginScreen());
            Get.snackbar(
              "Rejected",
              "Your account was rejected by Admin.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          Get.offAll(() => const LoginScreen());
        }
      } catch (e) {
        await FirebaseAuth.instance.signOut();
        Get.offAll(() => const LoginScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo1.png', height: 120, width: 120),
              const SizedBox(height: 20),
              Text(
                'VENDOR PANEL',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(letterSpacing: 2.0),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.black87),
            ],
          ),
        ),
      ),
    );
  }
}
