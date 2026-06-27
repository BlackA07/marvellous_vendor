// vendor_report_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vendor_report_model.dart';

class VendorReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _vid => _auth.currentUser?.uid;

  Future<VendorReportModel?> getMyReportData() async {
    final vid = _vid;
    if (vid == null) return null;

    // ── Fetch all in parallel ──
    final results = await Future.wait([
      _db.collection('vendors').doc(vid).get(),
      _db
          .collection('vendor_purchases')
          .where('vendorId', isEqualTo: vid)
          .get(),
      _db
          .collection('vendor_payment_history')
          .where('vendorId', isEqualTo: vid)
          .get(),
      _db.collection('products').where('vendorId', isEqualTo: vid).get(),
      _db
          .collection('product_requests')
          .where('vendorId', isEqualTo: vid)
          .get(),
      _db.collection('order_requests').where('vendorId', isEqualTo: vid).get(),
    ]);

    final vendorDoc = results[0] as DocumentSnapshot;
    if (!vendorDoc.exists) return null;
    final data = vendorDoc.data() as Map<String, dynamic>;

    final purchasesSnap = results[1] as QuerySnapshot;
    final paymentsSnap = results[2] as QuerySnapshot;
    final productsSnap = results[3] as QuerySnapshot;
    final requestsSnap = results[4] as QuerySnapshot;
    final orderRequestsSnap = results[5] as QuerySnapshot;

    // ── Finance ──
    double billed = 0;
    int totalBills = purchasesSnap.docs.length;
    List<Map<String, dynamic>> recentBills = [];

    for (final doc in purchasesSnap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      double amt = _toDouble(d['totalBillAmount'] ?? d['totalPrice'] ?? 0);
      billed += amt;
      recentBills.add({
        'billNumber': d['billNumber']?.toString() ?? 'N/A',
        'amount': amt,
        'date': d['date'] is Timestamp
            ? (d['date'] as Timestamp).toDate()
            : DateTime.now(),
        'remaining': _toDouble(d['remainingBalance'] ?? 0),
        'paymentMode': d['paymentMode']?.toString() ?? 'Cash',
        'items': d['items'] is List ? (d['items'] as List).length : 0,
      });
    }

    recentBills.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    // YAHAN SE .take(5) HATA DIYA HAI - AB SARI BILLS AAYENGI
    final latestBills = recentBills;

    double cashReceived = 0;
    double chequeReceived = 0;
    double chequeCleared = 0;
    double chequePending = 0;
    List<Map<String, dynamic>> recentPayments = [];

    for (final doc in paymentsSnap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      double amt = _toDouble(d['paidAmount'] ?? 0);
      String mode = d['paymentMode']?.toString() ?? 'Cash';
      bool isCleared = d['isCleared'] != false;

      if (mode.toLowerCase() == 'cheque') {
        chequeReceived += amt;
        if (isCleared) {
          chequeCleared += amt;
        } else {
          chequePending += amt;
        }
      } else {
        cashReceived += amt;
      }

      recentPayments.add({
        'amount': amt,
        'mode': mode,
        'date': d['paymentDate'] is Timestamp
            ? (d['paymentDate'] as Timestamp).toDate()
            : DateTime.now(),
        'isCleared': isCleared,
        'chequeNumber': d['chequeNumber']?.toString() ?? '',
        'screenshot': d['screenshot']?.toString() ?? '',
      });
    }

    recentPayments.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    // YAHAN SE BHI .take(5) HATA DIYA HAI
    final latestPayments = recentPayments;

    double totalReceived = cashReceived + chequeCleared;
    double totalPending = (billed - totalReceived) < 0
        ? 0
        : billed - totalReceived;

    // ── Products ──
    List<Map<String, dynamic>> liveProductsList = productsSnap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return {
        'name': d['name']?.toString() ?? '',
        'category': d['category']?.toString() ?? '',
        'salePrice': _toDouble(d['salePrice'] ?? 0),
        'purchasePrice': _toDouble(d['purchasePrice'] ?? 0),
        'brand': d['brand']?.toString() ?? '',
        'stockQuantity': d['stockQuantity'] ?? 0,
      };
    }).toList();

    List<Map<String, dynamic>> pendingProductsList = [];
    int pendingCount = 0;
    int holdCount = 0;
    int rejectedCount = 0;

    for (final doc in requestsSnap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final s = d['status']?.toString() ?? '';
      if (s == 'pending') pendingCount++;
      if (s == 'hold') holdCount++;
      if (s == 'rejected') rejectedCount++;

      if (s == 'pending' || s == 'hold') {
        pendingProductsList.add({
          'name': d['name']?.toString() ?? '',
          'status': s,
          'category': d['category']?.toString() ?? '',
          'holdReason': d['holdReason']?.toString() ?? '',
        });
      }
    }

    // ── Order Requests ──
    int totalOrders = orderRequestsSnap.docs.length;
    int completedOrders = 0;
    int pendingOrders = 0;
    int confirmedOrders = 0;
    int shippedOrders = 0;
    int rejectedOrders = 0;

    for (final doc in orderRequestsSnap.docs) {
      final s =
          (doc.data() as Map<String, dynamic>)['status']?.toString() ?? '';
      if (s == 'completed' || s == 'received')
        completedOrders++;
      else if (s == 'pending')
        pendingOrders++;
      else if (s == 'confirmed')
        confirmedOrders++;
      else if (s == 'shipped')
        shippedOrders++;
      else if (s == 'rejected')
        rejectedOrders++;
    }

    // ── Vendor Info ──
    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']);
    }

    final List cats = data['categories'] is List ? data['categories'] : [];
    final List subCats = data['subCategories'] is List
        ? data['subCategories']
        : [];
    double beginningBalance = _toDouble(data['beginningBalance'] ?? 0);

    return VendorReportModel(
      vendorId: vid,
      storeName: data['storeName']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      phone: data['storePhone']?.toString() ?? '',
      ownerMobile: data['ownerMobile']?.toString() ?? '',
      contactPersonName: data['contactPersonName']?.toString() ?? '',
      contactPersonPhone: data['contactPersonPhone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      category: cats.isNotEmpty ? cats.join(', ') : 'N/A',
      categories: cats.map((e) => e.toString()).toList(),
      subCategories: subCats.map((e) => e.toString()).toList(),
      status: data['status']?.toString() ?? 'pending',
      createdAt: createdAt,
      totalBilled: billed,
      totalReceived: totalReceived,
      totalPending: totalPending,
      beginningBalance: beginningBalance,
      cashReceived: cashReceived,
      chequeReceived: chequeReceived,
      chequeCleared: chequeCleared,
      chequePending: chequePending,
      totalLiveProducts: liveProductsList.length,
      totalPendingProducts: pendingCount,
      totalHoldProducts: holdCount,
      totalRejectedProducts: rejectedCount,
      liveProductsList: liveProductsList,
      pendingProductsList: pendingProductsList,
      totalOrderRequests: totalOrders,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      confirmedOrders: confirmedOrders,
      shippedOrders: shippedOrders,
      rejectedOrders: rejectedOrders,
      totalBills: totalBills,
      avgBillAmount: totalBills > 0 ? billed / totalBills : 0,
      recentBills: latestBills,
      recentPayments: latestPayments,
    );
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
