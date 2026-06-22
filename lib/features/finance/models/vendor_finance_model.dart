import 'package:cloud_firestore/cloud_firestore.dart';

class VendorLedgerItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isPayment; // true = Admin se paise aaye, false = Naya bill bana
  final String subtitle;
  final String? screenshot;
  final String? paymentMode; // ✅ NEW: Added for Cheque Check
  final bool isCleared; // ✅ NEW: Added for Pending Check

  VendorLedgerItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isPayment,
    required this.subtitle,
    this.screenshot,
    this.paymentMode,
    this.isCleared = true,
  });
}
