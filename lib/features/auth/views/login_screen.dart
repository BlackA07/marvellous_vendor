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
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 40),

                // ✅ Updated to use Login Email Controller
                MetallicTextField(
                  hintText: "Email Address",
                  icon: Icons.email,
                  controller: viewModel.loginEmailCtrl,
                ),

                // ✅ Updated to use Login Password Controller & State
                MetallicTextField(
                  hintText: "Password",
                  icon: Icons.lock,
                  isPassword: viewModel.isLoginPassHidden,
                  controller: viewModel.loginPassCtrl,
                ),

                // ✅ Show Password aur Forgot Password dono aik hi line mein samne samne rakh diye
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- SHOW PASSWORD BUTTON ---
                    TextButton.icon(
                      onPressed: () => viewModel.toggleLoginPassVisibility(),
                      icon: Icon(
                        viewModel.isLoginPassHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                      label: Text(
                        viewModel.isLoginPassHidden ? "Show" : "Hide",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // --- FORGOT PASSWORD BUTTON ---
                    TextButton(
                      onPressed: () {
                        TextEditingController resetEmailCtrl =
                            TextEditingController(
                              text: viewModel.loginEmailCtrl.text,
                            );
                        Get.defaultDialog(
                          title: "Reset Password",
                          content: Column(
                            children: [
                              const Text(
                                "Enter your email to receive a reset link.",
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: resetEmailCtrl,
                                decoration: const InputDecoration(
                                  hintText: "Email Address",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          textConfirm: "Send Link",
                          confirmTextColor: Colors.white,
                          onConfirm: () {
                            Get.back();
                            viewModel.forgotPassword(resetEmailCtrl.text);
                          },
                          textCancel: "Cancel",
                        );
                      },
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.comicNeue(
                          color: Colors.black, // Color black kar diya
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10), // Thori space

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
