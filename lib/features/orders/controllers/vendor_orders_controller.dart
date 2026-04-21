import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/vendor_order_model.dart';
import '../repository/vendor_orders_repository.dart';

class VendorOrdersController extends GetxController {
  final VendorOrdersRepository _repo = VendorOrdersRepository();

  var isLoading = true.obs;
  var allOrders = <VendorOrderModel>[].obs;
  var pendingOrders = <VendorOrderModel>[].obs;
  var completedOrders = <VendorOrderModel>[].obs;

  // Global Stats
  var totalSalesValue = 0.0.obs;
  var totalAmountReceived = 0.0.obs;
  var totalAmountPending = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToOrders();
  }

  void _listenToOrders() {
    _repo.getVendorPurchasesStream().listen((snapshot) {
      isLoading.value = true;
      try {
        List<VendorOrderModel> tempList = snapshot.docs
            .map(
              (doc) => VendorOrderModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Sort by Date Descending (Newest First) without needing Firebase Index
        tempList.sort((a, b) => b.date.compareTo(a.date));

        allOrders.assignAll(tempList);
        pendingOrders.assignAll(tempList.where((o) => !o.isFullyPaid).toList());
        completedOrders.assignAll(
          tempList.where((o) => o.isFullyPaid).toList(),
        );

        _calculateTotals();
      } catch (e) {
        debugPrint("Error processing vendor orders: $e");
      } finally {
        isLoading.value = false;
      }
    });
  }

  void _calculateTotals() {
    double sales = 0;
    double received = 0;
    double pending = 0;

    for (var order in allOrders) {
      sales += order.totalBillAmount;
      received += order.cashPaid;
      pending += order.remainingBalance;
    }

    totalSalesValue.value = sales;
    totalAmountReceived.value = received;
    totalAmountPending.value = pending;
  }

  // Safe parsing helper for detail screen streams
  DateTime parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String)
      return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }
}
