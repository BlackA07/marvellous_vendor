import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String? id;
  String name;
  String modelNumber;
  String description;
  String category;
  String subCategory;
  String brand;
  double purchasePrice;
  double salePrice;
  double originalPrice;
  int stockQuantity;
  int stockOut;
  int stockIn;
  String vendorId;
  String vendorName;
  List<String> images;
  String? video;
  DateTime dateAdded;
  String deliveryLocation;
  String warranty;
  double productPoints;
  String? tiktokVideoUrl; // ✅ NAYA FIELD ADDED

  Map<String, double> deliveryFeesMap;
  Map<String, String> deliveryTimeMap;
  double codFee;
  double averageRating;
  int totalReviews;

  bool isPackage;
  List<String> includedItemIds;
  bool showDecimalPoints;
  String? ram;
  String? storage;
  String status;
  String? holdReason; // ✅ NAYA FIELD: Hold reason save aur fetch karne ke liye

  ProductModel({
    this.id,
    required this.name,
    required this.modelNumber,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.brand,
    required this.purchasePrice,
    this.tiktokVideoUrl, // ✅ ADDED
    required this.salePrice,
    required this.originalPrice,
    required this.stockQuantity,
    this.stockOut = 0,
    this.stockIn = 0,
    required this.vendorId,
    required this.vendorName,
    required this.images,
    this.video,
    required this.dateAdded,
    required this.deliveryLocation,
    required this.warranty,
    required this.productPoints,
    required this.deliveryFeesMap,
    required this.deliveryTimeMap,
    this.codFee = 0.0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isPackage = false,
    this.includedItemIds = const [],
    this.showDecimalPoints = true,
    this.ram,
    this.storage,
    this.status = 'pending',
    this.holdReason, // ✅ ADDED
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'modelNumber': modelNumber,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'brand': brand,
      'purchasePrice': purchasePrice,
      'tiktokVideoUrl': tiktokVideoUrl, // ✅ ADDED
      'salePrice': salePrice,
      'originalPrice': originalPrice,
      'stockQuantity': stockQuantity,
      'stockOut': stockOut,
      'stockIn': stockIn,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'images': images,
      'video': video,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'deliveryLocation': deliveryLocation,
      'warranty': warranty,
      'productPoints': productPoints,
      'deliveryFeesMap': deliveryFeesMap,
      'deliveryTimeMap': deliveryTimeMap,
      'codFee': codFee,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'isPackage': isPackage,
      'includedItemIds': includedItemIds,
      'showDecimalPoints': showDecimalPoints,
      'ram': ram,
      'storage': storage,
      'status': status,
      'holdReason': holdReason, // ✅ ADDED
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name']?.toString() ?? '',
      modelNumber: map['modelNumber']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      subCategory: map['subCategory']?.toString() ?? '',
      brand: map['brand']?.toString() ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      stockOut: (map['stockOut'] as num?)?.toInt() ?? 0,
      stockIn: (map['stockIn'] ?? map['stockQuantity'] as num?)?.toInt() ?? 0,
      vendorId: map['vendorId']?.toString() ?? '',
      vendorName: map['vendorName']?.toString() ?? 'Unknown Vendor',
      images: map['images'] is List
          ? (map['images'] as List).map((e) => e.toString()).toList()
          : [],
      video: map['video']?.toString(),
      dateAdded: map['dateAdded'] is Timestamp
          ? (map['dateAdded'] as Timestamp).toDate()
          : DateTime.now(),
      deliveryLocation: map['deliveryLocation']?.toString() ?? 'Worldwide',
      warranty: map['warranty']?.toString() ?? 'No Warranty',
      productPoints: (map['productPoints'] as num?)?.toDouble() ?? 0.0,
      tiktokVideoUrl: map['tiktokVideoUrl']?.toString(), // ✅ ADDED
      deliveryFeesMap: map['deliveryFeesMap'] is Map
          ? (map['deliveryFeesMap'] as Map).map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num).toDouble()),
            )
          : {},
      deliveryTimeMap: map['deliveryTimeMap'] is Map
          ? (map['deliveryTimeMap'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : {},
      codFee: (map['codFee'] as num?)?.toDouble() ?? 0.0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      isPackage: map['isPackage'] ?? false,
      includedItemIds: map['includedItemIds'] is List
          ? (map['includedItemIds'] as List).map((e) => e.toString()).toList()
          : [],
      showDecimalPoints: map['showDecimalPoints'] ?? true,
      ram: map['ram']?.toString(),
      storage: map['storage']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      holdReason: map['holdReason']?.toString(), // ✅ ADDED
    );
  }
}
