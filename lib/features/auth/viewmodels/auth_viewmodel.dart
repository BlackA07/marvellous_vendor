// lib/features/auth/viewmodels/auth_viewmodel.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ IMPORT ADD KIYA
import '../models/vendor_model.dart';
import '../views/pending_approval_screen.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../views/signup_screen.dart';

final authViewModelProvider = ChangeNotifierProvider((ref) => AuthViewModel());

class AuthViewModel extends ChangeNotifier {
  // --- Text Controllers (Signup) ---
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

  // --- Text Controllers (Login) ---
  final loginEmailCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();

  // --- State Variables ---
  String selectedCountryCode = '+92';
  bool isPassHidden = true; // Signup ke liye
  bool isLoginPassHidden = true;
  bool isLoading = false;

  XFile? faceImageFile;
  List<XFile> storeImageFiles = [];

  // --- Category Variables ---
  List<Map<String, dynamic>> dbCategories = [];
  List<String> selectedCategories = [];
  List<String> selectedSubCategories = [];

  List<Map<String, dynamic>> _pendingNewCategories = [];
  List<Map<String, dynamic>> _pendingNewSubCategories = [];

  // ✅ NAYA: Saved accounts list
  List<Map<String, String>> savedAccounts = [];

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel() {
    _fetchCategories();
    _loadSavedAccounts(); // ✅ NAYA: Initialize hone par saved accounts load karein
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MULTI-ACCOUNT LOGIC (SHARED PREFERENCES)
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('saved_accounts');
    if (accountsJson != null) {
      final List<dynamic> decodedList = jsonDecode(accountsJson);
      savedAccounts = decodedList
          .map((e) => Map<String, String>.from(e))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _saveAccountToLocal(
    String email,
    String password,
    String storeName,
    String? profileImage, // ✅ Naya parameter add kiya
  ) async {
    final prefs = await SharedPreferences.getInstance();

    int existingIndex = savedAccounts.indexWhere(
      (acc) => acc['email'] == email,
    );

    final accountData = {
      'email': email,
      'password': password,
      'storeName': storeName,
      'profileImage': profileImage ?? '', // ✅ Image save karein
    };

    if (existingIndex != -1) {
      savedAccounts[existingIndex] = accountData;
    } else {
      savedAccounts.add(accountData);
    }

    await prefs.setString('saved_accounts', jsonEncode(savedAccounts));
    notifyListeners();
  }

  Future<void> switchAccount(String email, String password) async {
    setLoading(true);
    Get.back(); // Bottom sheet close karne k liye

    try {
      // 1. Current account se sign out karein
      await _auth.signOut();

      // 2. Naye account mein sign in karein
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
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
          Get.offAll(() => const DashboardScreen());
          Get.snackbar(
            "Account Switched",
            "Switched to ${vendorDoc.get('storeName')}",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else if (status == 'rejected') {
          _showError("This account was rejected. Please contact support.");
        }
      } else {
        setLoading(false);
        _showError("Vendor record not found.");
      }
    } catch (e) {
      setLoading(false);
      _showError("Failed to switch account: $e");
    }
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

  void toggleLoginPassVisibility() {
    isLoginPassHidden = !isLoginPassHidden;
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
        imageQuality: 30,
        maxWidth: 800,
        maxHeight: 800,
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
  // SIGNUP LOGIC (WITH SMART RE-APPLY OVERWRITE)
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

      await _processAndSaveVendorData(userCredential.user!.uid, context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          UserCredential loginCred = await _auth.signInWithEmailAndPassword(
            email: emailCtrl.text.trim(),
            password: passCtrl.text.trim(),
          );

          DocumentSnapshot doc = await _firestore
              .collection('vendors')
              .doc(loginCred.user!.uid)
              .get();

          if (doc.exists) {
            String existingStatus = doc.get('status');

            if (existingStatus == 'rejected') {
              // ✅ Delete nahi karo — same doc ko overwrite karo
              await _processAndSaveVendorData(loginCred.user!.uid, context);
            } else if (existingStatus == 'hold') {
              // ✅ Hold pe bhi reapply allow karo
              await _processAndSaveVendorData(loginCred.user!.uid, context);
            } else if (existingStatus == 'pending') {
              setLoading(false);
              _showError("Your application is already pending approval!");
            } else {
              setLoading(false);
              _showError(
                "This account is already approved. Please go to Login.",
              );
            }
          } else {
            await _processAndSaveVendorData(loginCred.user!.uid, context);
          }
        } on FirebaseAuthException catch (loginError) {
          setLoading(false);
          if (loginError.code == 'wrong-password' ||
              loginError.code == 'invalid-credential') {
            _showError(
              "This email is already registered with a different password. "
              "If you were rejected previously, please contact admin to clear your account.",
            );
          } else {
            _showError("Email already in use: ${loginError.message}");
          }
        } catch (e) {
          setLoading(false);
          _showError("An unexpected error occurred: $e");
        }
      } else {
        setLoading(false);
        _showError(e.message ?? "Authentication Failed");
      }
    } catch (e) {
      setLoading(false);
      _showError("An unexpected error occurred: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTION: TO SAVE VENDOR DATA IN FIRESTORE
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _processAndSaveVendorData(
    String uid,
    BuildContext context,
  ) async {
    try {
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
          "Application submitted! Waiting for admin approval.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAll(() => const PendingApprovalScreen());
      }
    } catch (e) {
      setLoading(false);
      _showError("Data saving error: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOGIN LOGIC (UPDATED FOR REJECTED VENDORS)
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> login(BuildContext context) async {
    if (loginEmailCtrl.text.isEmpty || loginPassCtrl.text.isEmpty) {
      _showError("Email and Password are required!");
      return;
    }
    setLoading(true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: loginEmailCtrl.text.trim(),
        password: loginPassCtrl.text.trim(),
      );

      String uid = userCredential.user!.uid;
      DocumentSnapshot vendorDoc = await _firestore
          .collection('vendors')
          .doc(uid)
          .get();

      if (vendorDoc.exists) {
        String status = vendorDoc.get('status');

        if (status == 'pending') {
          setLoading(false);
          Get.offAll(() => const PendingApprovalScreen());
        } else if (status == 'approved') {
          await _saveAccountToLocal(
            loginEmailCtrl.text.trim(),
            loginPassCtrl.text.trim(),
            vendorDoc.get('storeName') ?? 'Unknown Store',
            vendorDoc.get('profileImage'), // ✅ Image yahan se pass hogi
          );
          setLoading(false);
          Get.offAll(() => const DashboardScreen());
          Get.snackbar(
            "Welcome",
            "Login Successful!",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else if (status == 'rejected') {
          // ✅ Reason nikaalo pehle
          String reason = '';
          try {
            reason = vendorDoc.get('rejectionReason') ?? '';
          } catch (_) {}
          if (reason.isEmpty) reason = 'No reason provided. Contact admin.';

          // ✅ Firestore doc + Firebase Auth account dono delete karo
          // taake same email se dobara apply ho sake
          try {
            await _firestore.collection('vendors').doc(uid).delete();
          } catch (e) {
            debugPrint('Vendor doc delete error: $e');
          }
          try {
            await userCredential.user!.delete();
          } catch (e) {
            debugPrint('Auth delete error: $e');
          }

          setLoading(false);

          // ✅ Reason dikhao + signup ka option do
          Get.dialog(
            barrierDismissible: false,
            AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    "Application Rejected",
                    style: GoogleFonts.orbitron(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your vendor application was rejected by admin.",
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Reason: $reason",
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your previous data has been cleared. You can re-apply with the same email after fixing the issues.",
                    style: GoogleFonts.comicNeue(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "Stay on Login",
                    style: GoogleFonts.comicNeue(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    // ✅ Email pre-fill kar do signup mein
                    emailCtrl.text = loginEmailCtrl.text;
                    Get.off(() => const SignupScreen());
                  },
                  child: Text(
                    "Re-Apply Now",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
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

  // ════════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD LOGIC
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> forgotPassword(String emailAddress) async {
    if (emailAddress.isEmpty) {
      _showError("Please enter your email first!");
      return;
    }
    setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: emailAddress.trim());
      setLoading(false);
      Get.snackbar(
        "Email Sent",
        "Password reset link has been sent to your email.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      _showError(e.message ?? "Failed to send reset link");
    } catch (e) {
      setLoading(false);
      _showError("An error occurred: $e");
    }
  }

  Future<void> removeAccount(int index) async {
    final prefs = await SharedPreferences.getInstance();
    savedAccounts.removeAt(index);
    await prefs.setString('saved_accounts', jsonEncode(savedAccounts));
    notifyListeners();
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
