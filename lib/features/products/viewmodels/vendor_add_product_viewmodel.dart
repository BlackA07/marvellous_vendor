import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product_model.dart';

final vendorAddProductProvider = ChangeNotifierProvider.autoDispose(
  (ref) => VendorAddProductViewModel(),
);

final grossProfitProvider = StateProvider.autoDispose<double>((ref) {
  final vm = ref.watch(vendorAddProductProvider);
  double purchase = double.tryParse(vm.purchaseCtrl.text) ?? 0.0;
  double sale = double.tryParse(vm.saleCtrl.text) ?? 0.0;
  return sale - purchase;
});

class VendorAddProductViewModel extends ChangeNotifier {
  final nameCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final tiktokUrlCtrl = TextEditingController(); // ✅ NAYA FIELD
  final brandCtrl = TextEditingController();
  final ramCtrl = TextEditingController();
  final storageCtrl = TextEditingController();
  final purchaseCtrl = TextEditingController();
  final saleCtrl = TextEditingController();
  final originalCtrl = TextEditingController();
  final vendorNameCtrl = TextEditingController();
  final customWarrantyCtrl = TextEditingController();

  bool isLoading = false;
  bool isMobile = false;
  List<String> selectedImagesBase64 = [];
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> dbCategories = [];
  String? selectedCategory;
  String? selectedSubCategory;
  StreamSubscription? _categorySubscription;

  String selectedWarrantyDuration = "No Warranty";
  bool hasCompanyWarranty = false;
  bool hasShopWarranty = false;

  String currentVendorId = "";
  String currentVendorName = "";

  // ✅ EDIT MODE VARIABLES
  bool isEditMode = false;
  bool isEditInitialized = false;
  String? editOriginalProductId;
  List<String> combinedImages = [];

  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  VendorAddProductViewModel() {
    _fetchCurrentVendorDetails();
    _fetchCategories();
    nameCtrl.addListener(_checkIfMobile);
  }

  // ✅ INIT EDIT MODE (Pre-fill data)
  void initForEdit(ProductModel product) {
    if (isEditInitialized) return;

    isEditMode = true;
    isEditInitialized = true;
    editOriginalProductId = product.id;

    // Controllers fill karna
    tiktokUrlCtrl.text = product.tiktokVideoUrl ?? '';
    nameCtrl.text = product.name;
    modelCtrl.text = product.modelNumber;
    descCtrl.text = product.description;
    brandCtrl.text = product.brand;
    purchaseCtrl.text = product.purchasePrice.toStringAsFixed(0);
    saleCtrl.text = product.salePrice.toStringAsFixed(0);
    originalCtrl.text = product.originalPrice.toStringAsFixed(0);

    if (product.ram != null) ramCtrl.text = product.ram!;
    if (product.storage != null) storageCtrl.text = product.storage!;

    selectedCategory = product.category;
    selectedSubCategory = product.subCategory;

    // ✅ Combined List mein purani images load karna
    // Taake Edit mode mein purani images pehle se nazar ayen
    combinedImages = List<String>.from(product.images);

    // Warranty handling
    // Agar warranty format mein "(" hai, to duration extract karo
    if (product.warranty.contains('(')) {
      selectedWarrantyDuration = product.warranty.split('(').first.trim();
      String types = product.warranty.split('(').last.replaceAll(')', '');
      hasCompanyWarranty = types.contains('Company');
      hasShopWarranty = types.contains('Shop');
    } else {
      selectedWarrantyDuration = product.warranty;
    }

    _checkIfMobile();
    notifyListeners();
  }

  void _checkIfMobile() {
    bool isMob = nameCtrl.text.toLowerCase().contains("mobile");
    if (isMob != isMobile) {
      isMobile = isMob;
      notifyListeners();
    }
  }

  void _fetchCategories() {
    _categorySubscription = _firestore
        .collection('categories')
        .snapshots()
        .listen((snapshot) {
          dbCategories = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          notifyListeners();
        });
  }

  List<String> get categoryNames =>
      dbCategories.map((c) => c['name'].toString()).toSet().toList();

  List<String> get availableSubCategories {
    if (selectedCategory == null) return [];
    var cat = dbCategories.firstWhere(
      (c) => c['name'] == selectedCategory,
      orElse: () => {},
    );
    if (cat.isEmpty || cat['subCategories'] == null) return [];
    return List<String>.from(cat['subCategories']).toSet().toList();
  }

