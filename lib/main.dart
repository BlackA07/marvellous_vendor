// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart'; // Naya import
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Riverpod ke liye ProviderScope aur DevicePreview ka setup
  runApp(
    DevicePreview(
      enabled: true, // Isko production mein false kar dijiyega
      builder: (context) => const ProviderScope(child: VendorApp()),
    ),
  );
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vendor App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightGradientTheme,

      // --- Device Preview Configuration for GetX ---
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      home: const SplashScreen(),
    );
  }
}
