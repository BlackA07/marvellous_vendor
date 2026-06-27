// vendor_report_model.dart

class VendorReportModel {
  final String vendorId;
  final String storeName;
  final String ownerName;
  final String phone;
  final String ownerMobile;
  final String contactPersonName;
  final String contactPersonPhone;
  final String email;
  final String address;
  final String category;
  final List<String> categories;
  final List<String> subCategories;
  final String status;
  final DateTime? createdAt;

  // Finance stats
  final double totalBilled;
  final double totalReceived;
  final double totalPending;
  final double beginningBalance;

  // Payment breakdown
  final double cashReceived;
  final double chequeReceived;
  final double chequeCleared;
  final double chequePending;

  // Product stats
  final int totalLiveProducts;
  final int totalPendingProducts;
  final int totalHoldProducts;
  final int totalRejectedProducts;

  // Product list for drill-down
  final List<Map<String, dynamic>> liveProductsList;
  final List<Map<String, dynamic>> pendingProductsList;

  // Order request stats
  final int totalOrderRequests;
  final int completedOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int shippedOrders;
  final int rejectedOrders;

  // Bill stats
  final int totalBills;
  final double avgBillAmount;
  final List<Map<String, dynamic>> recentBills;

  // Payment history
  final List<Map<String, dynamic>> recentPayments;

  const VendorReportModel({
    required this.vendorId,
    required this.storeName,
    required this.ownerName,
    required this.phone,
    required this.ownerMobile,
    required this.contactPersonName,
    required this.contactPersonPhone,
    required this.email,
    required this.address,
    required this.category,
    required this.categories,
    required this.subCategories,
    required this.status,
    required this.createdAt,
    required this.totalBilled,
    required this.totalReceived,
    required this.totalPending,
    required this.beginningBalance,
    required this.cashReceived,
    required this.chequeReceived,
    required this.chequeCleared,
    required this.chequePending,
    required this.totalLiveProducts,
    required this.totalPendingProducts,
    required this.totalHoldProducts,
    required this.totalRejectedProducts,
    required this.liveProductsList,
    required this.pendingProductsList,
    required this.totalOrderRequests,
    required this.completedOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.shippedOrders,
    required this.rejectedOrders,
    required this.totalBills,
    required this.avgBillAmount,
    required this.recentBills,
    required this.recentPayments,
  });
}
