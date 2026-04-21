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
  String vendorId;
  String vendorName; // ✅ Nayi Field: Vendor ka auto-filled naam
  List<String> images;
  String? video;
  DateTime dateAdded;
  String deliveryLocation;
  String warranty;
  double productPoints;

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
  String status; // ✅ 'pending', 'approved', 'rejected'

  ProductModel({
    this.id,
    required this.name,
    required this.modelNumber,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.brand,
    required this.purchasePrice,
    required this.salePrice,
    required this.originalPrice,
    required this.stockQuantity,
    this.stockOut = 0,
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
    this.status = 'pending', // Vendor jab add karega to default pending hoga
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
      'salePrice': salePrice,
      'originalPrice': originalPrice,
      'stockQuantity': stockQuantity,
      'stockOut': stockOut,
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
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      modelNumber: map['modelNumber'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      brand: map['brand'] ?? '',
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      stockOut: map['stockOut'] ?? 0,
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? 'Unknown Vendor',
      images: List<String>.from(map['images'] ?? []),
      video: map['video'],
      dateAdded: map['dateAdded'] != null
          ? (map['dateAdded'] as Timestamp).toDate()
          : DateTime.now(),
      deliveryLocation: map['deliveryLocation'] ?? 'Worldwide',
      warranty: map['warranty'] ?? 'No Warranty',
      productPoints: (map['productPoints'] ?? 0).toDouble(),
      deliveryFeesMap: Map<String, double>.from(map['deliveryFeesMap'] ?? {}),
      deliveryTimeMap: Map<String, String>.from(map['deliveryTimeMap'] ?? {}),
      codFee: (map['codFee'] ?? 0.0).toDouble(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isPackage: map['isPackage'] ?? false,
      includedItemIds: List<String>.from(map['includedItemIds'] ?? []),
      showDecimalPoints: map['showDecimalPoints'] ?? true,
      ram: map['ram'],
      storage: map['storage'],
      status: map['status'] ?? 'pending',
    );
  }
}
