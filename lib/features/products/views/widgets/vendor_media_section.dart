// Path: lib/features/products/views/widgets/vendor_media_section.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class VendorMediaSection extends StatelessWidget {
  final List<String> images;
  final Function(ImageSource) onPickImage;
  final Function(int) onRemoveImage;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;

  const VendorMediaSection({
    super.key,
    required this.images,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
  });

  // ✅ FIX: Helper function jo decide karega ke image URL hai ya Base64
  ImageProvider _getImageProvider(String imageData) {
    if (imageData.startsWith('http') || imageData.startsWith('https')) {
      return NetworkImage(imageData);
    } else {
      String cleanBase64 = imageData.contains(',')
          ? imageData.split(',').last
          : imageData;
      return MemoryImage(base64Decode(cleanBase64));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Product Images (Max 4) *",
          style: GoogleFonts.orbitron(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        // Grid for Images + Add Button
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Display Selected Images
            ...List.generate(images.length, (index) {
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: _getImageProvider(
                          images[index],
                        ), // ✅ FIX APPLIED HERE
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: InkWell(
                      onTap: () => onRemoveImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // Add Image Button
            if (images.length < 4)
              GestureDetector(
                onTap: () {
                  // Show Bottom Sheet for Camera/Gallery choice
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.camera_alt,
                            color: Colors.blueAccent,
                          ),
                          title: const Text(
                            "Take Photo",
                            style: TextStyle(fontSize: 18),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            onPickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.photo_library,
                            color: Colors.blueAccent,
                          ),
                          title: const Text(
                            "Choose from Gallery",
                            style: TextStyle(fontSize: 18),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            onPickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: accentColor, size: 30),
                      const SizedBox(height: 5),
                      Text(
                        "Add Photo",
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
