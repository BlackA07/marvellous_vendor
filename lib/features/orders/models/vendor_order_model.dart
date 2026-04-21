import 'package:cloud_firestore/cloud_firestore.dart';

class VendorOrderModel {
  final String id;
  final String billNumber;
  final DateTime date;
  final double totalBillAmount;
  final double cashPaid;
  final double remainingBalance;
  final String paymentMode;
  final String creditType;
  final List<dynamic> items;

  VendorOrderModel({
    required this.id,
    required this.billNumber,
    required this.date,
    required this.totalBillAmount,
    required this.cashPaid,
    required this.remainingBalance,
    required this.paymentMode,
    required this.creditType,
    required this.items,
  });

  factory VendorOrderModel.fromMap(Map<String, dynamic> map, String docId) {
    // Safe Date Parsing
    DateTime parsedDate = DateTime.now();
    if (map['date'] != null) {
      if (map['date'] is Timestamp) {
        parsedDate = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is String) {
        parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
      }
    }

    // Safe Amount Parsing
    double total =
        double.tryParse(
          map['totalBillAmount']?.toString() ??
              map['totalPrice']?.toString() ??
              '0',
        ) ??
        0.0;
    double paid = double.tryParse(map['cashPaid']?.toString() ?? '0') ?? 0.0;
    double remaining =
        double.tryParse(map['remainingBalance']?.toString() ?? '0') ?? 0.0;

    // Fallback calculation if remaining is missing in old records
    if (remaining <= 0 && total > 0 && paid < total) {
      remaining = total - paid;
    }

    return VendorOrderModel(
      id: docId,
      billNumber: map['billNumber']?.toString() ?? 'N/A',
      date: parsedDate,
      totalBillAmount: total,
      cashPaid: paid,
      remainingBalance: remaining < 0 ? 0.0 : remaining,
      paymentMode: map['paymentMode']?.toString() ?? 'Unknown',
      creditType: map['creditType']?.toString() ?? 'Unknown',
      items: map['items'] is List ? map['items'] : [],
    );
  }

  bool get isFullyPaid => remainingBalance <= 0.01;
}
