// lib/features/products/views/widgets/vendor_info_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../viewmodels/vendor_add_product_viewmodel.dart';

class VendorInfoSection extends ConsumerWidget {
  final VendorAddProductViewModel viewModel;
  final VendorAddProductViewModel viewModelNotifier;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;

  const VendorInfoSection({
    super.key,
    required this.viewModel,
    required this.viewModelNotifier,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Product Details"),

        _buildTextField(
          "Product Name *",
          "e.g. iPhone 15 Pro",
          viewModel.nameCtrl,
          ref,
        ),
        _buildTextField("Brand", "e.g. Apple", viewModel.brandCtrl, ref),
        _buildTextField("Model Number", "e.g. A2848", viewModel.modelCtrl, ref),

        // --- Live Categories (Firestore) ---
        _buildCategoryDropdown(context),

        // --- Live Sub-Categories (Firestore) ---
        if (viewModel.selectedCategory != null)
          _buildSubCategoryDropdown(context),

        if (viewModel.isMobile) ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "RAM",
                  "e.g. 8GB",
                  viewModel.ramCtrl,
                  ref,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(
                  "Storage",
                  "e.g. 256GB",
                  viewModel.storageCtrl,
                  ref,
                ),
              ),
            ],
          ),
        ],

        // ✅ Multi-line Description
        _buildTextField(
          "Description *",
          "Enter product details (Multi-line support)...",
          viewModel.descCtrl,
          ref,
          maxLines: 4,
        ),

        const SizedBox(height: 20),

        // ✅ NAYA FIELD: TikTok URL
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TikTok Video URL (Optional)",
              style: GoogleFonts.comicNeue(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: viewModel.tiktokUrlCtrl,
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "https://www.tiktok.com/@user/video/...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: cardColor,
                prefixIcon: const Icon(
                  Icons.link,
                  color: Colors.blueAccent,
                ), // Link icon
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),

        _buildSectionTitle("Pricing (PKR)"),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                "Sale Price(Marvellous) *",
                "0",
                viewModel.purchaseCtrl,
                ref,
                isNumber: true,
                onChanged: (val) {
                  // ✅ FIX: Curly braces for web safety
                  ref.refresh(grossProfitProvider);
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                "Sale Price(Customers) *",
                "0",
                viewModel.saleCtrl,
                ref,
                isNumber: true,
                onChanged: (val) {
                  // ✅ FIX: Curly braces for web safety
                  ref.refresh(grossProfitProvider);
                },
              ),
            ),
          ],
        ),
        _buildTextField(
          "Fake Discounted Price (Optional)",
          "0",
          viewModel.originalCtrl,
          ref,
          isNumber: true,
        ),

        // --- GROSS PROFIT CALCULATION ---
        Consumer(
          builder: (context, localRef, _) {
            final profit = localRef.watch(grossProfitProvider);
            final bool isLoss = profit < 0;
            final Color boxColor = isLoss ? Colors.red : Colors.green;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: boxColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: boxColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gross Profit",
                    style: GoogleFonts.comicNeue(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Rs ${profit.toStringAsFixed(0)}",
                    style: GoogleFonts.orbitron(
                      color: boxColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        _buildSectionTitle("Warranty Options"),

        // --- WARRANTY LOGIC ---
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Duration:",
                style: GoogleFonts.comicNeue(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    <String>[
                      "No Warranty",
                      "6 Months",
                      "1 Year",
                      "2 Years",
                    ].map<Widget>((String opt) {
                      bool isSelected =
                          viewModel.selectedWarrantyDuration == opt;
                      return ChoiceChip(
                        label: Text(
                          opt,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: accentColor,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (bool val) {
                          if (val) {
                            viewModelNotifier.selectedWarrantyDuration = opt;
                            viewModelNotifier.notifyListeners();
                          }
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 15),

              _buildTextField(
                "Custom Warranty",
                "e.g. 5 Years or Life Time",
                viewModel.customWarrantyCtrl,
                ref,
              ),

              const Divider(),

              Text(
                "Warranty Provider:",
                style: GoogleFonts.comicNeue(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CheckboxListTile(
                title: Text(
                  "Company Warranty",
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                value: viewModel.hasCompanyWarranty == true, // ✅ 100% Null-safe
                activeColor: accentColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) =>
                    viewModelNotifier.toggleCompanyWarranty(val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: Text(
                  "Shop Warranty",
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                value: viewModel.hasShopWarranty == true, // ✅ 100% Null-safe
                activeColor: accentColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) =>
                    viewModelNotifier.toggleShopWarranty(val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          color: accentColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController ctrl,
    WidgetRef ref, {
    int maxLines = 1,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.comicNeue(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: maxLines > 1
                ? TextInputType.multiline
                : (isNumber ? TextInputType.number : TextInputType.text),
            textInputAction: maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
            ),
            validator: (val) {
              if (label.contains("Optional") ||
                  label.contains("Custom Warranty"))
                return null;
              if (val == null || val.trim().isEmpty)
                return "This field is required";
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --- Category Dropdown ---
  Widget _buildCategoryDropdown(BuildContext context) {
    String? safeCategory =
        viewModel.categoryNames.contains(viewModel.selectedCategory)
        ? viewModel.selectedCategory
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Category *",
            style: GoogleFonts.comicNeue(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: safeCategory,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text("Select Category"),
                  // ✅ FIX: Strongly typed DropdownMenuItem<String> for Web Safety
                  items: viewModel.categoryNames.map<DropdownMenuItem<String>>((
                    String cat,
                  ) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(
                        cat,
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? val) {
                    viewModelNotifier.selectedCategory = val;
                    viewModelNotifier.selectedSubCategory = null;
                    viewModelNotifier.notifyListeners();
                  },
                  validator: (val) =>
                      val == null ? "Please select a category" : null,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => _showAddDialog(context, isSubCategory: false),
                icon: Icon(Icons.add_circle, color: accentColor, size: 35),
                tooltip: "Add New Category",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sub Category Dropdown ---
  Widget _buildSubCategoryDropdown(BuildContext context) {
    String? safeSubCategory =
        viewModel.availableSubCategories.contains(viewModel.selectedSubCategory)
        ? viewModel.selectedSubCategory
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sub Category",
            style: GoogleFonts.comicNeue(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: safeSubCategory,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text("Select Sub Category"),
                  // ✅ FIX: Strongly typed DropdownMenuItem<String> for Web Safety
                  items: viewModel.availableSubCategories
                      .map<DropdownMenuItem<String>>((String sub) {
                        return DropdownMenuItem<String>(
                          value: sub,
                          child: Text(
                            sub,
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (String? val) {
                    viewModelNotifier.selectedSubCategory = val;
                    viewModelNotifier.notifyListeners();
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => _showAddDialog(context, isSubCategory: true),
                icon: Icon(
                  Icons.add_circle,
                  color: Colors.green.shade600,
                  size: 35,
                ),
                tooltip: "Add Sub Category",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Add Category / SubCategory Dialog ---
  void _showAddDialog(BuildContext context, {required bool isSubCategory}) {
    TextEditingController newCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          isSubCategory ? "Add Sub-Category" : "Add Category",
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: newCtrl,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Enter Name",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () {
              if (newCtrl.text.trim().isNotEmpty) {
                String newName = newCtrl.text.trim();
                Get.back();

                Future.delayed(const Duration(milliseconds: 150), () {
                  if (isSubCategory && viewModel.selectedCategory != null) {
                    viewModelNotifier.addNewSubCategory(
                      viewModel.selectedCategory!,
                      newName,
                    );
                  } else {
                    viewModelNotifier.addNewCategory(newName);
                  }
                });
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
