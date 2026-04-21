import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorFinanceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentVendorId => _auth.currentUser?.uid;

  Stream<QuerySnapshot> getVendorPurchasesStream() {
    return _db
        .collection('vendor_purchases')
        .where('vendorId', isEqualTo: currentVendorId)
        .snapshots();
  }

  Stream<QuerySnapshot> getVendorPaymentsStream() {
    return _db
        .collection('vendor_payment_history')
        .where('vendorId', isEqualTo: currentVendorId)
        .snapshots();
  }
}
