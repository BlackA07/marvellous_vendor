// lib/core/widgets/trapezoid_button.dart
import 'package:flutter/material.dart';

class TrapezoidButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  final double height;
  final double width;

  const TrapezoidButton({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.height = 90,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        width: width,
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback agar image na ho
            return Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "SIGN UP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
