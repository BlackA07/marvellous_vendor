// lib/features/auth/views/signup_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/metallic_button.dart';
import '../../../core/widgets/metallic_textfield.dart';
import '../../../core/widgets/trapezoid_button.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  void _showImagePickerDialog(
    BuildContext context,
    WidgetRef ref, {
    bool isStoreImage = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Select Image Source',
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: Text(
                'Camera',
                style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 18),
              ),
              onTap: () {
                Navigator.pop(ctx);
                if (isStoreImage) {
                  ref
                      .read(authViewModelProvider)
                      .pickAndCropStoreImage(context, ImageSource.camera);
                } else {
                  ref
                      .read(authViewModelProvider)
                      .pickFaceImage(ImageSource.camera);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: Text(
                'Gallery',
                style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 18),
              ),
              onTap: () {
                Navigator.pop(ctx);
                if (isStoreImage) {
                  ref
                      .read(authViewModelProvider)
                      .pickAndCropStoreImage(context, ImageSource.gallery);
                } else {
                  ref
                      .read(authViewModelProvider)
                      .pickFaceImage(ImageSource.gallery);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NAYA HELPER: category/sub-category add dialog ke andar image pick + crop karta hai
  Future<void> _pickCategoryImage(
    BuildContext context,
    void Function(void Function()) setDialogState,
    void Function(Uint8List) onPicked,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setDialogState(() => onPicked(bytes));
      return;
    }

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF2A2D3E),
          toolbarWidgetColor: Colors.white,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
    if (cropped != null) {
      final bytes = await cropped.readAsBytes();
      setDialogState(() => onPicked(bytes));
    }
  }

  void _showCategoryDialog(BuildContext context, AuthViewModel viewModel) {
    final searchCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    Uint8List? pickedBytes;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final List<Map<String, dynamic>> filtered =
              viewModel.categoryMaps
                  .where(
                    (c) => c['name'].toString().toLowerCase().contains(
                      searchCtrl.text.toLowerCase(),
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a['name'].toString().compareTo(b['name'].toString()),
                );

          return Dialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "Add Category",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "New categories will be saved after admin approval",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search categories...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // List — fixed height
                    if (filtered.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final name = item['name'].toString();
                            final imgUrl = item['imageUrl']?.toString() ?? '';
                            final isSelected = viewModel.selectedCategories
                                .contains(name);
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.white12,
                                backgroundImage: imgUrl.isNotEmpty
                                    ? NetworkImage(imgUrl)
                                    : null,
                                child: imgUrl.isEmpty
                                    ? const Icon(
                                        Icons.image,
                                        size: 14,
                                        color: Colors.white38,
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.blueAccent,
                                      size: 18,
                                    )
                                  : null,
                              onTap: () {
                                viewModel.addSelectedCategory(name);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),

                    if (filtered.isEmpty && searchCtrl.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "No match found",
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),

                    // Divider
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "OR ADD NEW",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                    ),

                    // ✅ NAYA: image picker for new category
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickCategoryImage(
                          context,
                          setDialogState,
                          (bytes) => pickedBytes = bytes,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white12,
                          backgroundImage: pickedBytes != null
                              ? MemoryImage(pickedBytes!) as ImageProvider
                              : null,
                          child: pickedBytes == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white54,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        "Tap to add image (optional)",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // New category field
                    TextField(
                      controller: newCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type New Category",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (newCtrl.text.trim().isEmpty) return;
                                  setDialogState(() => isSaving = true);
                                  await viewModel.addNewCategoryLocally(
                                    newCtrl.text.trim(),
                                    imageBytes: pickedBytes,
                                  );
                                  Navigator.pop(ctx);
                                },
                          child: isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Add",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSubCategoryDialog(BuildContext context, AuthViewModel viewModel) {
    if (viewModel.selectedCategories.isEmpty) {
      Get.snackbar(
        "Notice",
        "Please select a Category first!",
        backgroundColor: Colors.orange,
      );
      return;
    }

    final searchCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? selectedParentCatForNew = viewModel.selectedCategories.first;
    Uint8List? pickedBytes;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Collect all subs (with image) from selected categories
          final List<Map<String, dynamic>> filtered =
              viewModel.availableSubCategoryMaps
                  .where(
                    (s) => s['name'].toString().toLowerCase().contains(
                      searchCtrl.text.toLowerCase(),
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a['name'].toString().compareTo(b['name'].toString()),
                );

          return Dialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "Add Sub-Category",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "New sub-categories will be saved after admin approval",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search sub-categories...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // List — fixed height
                    if (filtered.isNotEmpty)
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final name = item['name'].toString();
                            final imgUrl = item['imageUrl']?.toString() ?? '';
                            final isSelected = viewModel.selectedSubCategories
                                .contains(name);
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.white12,
                                backgroundImage: imgUrl.isNotEmpty
                                    ? NetworkImage(imgUrl)
                                    : null,
                                child: imgUrl.isEmpty
                                    ? const Icon(
                                        Icons.subdirectory_arrow_right,
                                        size: 14,
                                        color: Colors.white38,
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.greenAccent
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.greenAccent,
                                      size: 18,
                                    )
                                  : null,
                              onTap: () {
                                viewModel.addSelectedSubCategory(name);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),

                    if (filtered.isEmpty && searchCtrl.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "No match found",
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),

                    // Divider
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "OR ADD NEW",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                    ),

                    // Parent category dropdown
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: const TextStyle(color: Colors.white),
                      value: selectedParentCatForNew,
                      decoration: InputDecoration(
                        labelText: "Under which Category?",
                        labelStyle: const TextStyle(color: Colors.blueAccent),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: viewModel.selectedCategories
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedParentCatForNew = val),
                    ),
                    const SizedBox(height: 10),

                    // ✅ NAYA: image picker for new sub-category
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickCategoryImage(
                          context,
                          setDialogState,
                          (bytes) => pickedBytes = bytes,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white12,
                          backgroundImage: pickedBytes != null
                              ? MemoryImage(pickedBytes!) as ImageProvider
                              : null,
                          child: pickedBytes == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white54,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        "Tap to add image (optional)",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // New sub-category field
                    TextField(
                      controller: newCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type New Sub-Category",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (newCtrl.text.trim().isEmpty ||
                                      selectedParentCatForNew == null) {
                                    return;
                                  }
                                  setDialogState(() => isSaving = true);
                                  await viewModel.addNewSubCategoryLocally(
                                    selectedParentCatForNew!,
                                    newCtrl.text.trim(),
                                    imageBytes: pickedBytes,
                                  );
                                  Navigator.pop(ctx);
                                },
                          child: isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageWidget(
    XFile xfile, {
    double height = 80,
    double width = 80,
    BoxFit fit = BoxFit.cover,
  }) {
    if (kIsWeb) {
      return Image.network(xfile.path, height: height, width: width, fit: fit);
    } else {
      return Image.file(
        File(xfile.path),
        height: height,
        width: width,
        fit: fit,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(authViewModelProvider);
    String todayDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      todayDate,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "Vendor Signup",
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () =>
                      _showImagePickerDialog(context, ref, isStoreImage: false),
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 3),
                      color: Colors.black54,
                    ),
                    child: viewModel.faceImageFile != null
                        ? ClipOval(
                            child: _buildImageWidget(
                              viewModel.faceImageFile!,
                              height: 120,
                              width: 120,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white54,
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Profile Photo *",
                  style: GoogleFonts.comicNeue(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                MetallicTextField(
                  hintText: "Store Name",
                  icon: Icons.store,
                  controller: viewModel.storeNameCtrl,
                ),
                _buildPhoneField(
                  viewModel.storePhoneCtrl,
                  (c) => viewModel.selectedCountryCode = c.dialCode ?? '+92',
                  "Store Phone",
                ),
                MetallicTextField(
                  hintText: "Owner Name",
                  icon: Icons.person,
                  controller: viewModel.ownerNameCtrl,
                ),
                _buildPhoneField(
                  viewModel.ownerMobileCtrl,
                  (c) => viewModel.selectedCountryCode = c.dialCode ?? '+92',
                  "Owner Mobile",
                ),
                MetallicTextField(
                  hintText: "Contact Person",
                  icon: Icons.support_agent,
                  controller: viewModel.contactPersonCtrl,
                ),
                _buildPhoneField(
                  viewModel.contactPersonPhoneCtrl,
                  (c) => viewModel.selectedCountryCode = c.dialCode ?? '+92',
                  "Contact Phone",
                ),
                MetallicTextField(
                  hintText: "Email Address",
                  icon: Icons.email,
                  controller: viewModel.emailCtrl,
                ),
                MetallicTextField(
                  hintText: "Complete Store Address",
                  icon: Icons.location_on,
                  controller: viewModel.addressCtrl,
                ),

                const SizedBox(height: 15),
                _buildDynamicChips(
                  "Categories",
                  viewModel.selectedCategories,
                  () => _showCategoryDialog(context, viewModel),
                  (cat) => viewModel.removeSelectedCategory(cat),
                ),
                const SizedBox(height: 10),
                _buildDynamicChips(
                  "Sub Categories",
                  viewModel.selectedSubCategories,
                  () => _showSubCategoryDialog(context, viewModel),
                  (cat) => viewModel.removeSelectedSubCategory(cat),
                ),

                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Store Pictures (Max 4)",
                    style: GoogleFonts.comicNeue(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...List.generate(
                        viewModel.storeImageFiles.length,
                        (index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImageWidget(
                                viewModel.storeImageFiles[index],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => viewModel.removeStoreImage(index),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (viewModel.storeImageFiles.length < 4)
                        GestureDetector(
                          onTap: () => _showImagePickerDialog(
                            context,
                            ref,
                            isStoreImage: true,
                          ),
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Beginning Balance",
                    style: GoogleFonts.comicNeue(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                MetallicTextField(
                  hintText: "Default is 0",
                  icon: Icons.account_balance_wallet,
                  controller: viewModel.balanceCtrl,
                ),

                MetallicTextField(
                  hintText: "Password",
                  icon: Icons.lock,
                  isPassword: viewModel.isPassHidden,
                  controller: viewModel.passCtrl,
                ),
                MetallicTextField(
                  hintText: "Confirm Password",
                  icon: Icons.lock_outline,
                  isPassword: viewModel.isPassHidden,
                  controller: viewModel.confirmPassCtrl,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => viewModel.togglePassVisibility(),
                    icon: Icon(
                      viewModel.isPassHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                    label: Text(
                      viewModel.isPassHidden ? "Show" : "Hide",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                viewModel.isLoading
                    ? const CircularProgressIndicator()
                    : TrapezoidButton(
                        imagePath: 'assets/images/signupbutton.png',
                        onTap: () => viewModel.signUp(context),
                      ),

                const SizedBox(height: 30),
                MetallicButton(
                  text: "LOGIN INSTEAD",
                  onTap: () => Get.off(() => const LoginScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(
    TextEditingController ctrl,
    Function(CountryCode) onChanged,
    String hint,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            onChanged: onChanged,
            initialSelection: 'PK',
            textStyle: const TextStyle(color: Colors.white),
            dialogBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicChips(
    String title,
    List<String> list,
    VoidCallback onAdd,
    Function(String) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.comicNeue(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green, size: 35),
              onPressed: onAdd,
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list
              .map(
                (item) => Chip(
                  label: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blueAccent,
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                  onDeleted: () => onRemove(item),
                ),
              )
              .toList(),
        ),
        if (list.isEmpty)
          Text(
            "No $title selected",
            style: const TextStyle(
              color: Color.fromARGB(136, 0, 0, 0),
              fontSize: 16,
            ),
          ),
      ],
    );
  }
}
