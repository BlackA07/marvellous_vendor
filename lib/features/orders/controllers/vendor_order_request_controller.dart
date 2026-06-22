import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_request_model.dart';

class VendorOrderRequestController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = false.obs;
  var orderRequests = <OrderRequestModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    listenToOrderRequests();
  }

  // Real-time stream to get requests for the logged-in vendor
  void listenToOrderRequests() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _db
        .collection('order_requests')
        .where('vendorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            orderRequests.value = snapshot.docs.map((doc) {
              return OrderRequestModel.fromMap(doc.id, doc.data());
            }).toList();
          },
          onError: (e) {
            debugPrint("Error listening to order requests: $e");
          },
        );
  }

  // Individual item availability toggle
  Future<void> toggleItemAvailability(
    String requestId,
    List<dynamic> currentItems,
    int itemIndex,
    bool newValue,
  ) async {
    try {
      // Modify the list locally
      List<dynamic> updatedItems = List.from(currentItems);
      updatedItems[itemIndex]['isAvailable'] = newValue;

      // Update in Firestore
      await _db.collection('order_requests').doc(requestId).update({
        'items': updatedItems,
      });
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update item availability: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Overall Order Status Update (Confirm, Reject, Shipped)
  // ✅ FIX: Removed _sendAdminNotification to avoid Permission Denied errors
  Future<void> updateOrderStatus(
    String requestId,
    String newStatus, {
    String? rejectReason,
    String? holdReason, // Added parameter
  }) async {
    isLoading.value = true;
    try {
      Map<String, dynamic> updateData = {'status': newStatus};
      if (rejectReason != null && rejectReason.isNotEmpty) {
        updateData['rejectReason'] = rejectReason;
      }
      if (holdReason != null && holdReason.isNotEmpty) {
        updateData['holdReason'] = holdReason; // Save hold reason to database
      }

      await _db.collection('order_requests').doc(requestId).update(updateData);

      String msg = "Order status updated successfully.";
      if (newStatus == 'confirmed') msg = "Order Confirmed!";
      if (newStatus == 'shipped') msg = "Order marked as Shipped!";
      if (newStatus == 'rejected') msg = "Order Rejected.";
      if (newStatus == 'hold') msg = "Order placed on Hold.";

      Get.snackbar(
        "Status Updated",
        msg,
        backgroundColor: newStatus == 'rejected'
            ? Colors.red.shade900
            : (newStatus == 'hold'
                  ? Colors.amber.shade900
                  : Colors.green.shade900),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update status: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    isLoading.value = false;
  }

  // ✅ UPDATE METHOD: Admin Notification switch block update
  Future<void> _sendAdminNotification(
    String requestId,
    String newStatus,
  ) async {
    try {
      var reqDoc = await _db.collection('order_requests').doc(requestId).get();
      if (!reqDoc.exists) return;
      var reqData = reqDoc.data() as Map<String, dynamic>;
      String vendorName = reqData['vendorName'] ?? 'Vendor';

      String title = '';
      String body = '';
      switch (newStatus) {
        case 'confirmed':
          title = '✅ Order Confirmed';
          body = '$vendorName ne order confirm kar diya.';
          break;
        case 'shipped':
          title = '🚚 Order Shipped';
          body = '$vendorName ne order ship kar diya.';
          break;
        case 'rejected':
          title = '❌ Order Rejected';
          body = '$vendorName ne order reject kar diya.';
          break;
        case 'hold': // Added case
          title = '⚠️ Order on HOLD';
          body =
              '$vendorName ne order HOLD par rakh diya he. Reason check karen.';
          break;
        default:
          title = '📦 Order Update';
          body = '$vendorName ne order status update kiya: $newStatus';
      }

      var adminSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (adminSnap.docs.isNotEmpty) {
        await _db
            .collection('users')
            .doc(adminSnap.docs.first.id)
            .collection('notifications')
            .add({
              'title': title,
              'body': body,
              'type': 'order_status',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
              'data': {
                'requestId': requestId,
                'vendorName': vendorName,
                'status': newStatus,
              },
            });
      }
    } catch (e) {
      debugPrint('Admin notification error: $e');
    }
  }
}
