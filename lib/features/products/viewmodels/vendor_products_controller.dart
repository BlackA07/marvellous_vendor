import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../repository/vendor_products_repository.dart';

class VendorProductsController extends GetxController {
  final VendorProductsRepository _repo = VendorProductsRepository();

  var isLoadingLive = true.obs;
  var isLoadingPending = true.obs;

  var liveProducts = <ProductModel>[].obs;
  var pendingRequests = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _listenToLiveProducts();
    _listenToPendingRequests();
  }

  void _listenToLiveProducts() {
    _repo.getLiveProductsStream().listen((snapshot) {
      isLoadingLive.value = true;
      try {
        var list = snapshot.docs
            .map(
              (doc) => ProductModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        liveProducts.assignAll(list);
      } finally {
        isLoadingLive.value = false;
      }
    });
  }

  void _listenToPendingRequests() {
    _repo.getPendingRequestsStream().listen((snapshot) {
      isLoadingPending.value = true;
      try {
        var list = snapshot.docs
            .map(
              (doc) => ProductModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // ✅ FIX: Ab yahan 'hold' status bhi include kar diya he taake vendor ko apni hold requests nazar aayein aur wo edit kar sakay
        list = list
            .where(
              (p) =>
                  p.status == 'pending' ||
                  p.status == 'rejected' ||
                  p.status == 'hold',
            )
            .toList();

        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        pendingRequests.assignAll(list);
      } finally {
        isLoadingPending.value = false;
      }
    });
  }

  // ✅ FIX: LIVE DELETE WILL SEND A REQUEST, PENDING DELETE WILL CANCEL IT DIRECTLY
  Future<void> deleteProduct(ProductModel product, bool isLive) async {
    try {
      if (isLive) {
        // Send a DELETE REQUEST to Admin
        Map<String, dynamic> requestData = product.toMap();
        requestData['isDeleteRequest'] = true;
        requestData['originalProductId'] = product.id;
        requestData['status'] = 'pending'; // Make it pending for admin

        await FirebaseFirestore.instance
            .collection('product_requests')
            .add(requestData);

        Get.snackbar(
          "Request Sent",
          "Delete request sent to admin for approval.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Just cancel the unapproved request directly
        await _repo.deleteProductRequest(product.id!);

        Get.snackbar(
          "Cancelled",
          "Pending request cancelled successfully.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not process request: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