  Future<void> addNewCategory(String catName) async {
    String trimmed = catName.trim();
    if (dbCategories.any((c) => c['name'] == trimmed)) {
      selectedCategory = trimmed;
      selectedSubCategory = null;
      notifyListeners();
      return;
    }
    dbCategories.add({'name': trimmed, 'subCategories': []});
    selectedCategory = trimmed;
    selectedSubCategory = null;
    notifyListeners();
    try {
      await _firestore.collection('categories').add({
        'name': trimmed,
        'subCategories': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  Future<void> addNewSubCategory(String catName, String subName) async {
    String trimmedSub = subName.trim();
    var catIndex = dbCategories.indexWhere((c) => c['name'] == catName);
    if (catIndex != -1) {
      List<dynamic> subs = List.from(
        dbCategories[catIndex]['subCategories'] ?? [],
      );
      if (!subs.contains(trimmedSub)) {
        subs.add(trimmedSub);
        dbCategories[catIndex]['subCategories'] = subs;
      }
    }
    selectedSubCategory = trimmedSub;
    notifyListeners();
    try {
      var catQuery = await _firestore
          .collection('categories')
          .where('name', isEqualTo: catName)
          .limit(1)
          .get();
      if (catQuery.docs.isNotEmpty) {
        await _firestore
            .collection('categories')
            .doc(catQuery.docs.first.id)
            .update({
              'subCategories': FieldValue.arrayUnion([trimmedSub]),
            });
      }
    } catch (e) {}
  }

  Future<void> _fetchCurrentVendorDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentVendorId = user.uid;
      try {
        DocumentSnapshot doc = await _firestore
            .collection('vendors')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          currentVendorName =
              doc.get('storeName') ?? doc.get('ownerName') ?? "Vendor";
          vendorNameCtrl.text = currentVendorName;
          notifyListeners();
        }
      } catch (e) {}
    }
  }

  void toggleCompanyWarranty(bool value) {
    hasCompanyWarranty = value;
    notifyListeners();
  }

  void toggleShopWarranty(bool value) {
    hasShopWarranty = value;
    notifyListeners();
  }

  String _getCombinedWarranty() {
    String duration = selectedWarrantyDuration;
    if (customWarrantyCtrl.text.trim().isNotEmpty)
      duration = customWarrantyCtrl.text.trim();

    List<String> types = [];
    if (hasCompanyWarranty) types.add("Company");
    if (hasShopWarranty) types.add("Shop");

    // ✅ Agar dono false hain (yani select nahi kiye), toh sirf duration return hogi
    if (types.isEmpty) return duration;

    return "$duration (${types.join(' & ')} Warranty)";
  }

  Future<void> pickAndCropStoreImage(
    BuildContext context,
    ImageSource source,
  ) async {
    if (combinedImages.length >= 4) {
      // selectedImagesBase64 ki jagah combinedImages
      _showSnackBar(
        context,
        "Limit Reached",
        "Max 4 images allowed.",
        Colors.orange,
      );
      return;
    }
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Product Image',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop Product Image'),
            WebUiSettings(context: context, presentStyle: WebPresentStyle.page),
          ],
        );
        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          combinedImages.add(base64Encode(bytes)); // ✅ Combined mein add karein
          notifyListeners();
        }
      }
    } catch (e) {}
  }

  void removeImage(int index) {
    combinedImages.removeAt(index); // ✅ Combined se remove karein
    notifyListeners();
  }

  Future<bool> submitProductRequest(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    // ✅ 1. Form Validation (Ye text fields pe red error show karega)
    if (!formKey.currentState!.validate()) {
      _showSnackBar(
        context,
        "Form Error",
        "Kuch fields khali hain ya galat format mein hain. Check karein!",
        Colors.redAccent,
      );
      return false;
    }

    final Map<String, String> requiredFields = {
      'Product Name': nameCtrl.text,
      'Model Number': modelCtrl.text,
      'Description': descCtrl.text,
      'Brand': brandCtrl.text,
      'Sale Price (Marvellous)': purchaseCtrl.text,
      'Sale Price (Customers)': saleCtrl.text,
    };

    for (var entry in requiredFields.entries) {
      if (entry.value.trim().isEmpty) {
        _showSnackBar(
          context,
          "Missing Field",
          "\"${entry.key}\" khali hai — please fill karein!",
          Colors.redAccent,
        );
        return false;
      }
    }

    // ✅ 3. Agar Product Mobile hai toh RAM aur Storage bhi zaroori hai
    if (isMobile &&
        (ramCtrl.text.trim().isEmpty || storageCtrl.text.trim().isEmpty)) {
      _showSnackBar(
        context,
        "Missing Info",
        "Mobile ke liye RAM aur Storage fill karna zaroori hai!",
        Colors.redAccent,
      );
      return false;
    }

    // ✅ 4. Category Check
    if (selectedCategory == null) {
      _showSnackBar(
        context,
        "Required",
        "Please select a Category",
        Colors.redAccent,
      );
      return false;
    }

    // ✅ 5. Images Check
    if (combinedImages.isEmpty) {
      _showSnackBar(
        context,
        "Required",
        "Please upload at least 1 product image",
        Colors.redAccent,
      );
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      ProductModel requestProduct = ProductModel(
        name: nameCtrl.text.trim(),
        modelNumber: modelCtrl.text.trim(),
        description: descCtrl.text.trim(),
        tiktokVideoUrl: tiktokUrlCtrl.text.trim(), // Optional field
        category: selectedCategory!,
        subCategory: selectedSubCategory ?? "General",
        brand: brandCtrl.text.trim(), // Generic ki jagah ab mandatory hai
        purchasePrice: double.tryParse(purchaseCtrl.text) ?? 0,
        salePrice: double.tryParse(saleCtrl.text) ?? 0,
        originalPrice: double.tryParse(originalCtrl.text) ?? 0,
        stockQuantity: 1,
        vendorId: currentVendorId,
        vendorName: currentVendorName,
        images: combinedImages,
        dateAdded: selectedDate,
        deliveryLocation: "Pending Admin Review",
        warranty: _getCombinedWarranty(),
        productPoints: 0.0,
        deliveryFeesMap: {},
        deliveryTimeMap: {},
        codFee: 0.0,
        ram: isMobile ? ramCtrl.text : null,
        storage: isMobile ? storageCtrl.text : null,
        status: 'pending',
      );

      Map<String, dynamic> dataToSave = requestProduct.toMap();

      if (isEditMode) {
        if (editOriginalProductId != null) {
          var requestDoc = await _firestore
              .collection('product_requests')
              .doc(editOriginalProductId)
              .get();

          if (requestDoc.exists) {
            dataToSave['isEditRequest'] =
                requestDoc.data()?['isEditRequest'] ?? false;
            dataToSave['originalProductId'] = requestDoc
                .data()?['originalProductId'];
            dataToSave.remove('holdReason');

            await _firestore
                .collection('product_requests')
                .doc(editOriginalProductId)
                .update(dataToSave);
          } else {
            dataToSave['isEditRequest'] = true;
            dataToSave['originalProductId'] = editOriginalProductId;
            await _firestore.collection('product_requests').add(dataToSave);
          }
        }
      } else {
        await _firestore.collection('product_requests').add(dataToSave);
      }

      _clearForm();
      return true;
    } catch (e) {
      _showSnackBar(context, "Error", e.toString(), Colors.redAccent);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clearForm() {
    nameCtrl.clear();
    tiktokUrlCtrl.clear();
    modelCtrl.clear();
    descCtrl.clear();
    brandCtrl.clear();
    ramCtrl.clear();
    storageCtrl.clear();
    purchaseCtrl.clear();
    saleCtrl.clear();
    originalCtrl.clear();
    customWarrantyCtrl.clear();

    // ✅ YAHAN ADD KAREIN:
    combinedImages.clear(); // Purani images saaf ho jayengi

    selectedImagesBase64.clear();
    hasCompanyWarranty = false;
    hasShopWarranty = false;
    selectedWarrantyDuration = "No Warranty";
    selectedCategory = null;
    selectedSubCategory = null;
    isEditMode = false;
    isEditInitialized = false;
    editOriginalProductId = null;
    notifyListeners(); // UI refresh ho jayega aur image gayab ho jayegi
  }

  void _showSnackBar(
    BuildContext context,
    String title,
    String msg,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title: $msg"), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    nameCtrl.removeListener(_checkIfMobile);
    tiktokUrlCtrl.dispose(); // ✅ NAYA FIELD
    nameCtrl.dispose();
    modelCtrl.dispose();
    descCtrl.dispose();
    brandCtrl.dispose();
    ramCtrl.dispose();
    storageCtrl.dispose();
    purchaseCtrl.dispose();
    saleCtrl.dispose();
    originalCtrl.dispose();
    vendorNameCtrl.dispose();
    customWarrantyCtrl.dispose();
    super.dispose();
  }
}
