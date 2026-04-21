// lib/core/widgets/metallic_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetallicButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const MetallicButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFC0C0C0)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.comicNeue(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
