import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorProductsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentVendorId => _auth.currentUser?.uid;

  // Fetch products that are approved and live
  Stream<QuerySnapshot> getLiveProductsStream() {
    if (currentVendorId == null) return const Stream.empty();
    return _db
        .collection('products')
        .where('vendorId', isEqualTo: currentVendorId)
        .snapshots();
  }

  // Fetch product requests (Pending/Rejected)
  Stream<QuerySnapshot> getPendingRequestsStream() {
    if (currentVendorId == null) return const Stream.empty();
    return _db
        .collection('product_requests')
        .where('vendorId', isEqualTo: currentVendorId)
        .snapshots();
  }

  // ✅ NEW: Delete Product / Cancel Request
  Future<void> deleteProductRequest(String docId) async {
    await _db.collection('product_requests').doc(docId).delete();
  }

  Future<void> deleteLiveProduct(String docId) async {
    await _db.collection('products').doc(docId).delete();
  }
}
