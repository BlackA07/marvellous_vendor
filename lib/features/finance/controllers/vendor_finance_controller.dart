import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/vendor_finance_model.dart';
import '../repository/vendor_finance_repository.dart';

class VendorFinanceController extends GetxController {
  final VendorFinanceRepository _repo = VendorFinanceRepository();

  var isLoading = true.obs;

  // Stats
  var totalBilledAmount = 0.0.obs;
  var totalReceivedAmount = 0.0.obs;
  var totalAmountPending = 0.0.obs;

  // Lists
  var ledgerHistory = <VendorLedgerItem>[].obs;

  // Chart Data (Last 7 days sales)
  var weeklyChartData = <double>[0, 0, 0, 0, 0, 0, 0].obs;
  var weeklyLabels = <String>['', '', '', '', '', '', ''].obs;
  var maxChartValue = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    _setupChartLabels();
    _loadData();
  }

  void _setupChartLabels() {
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      weeklyLabels[6 - i] = DateFormat(
        'E',
      ).format(day).substring(0, 1); // M, T, W, etc.
    }
  }

  void _loadData() {
    isLoading.value = true;

    _repo.getVendorPurchasesStream().listen((purchaseSnap) {
      _repo.getVendorPaymentsStream().listen((paymentSnap) {
        List<VendorLedgerItem> tempLedger = [];
        double billed = 0.0;
        double received = 0.0;
        double pending = 0.0;

        List<double> chartValues = [0, 0, 0, 0, 0, 0, 0];
        DateTime now = DateTime.now();
        DateTime todayStart = DateTime(now.year, now.month, now.day);

        // Process Purchases (Bills)
        for (var doc in purchaseSnap.docs) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime date = (data['date'] as Timestamp).toDate();
          double amount =
              double.tryParse(
                data['totalBillAmount']?.toString() ??
                    data['totalPrice']?.toString() ??
                    '0',
              ) ??
              0.0;
          double remaining =
              double.tryParse(data['remainingBalance']?.toString() ?? '0') ??
              0.0;
          String billNum = data['billNumber']?.toString() ?? 'N/A';

          billed += amount;
          pending += remaining;

          tempLedger.add(
            VendorLedgerItem(
              id: doc.id,
              title: "Bill Generated (#$billNum)",
              amount: amount,
              date: date,
              isPayment: false,
              subtitle: "Total Bill: PKR ${amount.toStringAsFixed(0)}",
            ),
          );

          // Chart Calculation
          int dayDiff = todayStart
              .difference(DateTime(date.year, date.month, date.day))
              .inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            chartValues[6 - dayDiff] += amount;
          }
        }

        // Process Payments
        for (var doc in paymentSnap.docs) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime date = (data['paymentDate'] as Timestamp).toDate();
          double amount = (data['paidAmount'] ?? 0.0).toDouble();
          String mode = data['paymentMode'] ?? 'Cash';

          received += amount;

          tempLedger.add(
            VendorLedgerItem(
              id: doc.id,
              title: "Payment Received",
              amount: amount,
              date: date,
              isPayment: true,
              subtitle: "Via $mode",
            ),
          );
        }

        // Sort Ledger (Newest first)
        tempLedger.sort((a, b) => b.date.compareTo(a.date));

        totalBilledAmount.value = billed;
        totalReceivedAmount.value = received;
        totalAmountPending.value = pending;
        ledgerHistory.assignAll(tempLedger);

        // Update Chart
        double maxVal = 0;
        for (var val in chartValues) {
          if (val > maxVal) maxVal = val;
        }
        maxChartValue.value = maxVal > 0 ? maxVal : 1.0;
        weeklyChartData.assignAll(chartValues);

        isLoading.value = false;
      });
    });
  }
}
