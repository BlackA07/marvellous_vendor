import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorOrdersRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentVendorId => _auth.currentUser?.uid;

  // Streams for real-time updates
  Stream<QuerySnapshot> getVendorPurchasesStream() {
    if (currentVendorId == null) return const Stream.empty();
    return _db
        .collection('vendor_purchases')
        .where('vendorId', isEqualTo: currentVendorId)
        .snapshots();
  }

  Stream<QuerySnapshot> getVendorDuesStream(String purchaseId) {
    return _db
        .collection('vendor_dues')
        .where('purchaseId', isEqualTo: purchaseId)
        .snapshots();
  }

  Stream<QuerySnapshot> getVendorPaymentHistoryStream() {
    if (currentVendorId == null) return const Stream.empty();
    return _db
        .collection('vendor_payment_history')
        .where('vendorId', isEqualTo: currentVendorId)
        .snapshots();
  }
}
