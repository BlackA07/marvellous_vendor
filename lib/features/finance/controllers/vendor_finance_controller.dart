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
        double dbPending = 0.0;
        double unclearedChequesTotal =
            0.0; // ✅ NAYA: Uncleared cheques ka total

        List<double> chartValues = [0, 0, 0, 0, 0, 0, 0];
        DateTime now = DateTime.now();
        DateTime todayStart = DateTime(now.year, now.month, now.day);

        // ── Process Purchases (Bills) ──
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
          dbPending += remaining;

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

        // ── Process Payments ──
        for (var doc in paymentSnap.docs) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime date = (data['paymentDate'] as Timestamp).toDate();
          double amount = (data['paidAmount'] ?? 0.0).toDouble();
          String mode = data['paymentMode'] ?? 'Cash';
          String? screenshot = data['screenshot'];
          bool isCleared = data['isCleared'] ?? true;

          // ✅ MAIN FIX: Agar cheque clear ho gaya (isCleared = true) toh Received me plus karo,
          // Warna usko Uncleared me daal do taake Pending mein jama ho jaye.
          if (isCleared) {
            received += amount;
          } else {
            unclearedChequesTotal += amount;
          }

          tempLedger.add(
            VendorLedgerItem(
              id: doc.id,
              title: "Payment Received",
              amount: amount,
              date: date,
              isPayment: true,
              subtitle: "Via $mode",
              screenshot: screenshot,
              paymentMode: mode, // ✅ Pass for UI
              isCleared: isCleared, // ✅ Pass for UI
            ),
          );
        }

        // ── Sort Ledger (Newest first & Payment on Top) ──
        tempLedger.sort((a, b) {
          // 1. Date se sort karein
          int dateCmp = b.date.compareTo(a.date);
          if (dateCmp != 0) return dateCmp;

          // 2. ✅ FIX: Agar Date+Time bilkul same ho, toh Payment ko oopar rakho aur Bill ko neechay
          if (a.isPayment && !b.isPayment) return -1;
          if (!a.isPayment && b.isPayment) return 1;
          return 0;
        });

        totalBilledAmount.value = billed;
        totalReceivedAmount.value = received;

        // ✅ Pending = Original Pending + Uncleared Cheques (Kyunke wo paise abhi tak milay nahi)
        totalAmountPending.value = dbPending + unclearedChequesTotal;

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
