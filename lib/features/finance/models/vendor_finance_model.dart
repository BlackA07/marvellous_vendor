import 'package:cloud_firestore/cloud_firestore.dart';

class VendorLedgerItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isPayment; // true = Admin se paise aaye, false = Naya bill bana
  final String subtitle;

  VendorLedgerItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isPayment,
    required this.subtitle,
  });
}
