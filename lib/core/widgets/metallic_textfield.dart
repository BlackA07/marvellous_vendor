// lib/core/widgets/metallic_textfield.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetallicTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  const MetallicTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
  });

  @override
  State<MetallicTextField> createState() => _MetallicTextFieldState();
}

class _MetallicTextFieldState extends State<MetallicTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            offset: const Offset(2, 4),
            blurRadius: 8,
          ),
        ],
        border: Border.all(
          color: _hasFocus ? const Color(0xFF00E5FF) : Colors.white,
          width: _hasFocus ? 2 : 1,
        ),
      ),
      child: Center(
        child: TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          obscureText: widget.isPassword,
          style: GoogleFonts.comicNeue(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 19,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon, color: Colors.black54),
            hintText: widget.hintText,
            hintStyle: GoogleFonts.comicNeue(
              color: Colors.black38,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }
}
