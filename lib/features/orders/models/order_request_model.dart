import 'package:cloud_firestore/cloud_firestore.dart';

class OrderRequestModel {
  String? id;
  String vendorId;
  String vendorName;
  List<dynamic> items;
  String status; // pending, confirmed, shipped, completed, rejected
  DateTime createdAt;

  OrderRequestModel({
    this.id,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    this.status = 'pending',
    required this.createdAt,
  });

  factory OrderRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderRequestModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      items: map['items'] ?? [],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'items': items,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
