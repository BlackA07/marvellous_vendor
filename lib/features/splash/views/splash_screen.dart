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
    await Future.delayed(const Duration(seconds: 3));

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Get.offAll(() => const LoginScreen());
    } else {
      try {
        DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(currentUser.uid)
            .get();

        if (vendorDoc.exists) {
          String status = vendorDoc.get('status') ?? 'pending';

          if (status == 'approved') {
            Get.offAll(() => const DashboardScreen());
          } else {
            // pending, hold, rejected — sab PendingApprovalScreen pe
            Get.offAll(() => const PendingApprovalScreen());
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
