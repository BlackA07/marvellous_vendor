// lib/features/auth/viewmodels/auth_viewmodel.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/vendor_model.dart';
import '../views/pending_approval_screen.dart';
import '../../dashboard/views/dashboard_screen.dart'; // ✅ Dashboard Import add kiya

final authViewModelProvider = ChangeNotifierProvider((ref) => AuthViewModel());

class AuthViewModel extends ChangeNotifier {
  // --- Text Controllers ---
  final storeNameCtrl = TextEditingController();
  final storePhoneCtrl = TextEditingController();
  final ownerNameCtrl = TextEditingController();
  final ownerMobileCtrl = TextEditingController();
  final contactPersonCtrl = TextEditingController();
  final contactPersonPhoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final balanceCtrl = TextEditingController(text: '0');
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // --- State Variables ---
  String selectedCountryCode = '+92';
  bool isPassHidden = true;
  bool isLoading = false;

  XFile? faceImageFile;
  List<XFile> storeImageFiles = [];

  // --- Category Variables ---
  List<Map<String, dynamic>> dbCategories = [];
  List<String> selectedCategories = [];
  List<String> selectedSubCategories = [];

  List<Map<String, dynamic>> _pendingNewCategories = [];
  List<Map<String, dynamic>> _pendingNewSubCategories = [];

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel() {
    _fetchCategories();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CATEGORIES LOGIC - FULLY LOCAL
  // ════════════════════════════════════════════════════════════════════════════

  void _fetchCategories() {
    _firestore.collection('categories').snapshots().listen((snapshot) {
      dbCategories = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      notifyListeners();
    });
  }

  void addSelectedCategory(String name) {
    if (!selectedCategories.contains(name)) {
      selectedCategories.add(name);
      notifyListeners();
    }
  }

  void addNewCategoryLocally(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    if (!selectedCategories.contains(trimmed)) {
      selectedCategories.add(trimmed);

      bool alreadyInDb = dbCategories.any((c) => c['name'] == trimmed);
      if (!alreadyInDb) {
        _pendingNewCategories.add({'name': trimmed});
      }

      notifyListeners();

      Get.snackbar(
        "Category Added",
        "'$trimmed' added locally — will be saved after approval",
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void addSelectedSubCategory(String name) {
    if (!selectedSubCategories.contains(name)) {
      selectedSubCategories.add(name);
      notifyListeners();
    }
  }

  void addNewSubCategoryLocally(String categoryName, String subName) {
    final trimmedSub = subName.trim();
    if (trimmedSub.isEmpty) return;

    if (!selectedSubCategories.contains(trimmedSub)) {
      selectedSubCategories.add(trimmedSub);

      _pendingNewSubCategories.add({
        'categoryName': categoryName,
        'subName': trimmedSub,
      });

      notifyListeners();

      Get.snackbar(
        "Sub-Category Added",
        "'$trimmedSub' added locally — will be saved after approval",
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void removeSelectedCategory(String name) {
    selectedCategories.remove(name);
    _pendingNewCategories.removeWhere((c) => c['name'] == name);
    notifyListeners();
  }

  void removeSelectedSubCategory(String name) {
    selectedSubCategories.remove(name);
    _pendingNewSubCategories.removeWhere((c) => c['subName'] == name);
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // APPROVAL PE CATEGORIES FIRESTORE MEIN SAVE KARNA
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> syncPendingCategoriesToFirestore({
    required FirebaseFirestore firestore,
    required List<String> categories,
    required List<String> subCategories,
    required List<Map<String, dynamic>> pendingNewCategories,
    required List<Map<String, dynamic>> pendingNewSubCategories,
  }) async {
    try {
      for (var cat in pendingNewCategories) {
        String catName = cat['name'] ?? '';
        if (catName.isEmpty) continue;

        var existing = await firestore
            .collection('categories')
            .where('name', isEqualTo: catName)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await firestore.collection('categories').add({
            'name': catName,
            'subCategories': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      for (var sub in pendingNewSubCategories) {
        String catName = sub['categoryName'] ?? '';
        String subName = sub['subName'] ?? '';
        if (catName.isEmpty || subName.isEmpty) continue;

        var catQuery = await firestore
            .collection('categories')
            .where('name', isEqualTo: catName)
            .limit(1)
            .get();

        if (catQuery.docs.isNotEmpty) {
          await firestore
              .collection('categories')
              .doc(catQuery.docs.first.id)
              .update({
                'subCategories': FieldValue.arrayUnion([subName]),
              });
        }
      }

      debugPrint('✅ Categories synced to Firestore after approval');
    } catch (e) {
      debugPrint('⚠️ Category sync error (non-critical): $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  void togglePassVisibility() {
    isPassHidden = !isPassHidden;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> pickFaceImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 30,
        maxWidth: 500,
      );
      if (pickedFile != null) {
        faceImageFile = pickedFile;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Image picking error: $e");
    }
  }

  Future<void> pickAndCropStoreImage(
    BuildContext context,
    ImageSource source,
  ) async {
    if (storeImageFiles.length >= 4) {
      Get.snackbar(
        "Limit Reached",
        "You can only upload up to 4 store pictures.",
        backgroundColor: Colors.orange,
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
              toolbarTitle: 'Crop Store Picture',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            IOSUiSettings(
              title: 'Crop Store Picture',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            WebUiSettings(context: context, presentStyle: WebPresentStyle.page),
          ],
        );

        if (croppedFile != null) {
          storeImageFiles.add(XFile(croppedFile.path));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Store Image Error: $e");
    }
  }

  void removeStoreImage(int index) {
    storeImageFiles.removeAt(index);
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SIGNUP LOGIC
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> signUp(BuildContext context) async {
    if (storeNameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      _showError("Please fill all required fields!");
      return;
    }
    if (passCtrl.text != confirmPassCtrl.text) {
      _showError("Passwords do not match!");
      return;
    }
    if (faceImageFile == null) {
      _showError("Profile photo is required!");
      return;
    }
    if (storeImageFiles.isEmpty) {
      _showError("Please add at least 1 store picture!");
      return;
    }
    if (selectedCategories.isEmpty) {
      _showError("Please select at least 1 category!");
      return;
    }

    setLoading(true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailCtrl.text.trim(),
            password: passCtrl.text.trim(),
          );

      String uid = userCredential.user!.uid;

      String? faceBase64;
      try {
        final bytes = await faceImageFile!.readAsBytes();
        faceBase64 = base64Encode(bytes);
      } catch (e) {
        debugPrint('Face image encode error: $e');
      }

      List<String> storeBase64List = [];
      for (var xfile in storeImageFiles) {
        try {
          final bytes = await xfile.readAsBytes();
          storeBase64List.add(base64Encode(bytes));
        } catch (e) {
          debugPrint('Store image encode error: $e');
        }
      }

      String storePhone = "$selectedCountryCode${storePhoneCtrl.text.trim()}";
      String ownerPhone = "$selectedCountryCode${ownerMobileCtrl.text.trim()}";
      String contactPhone =
          "$selectedCountryCode${contactPersonPhoneCtrl.text.trim()}";
      double begBal = double.tryParse(balanceCtrl.text) ?? 0.0;

      VendorModel newVendor = VendorModel(
        uid: uid,
        storeName: storeNameCtrl.text.trim(),
        storePhone: storePhone,
        ownerName: ownerNameCtrl.text.trim(),
        ownerMobile: ownerPhone,
        contactPersonName: contactPersonCtrl.text.trim(),
        contactPersonPhone: contactPhone,
        email: emailCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        profileImage: faceBase64,
        storePictures: storeBase64List,
        categories: selectedCategories,
        subCategories: selectedSubCategories,
        beginningBalance: begBal,
        status: 'pending',
      );

      Map<String, dynamic> vendorMap = newVendor.toMap();
      vendorMap['pendingNewCategories'] = _pendingNewCategories;
      vendorMap['pendingNewSubCategories'] = _pendingNewSubCategories;

      await _firestore.collection('vendors').doc(uid).set(vendorMap);

      setLoading(false);
      if (context.mounted) {
        Get.snackbar(
          "Success 🎉",
          "Signup successful! Waiting for admin approval.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAll(() => const PendingApprovalScreen());
      }
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      _showError(e.message ?? "Authentication Failed");
    } catch (e) {
      setLoading(false);
      _showError("An unexpected error occurred: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOGIN LOGIC
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> login(BuildContext context) async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      _showError("Email and Password are required!");
      return;
    }
    setLoading(true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      String uid = userCredential.user!.uid;
      DocumentSnapshot vendorDoc = await _firestore
          .collection('vendors')
          .doc(uid)
          .get();

      if (vendorDoc.exists) {
        String status = vendorDoc.get('status');
        setLoading(false);
        if (status == 'pending') {
          Get.offAll(() => const PendingApprovalScreen());
        } else if (status == 'approved') {
          // ✅ FIX: Ab login success par DashboardScreen par le jaiga
          Get.offAll(() => const DashboardScreen());
          Get.snackbar(
            "Welcome",
            "Login Successful!",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else if (status == 'rejected') {
          await _auth.signOut();
          _showError("Your application was rejected by the Admin.");
        }
      } else {
        setLoading(false);
        await _auth.signOut();
        _showError("No vendor record found for this account.");
      }
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      _showError(e.message ?? "Login Failed");
    } catch (e) {
      setLoading(false);
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}
