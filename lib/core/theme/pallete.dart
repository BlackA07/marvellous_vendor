// lib/core/theme/pallete.dart
import 'package:flutter/material.dart';

class Pallete {
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color darkHousing = Color(0xFF2C2C2C);

  // Interesting bright gradient background ke liye
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)], // Light Ice-Blue Gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient metallicGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFE6E6E6), Color(0xFFCCCCCC), Color(0xFFFFFFFF)],
  );
}
