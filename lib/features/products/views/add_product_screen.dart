// Path: lib/features/products/views/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../dashboard/viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/vendor_add_product_viewmodel.dart';
import 'widgets/vendor_media_section.dart';
import 'widgets/vendor_info_section.dart';
import '../models/product_model.dart';

class VendorAddProductScreen extends ConsumerStatefulWidget {
  final ProductModel?
  productToEdit; // ✅ If this is passed, it opens in Edit Mode

  const VendorAddProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<VendorAddProductScreen> createState() =>
      _VendorAddProductScreenState();
}

class _VendorAddProductScreenState
    extends ConsumerState<VendorAddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // ✅ NAYA: Screen ko oopar scroll karne ke liye controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // ✅ Initialize Edit Mode if product is passed
    if (widget.productToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(vendorAddProductProvider.notifier)
            .initForEdit(widget.productToEdit!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ Memory leak se bachne ke liye dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(vendorAddProductProvider);
    final viewModelNotifier = ref.read(vendorAddProductProvider.notifier);

    const bgColor = Color(0xFFF5F7FA);
    const cardColor = Colors.white;
    const textColor = Colors.black87;
    const accentColor = Colors.blueAccent;

    void handleFormSubmit() async {
      bool success = await viewModelNotifier.submitProductRequest(
        context,
        _formKey,
      );

      if (success && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              title: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 15),
                  Text(
                    viewModel.isEditMode
                        ? "Edit Request Sent!"
                        : "Request Sent Successfully!",
                    style: GoogleFonts.orbitron(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Text(
                viewModel.isEditMode
                    ? "Your edit request has been sent to the admin. Once approved, the changes will be live."
                    : "Your product has been sent to the Admin for approval. It will appear in your 'My Products' list once approved.",
                style: GoogleFonts.comicNeue(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!viewModel.isEditMode)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_box, color: Colors.white),
                          label: const Text(
                            "Add Another Product",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogContext); // Dialog band karo

                            // ✅ NAYA: Screen ko smoothly top par scroll karo
                            _scrollController.animateTo(
                              0.0,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.dashboard,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          "Go Back",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Get.back();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          viewModel.isEditMode ? "Edit Product" : "Add New Product",
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController, // ✅ NAYA: Controller attach kiya
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text(
                          "Posting as: ",
                          style: GoogleFonts.comicNeue(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          viewModel.currentVendorName.isEmpty
                              ? "Loading..."
                              : viewModel.currentVendorName,
                          style: GoogleFonts.comicNeue(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  VendorMediaSection(
                    images: viewModel
                        .combinedImages, // ✅ Yahan updated list pass karein
                    onPickImage: (source) => viewModelNotifier
                        .pickAndCropStoreImage(context, source),
                    onRemoveImage: (index) =>
                        viewModelNotifier.removeImage(index),
                    cardColor: cardColor,
                    accentColor: accentColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 30),

                  VendorInfoSection(
                    viewModel: viewModel,
                    viewModelNotifier: viewModelNotifier,
                    cardColor: cardColor,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading ? null : handleFormSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              viewModel.isEditMode
                                  ? "SUBMIT EDIT REQUEST"
                                  : "SUBMIT TO ADMIN",
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (viewModel.isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
        ],
      ),
    );
  }
}
