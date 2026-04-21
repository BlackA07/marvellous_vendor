// lib/features/auth/views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/metallic_button.dart';
import '../../../core/widgets/metallic_textfield.dart';
import '../../../core/widgets/trapezoid_button.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo1.png', height: 120, width: 120),
                const SizedBox(height: 20),
                Text(
                  "Welcome Vendor",
                  style: GoogleFonts.comicNeue(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color.fromARGB(
                      255,
                      0,
                      0,
                      0,
                    ), // Dark background ke hisaab se white rakha hai
                  ),
                ),
                const SizedBox(height: 40),

                MetallicTextField(
                  hintText: "Email Address",
                  icon: Icons.email,
                  controller: viewModel.emailCtrl,
                ),
                MetallicTextField(
                  hintText: "Password",
                  icon: Icons.lock,
                  isPassword: viewModel.isPassHidden,
                  controller: viewModel.passCtrl,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.comicNeue(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                viewModel.isLoading
                    ? const CircularProgressIndicator()
                    : TrapezoidButton(
                        imagePath: 'assets/images/button.png',
                        height: 130,
                        width: 200,
                        onTap: () => viewModel.login(context),
                      ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Get.off(() => const SignupScreen());
                  },
                  child: Text(
                    "New Vendor? Create Account",
                    style: GoogleFonts.comicNeue(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
