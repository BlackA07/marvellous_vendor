// lib/features/splash/views/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_background.dart';
import '../../../main.dart'; // ✅ AuthGate yahan se import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Get.offAll(() => const AuthGate()); // ✅ decision AuthGate karega
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
