import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../viewmodels/vendor_products_controller.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';

class VendorMyProductsScreen extends StatelessWidget {
  const VendorMyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorProductsController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () =>
                Get.back(), // ✅ offAll ki jagah back — dashboard pe wapas
          ),
          title: Text(
            "My Products",
            style: GoogleFonts.comicNeue(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "LIVE PRODUCTS"),
              Tab(text: "PENDING REQUESTS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLiveProductsTab(controller),
            _buildPendingRequestsTab(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveProductsTab(VendorProductsController controller) {
    return Obx(() {
      if (controller.isLoadingLive.value && controller.liveProducts.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      }
      if (controller.liveProducts.isEmpty) {
        return Center(
          child: Text(
            "You have no live products yet.",
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: controller.liveProducts.length,
        itemBuilder: (context, index) {
          return _productCard(
            controller.liveProducts[index],
            controller,
            isLive: true,
          );
        },
      );
    });
  }

  Widget _buildPendingRequestsTab(VendorProductsController controller) {
    return Obx(() {
      if (controller.isLoadingPending.value &&
          controller.pendingRequests.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        );
      }
      if (controller.pendingRequests.isEmpty) {
        return Center(
          child: Text(
            "You have no pending requests.",
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: controller.pendingRequests.length,
        itemBuilder: (context, index) {
          return _productCard(
            controller.pendingRequests[index],
            controller,
            isLive: false,
          );
        },
      );
    });
  }

  // ✅ FIX: Changed id to whole ProductModel to send full data in Delete Request
  void _confirmDelete(
    BuildContext context,
    ProductModel product,
    bool isLive,
    VendorProductsController controller,
  ) {
    Get.defaultDialog(
      title: isLive ? "Request Deletion?" : "Cancel Request?",
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        color: Colors.red,
      ),
      middleText: isLive
          ? "This will send a delete request to the Admin. The product will be removed once approved."
          : "Are you sure you want to cancel this pending request?",
      textConfirm: isLive ? "Send Request" : "Yes, Cancel",
      textCancel: "No, Go Back",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () {
        Get.back();
        controller.deleteProduct(product, isLive);
      },
    );
  }

  Widget _productCard(
    ProductModel product,
    VendorProductsController controller, {
    required bool isLive,
  }) {
    String imageBase64 = product.images.isNotEmpty ? product.images.first : '';
    Widget imageWidget = const Icon(
      Icons.image_not_supported,
      size: 50,
      color: Colors.grey,
    );

    if (imageBase64.isNotEmpty) {
      try {
        if (imageBase64.startsWith('http')) {
          // ✅ FIX: Live product aksar URL hotay hain, isliye Network Image bhi support add kardi hai
          imageWidget = Image.network(
            imageBase64,
            fit: BoxFit.cover,
            width: 80,
            height: 80,
          );
        } else {
          String cleanBase64 = imageBase64.contains(',')
              ? imageBase64.split(',').last
              : imageBase64;
          imageWidget = Image.memory(
            base64Decode(cleanBase64),
            fit: BoxFit.cover,
            width: 80,
            height: 80,
          );
        }
      } catch (_) {}
    }

    Color statusColor = isLive
        ? Colors.green
        : (product.status == 'rejected' ? Colors.red : Colors.orange);
    String statusText = isLive ? "ACTIVE" : product.status.toUpperCase();

    // Check if it's an edit or delete request
    bool isEditReq = (product.toMap()['isEditRequest'] == true);
    bool isDeleteReq = (product.toMap()['isDeleteRequest'] == true);
    bool isHold = product.status == 'hold';

    if (isDeleteReq) {
      statusText = "DELETE PENDING";
      statusColor = Colors.redAccent;
    } else if (isEditReq) {
      statusText = "EDIT PENDING";
      statusColor = Colors.blueAccent;
    } else if (isHold) {
      statusText = "ON HOLD";
      statusColor = Colors.amberAccent.shade700;
    }

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade100,
                child: imageWidget,
              ),
            ),
            const SizedBox(width: 15),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.comicNeue(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ACTION BUTTONS
                      if (!isDeleteReq)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Get.to(
                                () => VendorAddProductScreen(
                                  productToEdit: product,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 15),
                            GestureDetector(
                              onTap: () => _confirmDelete(
                                Get.context!,
                                product,
                                isLive,
                                controller,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ✅ FIX: Brand aur Model add kar diye gaye hain
                  Text(
                    [
                      if (product.brand.isNotEmpty) "Brand: ${product.brand}",
                      if (product.modelNumber.isNotEmpty)
                        "Model: ${product.modelNumber}",
                    ].join(" | "),
                    style: GoogleFonts.comicNeue(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),

                  // ✅ FIX: Agar Mobile hai toh RAM aur ROM show karein
                  if (product.ram != null || product.storage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        [
                          if (product.ram != null && product.ram!.isNotEmpty)
                            "RAM: ${product.ram}",
                          if (product.storage != null &&
                              product.storage!.isNotEmpty)
                            "ROM: ${product.storage}",
                        ].join(" | "),
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ✅ FIX: Sale price ki jagah Purchase price show ho rahi hai (Kyunke vendor admin ko is rate par bechta hai)
                      Text(
                        "Price: PKR ${product.purchasePrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors
                              .green, // Darker green for visibility on white
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Added on: ${DateFormat('dd MMM yyyy').format(product.dateAdded)}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (!isLive && product.status == 'rejected')
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        "Rejected. Please check with admin.",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (!isLive && isHold)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amberAccent),
                        ),
                        child: Text(
                          "Hold Reason: ${product.holdReason ?? 'Admin se rabta karein'}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
