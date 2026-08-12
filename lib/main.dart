// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Ye import lazmi add karein
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/views/splash_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/pending_approval_screen.dart';
import 'features/dashboard/views/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    DevicePreview(
      // ✅ Release mode mein enabled: false ho jayega automatically
      enabled: !kReleaseMode,
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
      // ✅ Release mode mein locale aur builder ko handle karna
      locale: kReleaseMode ? null : DevicePreview.locale(context),
      builder: kReleaseMode ? null : DevicePreview.appBuilder,

      // ✅ SplashScreen ki jagah AuthGate — ye khud decide karega
      // Login / PendingApproval (hold/rejected/pending) / Dashboard
      home: const SplashScreen(),
    );
  }
}

// ✅ NAYA: App reopen hone par hamesha sahi screen (status samet) dikhane ke liye
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('vendors')
              .doc(user.uid)
              .get(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!docSnap.hasData || !docSnap.data!.exists) {
              return const LoginScreen();
            }

            final status = docSnap.data!.get('status');

            if (status == 'approved') {
              return const DashboardScreen();
            }

            // ✅ pending / hold / rejected — sab yahan
            // PendingApprovalScreen ke andar StreamBuilder hai jo
            // status/reason hamesha live rakhta hai
            return const PendingApprovalScreen();
          },
        );
      },
    );
  }
}
