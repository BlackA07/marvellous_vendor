// lib/features/auth/models/vendor_model.dart
class VendorModel {
  final String uid;
  final String storeName;
  final String storePhone;
  final String ownerName;
  final String ownerMobile;
  final String contactPersonName;
  final String contactPersonPhone;
  final String email;
  final List<String> categories;
  final List<String> subCategories;
  final String address;
  final String? profileImage;
  final List<String> storePictures; // Base64 images array
  final double beginningBalance;
  final String status;

  VendorModel({
    required this.uid,
    required this.storeName,
    required this.storePhone,
    required this.ownerName,
    required this.ownerMobile,
    required this.contactPersonName,
    required this.contactPersonPhone,
    required this.email,
    required this.categories,
    required this.subCategories,
    required this.address,
    this.profileImage,
    required this.storePictures,
    this.beginningBalance = 0.0,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'storeName': storeName,
      'storePhone': storePhone,
      'ownerName': ownerName,
      'ownerMobile': ownerMobile,
      'contactPersonName': contactPersonName,
      'contactPersonPhone': contactPersonPhone,
      'email': email,
      'categories': categories,
      'subCategories': subCategories,
      'address': address,
      'profileImage': profileImage,
      'storePictures': storePictures,
      'beginningBalance': beginningBalance,
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
