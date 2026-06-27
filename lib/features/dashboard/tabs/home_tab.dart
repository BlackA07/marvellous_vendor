// Path: lib/features/dashboard/presentation/tabs/home_tab.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifications/controllers/vendor_notifications_controller.dart';
import '../../orders/presentation/screens/vendor_order_requests_screen.dart';
import '../../products/views/vendor_my_products_screen.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/vendor_model.dart';
import '../../notifications/screens/vendor_notifications_screen.dart';
import '../../orders/controllers/vendor_orders_controller.dart';
import '../../products/viewmodels/vendor_products_controller.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomeTab({super.key, this.onNavigateToTab});
  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  VendorModel? vendor;
  bool isLoading = true;
  int pendingOrderRequestsCount = 0;
  double dueTodayAmount = 0.0;
  StreamSubscription? _orderReqSub;
  StreamSubscription? _duesSub;
  final VendorOrdersController _ordersCtrl = Get.put(VendorOrdersController());
  final VendorNotificationsController _notifCtrl = Get.put(
    VendorNotificationsController(),
  );

  @override
  void initState() {
    super.initState();
    _fetchVendor();
    _listenToDashboardStats();
  }

  @override
  void dispose() {
    _orderReqSub?.cancel();
    _duesSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchVendor() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await _db.collection('vendors').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          vendor = VendorModel(
            uid: data['uid'] ?? '',
            storeName: data['storeName'] ?? '',
            storePhone: data['storePhone'] ?? '',
            ownerName: data['ownerName'] ?? '',
            ownerMobile: data['ownerMobile'] ?? '',
            contactPersonName: data['contactPersonName'] ?? '',
            contactPersonPhone: data['contactPersonPhone'] ?? '',
            email: data['email'] ?? '',
            categories: List<String>.from(data['categories'] ?? []),
            subCategories: List<String>.from(data['subCategories'] ?? []),
            address: data['address'] ?? '',
            profileImage: data['profileImage'],
            storePictures: List<String>.from(data['storePictures'] ?? []),
            beginningBalance: (data['beginningBalance'] ?? 0).toDouble(),
            status: data['status'] ?? 'pending',
          );
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _listenToDashboardStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _orderReqSub = _db
        .collection('order_requests')
        .where('vendorId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(() {
              pendingOrderRequestsCount = snap.docs.length;
            });
          }
        });
    _duesSub = _db
        .collection('vendor_dues')
        .where('vendorId', isEqualTo: uid)
        .where('isPaid', isEqualTo: false)
        .snapshots()
        .listen((snap) {
          double todayTotal = 0.0;
          DateTime now = DateTime.now();
          for (var doc in snap.docs) {
            var data = doc.data();
            Timestamp? ts = data['dueDate'] as Timestamp?;
            if (ts != null) {
              DateTime d = ts.toDate();
              if (d.year == now.year &&
                  d.month == now.month &&
                  d.day == now.day) {
                double original =
                    (data['originalAmountDue'] ?? data['amountDue'] ?? 0.0)
                        .toDouble();
                double paid = (data['paidAmount'] ?? 0.0).toDouble();
                double rem = original - paid;
                if (rem > 0) todayTotal += rem;
              }
            }
          }
          if (mounted) {
            setState(() {
              dueTodayAmount = todayTotal;
            });
          }
        });
  }

  Widget _profileAvatar(double radius) {
    if (vendor?.profileImage != null && vendor!.profileImage!.isNotEmpty) {
      try {
        String cleanBase64 = vendor!.profileImage!.contains(',')
            ? vendor!.profileImage!.split(',').last
            : vendor!.profileImage!;
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(
            base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), '')),
          ),
        );
      } catch (e) {
        debugPrint("Error decoding avatar: $e");
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: Text(
        (vendor?.ownerName.isNotEmpty == true)
            ? vendor!.ownerName[0].toUpperCase()
            : "V",
        style: GoogleFonts.comicNeue(
          color: Colors.white,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _openFullScreenImage(String base64Str) {
    String cleanBase64 = base64Str.contains(',')
        ? base64Str.split(',').last
        : base64Str;
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: Center(
            child: Image.memory(
              base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), '')),
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit Store Info (text fields only) ──
  void _showEditInfoDialog() {
    if (vendor == null) return;

    final storeNameCtrl = TextEditingController(text: vendor!.storeName);
    final storePhoneCtrl = TextEditingController(text: vendor!.storePhone);
    final ownerNameCtrl = TextEditingController(text: vendor!.ownerName);
    final ownerMobileCtrl = TextEditingController(text: vendor!.ownerMobile);
    final contactPersonCtrl = TextEditingController(
      text: vendor!.contactPersonName,
    );
    final contactPhoneCtrl = TextEditingController(
      text: vendor!.contactPersonPhone,
    );
    final addressCtrl = TextEditingController(text: vendor!.address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          "Edit Store Info",
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField("Store Name", storeNameCtrl, Icons.store_rounded),
              _editField("Store Phone", storePhoneCtrl, Icons.phone_rounded),
              _editField("Owner Name", ownerNameCtrl, Icons.person_rounded),
              _editField(
                "Owner Mobile",
                ownerMobileCtrl,
                Icons.smartphone_rounded,
              ),
              _editField(
                "Contact Person",
                contactPersonCtrl,
                Icons.support_agent_rounded,
              ),
              _editField(
                "Contact Phone",
                contactPhoneCtrl,
                Icons.phone_in_talk_rounded,
              ),
              _editField("Address", addressCtrl, Icons.location_on_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009FFD),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveStoreInfo(
                storeName: storeNameCtrl.text.trim(),
                storePhone: storePhoneCtrl.text.trim(),
                ownerName: ownerNameCtrl.text.trim(),
                ownerMobile: ownerMobileCtrl.text.trim(),
                contactPersonName: contactPersonCtrl.text.trim(),
                contactPersonPhone: contactPhoneCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Profile Image ──
  void _showEditProfileImageDialog() {
    if (vendor == null) return;
    String? tempBase64 = vendor!.profileImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            "Edit Profile Image",
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final XFile? picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 30,
                  );
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    setDialogState(() => tempBase64 = base64Encode(bytes));
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          (tempBase64 != null && tempBase64!.isNotEmpty)
                          ? MemoryImage(
                              base64Decode(
                                tempBase64!.contains(',')
                                    ? tempBase64!.split(',').last
                                    : tempBase64!,
                              ),
                            )
                          : null,
                      child: (tempBase64 == null || tempBase64!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF009FFD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tap photo to change",
                style: GoogleFonts.comicNeue(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009FFD),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                await _db.collection('vendors').doc(uid).update({
                  'profileImage': tempBase64,
                });
                if (mounted) {
                  setState(() {
                    vendor = VendorModel(
                      uid: vendor!.uid,
                      storeName: vendor!.storeName,
                      storePhone: vendor!.storePhone,
                      ownerName: vendor!.ownerName,
                      ownerMobile: vendor!.ownerMobile,
                      contactPersonName: vendor!.contactPersonName,
                      contactPersonPhone: vendor!.contactPersonPhone,
                      email: vendor!.email,
                      categories: vendor!.categories,
                      subCategories: vendor!.subCategories,
                      address: vendor!.address,
                      profileImage: tempBase64,
                      storePictures: vendor!.storePictures,
                      beginningBalance: vendor!.beginningBalance,
                      status: vendor!.status,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile image updated!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Store Pictures ──
  void _showEditStorePicturesDialog() {
    if (vendor == null) return;
    List<String> tempPictures = List.from(vendor!.storePictures);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            "Edit Store Pictures",
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tempPictures.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No store pictures yet.\nTap below to add.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 210,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: tempPictures.length,
                      itemBuilder: (context, index) {
                        String img = tempPictures[index];
                        String clean = img.contains(',')
                            ? img.split(',').last
                            : img;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(
                                  clean.replaceAll(RegExp(r'\s+'), ''),
                                ),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setDialogState(
                                  () => tempPictures.removeAt(index),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                if (tempPictures.length < 4)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final XFile? picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 30,
                      );
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setDialogState(
                          () => tempPictures.add(base64Encode(bytes)),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      color: Color(0xFF009FFD),
                    ),
                    label: Text(
                      "Add Picture (${tempPictures.length}/4)",
                      style: GoogleFonts.comicNeue(
                        color: const Color(0xFF009FFD),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF009FFD)),
                    ),
                  )
                else
                  Text(
                    "Maximum 4 pictures reached",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009FFD),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                await _db.collection('vendors').doc(uid).update({
                  'storePictures': tempPictures,
                });
                if (mounted) {
                  setState(() {
                    vendor = VendorModel(
                      uid: vendor!.uid,
                      storeName: vendor!.storeName,
                      storePhone: vendor!.storePhone,
                      ownerName: vendor!.ownerName,
                      ownerMobile: vendor!.ownerMobile,
                      contactPersonName: vendor!.contactPersonName,
                      contactPersonPhone: vendor!.contactPersonPhone,
                      email: vendor!.email,
                      categories: vendor!.categories,
                      subCategories: vendor!.subCategories,
                      address: vendor!.address,
                      profileImage: vendor!.profileImage,
                      storePictures: tempPictures,
                      beginningBalance: vendor!.beginningBalance,
                      status: vendor!.status,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Store pictures updated!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.comicNeue(
            color: Colors.white54,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> _saveStoreInfo({
    required String storeName,
    required String storePhone,
    required String ownerName,
    required String ownerMobile,
    required String contactPersonName,
    required String contactPersonPhone,
    required String address,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('vendors').doc(uid).update({
        'storeName': storeName,
        'storePhone': storePhone,
        'ownerName': ownerName,
        'ownerMobile': ownerMobile,
        'contactPersonName': contactPersonName,
        'contactPersonPhone': contactPersonPhone,
        'address': address,
      });
      if (mounted) {
        setState(() {
          vendor = VendorModel(
            uid: vendor!.uid,
            storeName: storeName,
            storePhone: storePhone,
            ownerName: ownerName,
            ownerMobile: ownerMobile,
            contactPersonName: contactPersonName,
            contactPersonPhone: contactPersonPhone,
            email: vendor!.email,
            categories: vendor!.categories,
            subCategories: vendor!.subCategories,
            address: address,
            profileImage: vendor!.profileImage,
            storePictures: vendor!.storePictures,
            beginningBalance: vendor!.beginningBalance,
            status: vendor!.status,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showAccountSwitcher(BuildContext context) {
    final viewModel = ref.read(authViewModelProvider);
    String? currentEmail = FirebaseAuth.instance.currentUser?.email;
    final outerContext = context; // ✅ yahan store karo

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // ✅ alag naam do
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Switch Account",
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: viewModel.savedAccounts.length,
                  itemBuilder: (context, index) {
                    final acc = viewModel.savedAccounts[index];
                    bool isCurrent = acc['email'] == currentEmail;
                    String? profileImgStr = acc['profileImage']?.toString();

                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            if (!isCurrent) {
                              viewModel.switchAccount(
                                acc['email']!,
                                acc['password']!,
                              );
                            }
                          },
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isCurrent
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.shade800,
                            backgroundImage:
                                (profileImgStr != null &&
                                    profileImgStr.isNotEmpty)
                                ? MemoryImage(
                                    base64Decode(
                                      profileImgStr.contains(',')
                                          ? profileImgStr.split(',').last
                                          : profileImgStr,
                                    ),
                                  )
                                : null,
                            child:
                                (profileImgStr == null || profileImgStr.isEmpty)
                                ? Icon(
                                    Icons.store,
                                    color: isCurrent
                                        ? Colors.green
                                        : Colors.white54,
                                    size: 20,
                                  )
                                : null,
                          ),
                          title: Text(
                            acc['storeName'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.green : Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            acc['email'] ?? '',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: sheetContext,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: const Color(
                                          0xFF1E1E1E,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Row(
                                          children: const [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.redAccent,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Remove Account",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          "Are you sure you want to remove\n'${acc['storeName'] ?? acc['email']}'?",
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text(
                                              "Cancel",
                                              style: TextStyle(
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              "Yes, Remove",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await viewModel.removeAccount(index);
                                      Navigator.pop(sheetContext);
                                      _showAccountSwitcher(outerContext);
                                    }
                                  },
                                ),
                        ),
                        const Divider(color: Colors.white12),
                      ],
                    );
                  },
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF009FFD),
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: const Text(
                  "Add Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF009FFD),
                  ),
                ),
                onTap: () async {
                  Get.back();
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(() => const LoginScreen());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: (isLoading || authViewModel.isLoading)
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // ── Welcome Banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A2A72), Color(0xFF009FFD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF009FFD).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome,",
                                style: GoogleFonts.comicNeue(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vendor?.ownerName ?? "Vendor",
                                style: GoogleFonts.comicNeue(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vendor?.storeName ?? "",
                                style: GoogleFonts.comicNeue(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Order Requests Badge
                            InkWell(
                              onTap: () => Get.to(
                                () => const VendorOrderRequestsScreen(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.assignment_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  if (pendingOrderRequestsCount > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          pendingOrderRequestsCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Notifications Badge
                            Obx(() {
                              int unreadCount = _notifCtrl.notifications
                                  .where((n) => !n.isRead)
                                  .length;
                              return InkWell(
                                onTap: () => Get.to(
                                  () => const VendorNotificationsScreen(),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.notifications_active_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(width: 12),

                            // Logout
                            GestureDetector(
                              onTap: () async {
                                Get.defaultDialog(
                                  title: 'Logout',
                                  titleStyle: GoogleFonts.comicNeue(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  backgroundColor: const Color(0xFF2A2D3E),
                                  middleText:
                                      'Are you sure you want to logout?',
                                  middleTextStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  textConfirm: 'Yes, Logout',
                                  textCancel: 'Cancel',
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.redAccent,
                                  cancelTextColor: Colors.cyanAccent,
                                  onConfirm: () async {
                                    Get.back();
                                    await FirebaseAuth.instance.signOut();
                                    Get.offAll(() => const LoginScreen());
                                  },
                                );
                              },
                              child: const Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Avatar + Account Switcher
                            GestureDetector(
                              onTap: () => _showAccountSwitcher(context),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  _profileAvatar(34),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_drop_down_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Overview ──
                  Text(
                    "Overview",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      final VendorProductsController productsCtrl = Get.put(
                        VendorProductsController(),
                      );
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.35,
                        children: [
                          GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(2),
                            child: _statCard(
                              "Available Balance",
                              "Rs ${vendor?.beginningBalance.toStringAsFixed(0) ?? '0'}",
                              Icons.account_balance_wallet_rounded,
                              const Color(0xFF00E676),
                              const Color(0xFF00C853),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Get.to(() => const VendorMyProductsScreen()),
                            child: Obx(
                              () => _statCard(
                                "Live / Pending",
                                (productsCtrl.isLoadingLive.value ||
                                        productsCtrl.isLoadingPending.value)
                                    ? "..."
                                    : "${productsCtrl.liveProducts.length} / ${productsCtrl.pendingRequests.length}",
                                Icons.inventory_2_rounded,
                                const Color(0xFF40C4FF),
                                const Color(0xFF0091EA),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(5),
                            child: Obx(
                              () => _statCard(
                                "Pending Bills",
                                _ordersCtrl.isLoading.value
                                    ? "..."
                                    : "${_ordersCtrl.pendingOrders.length}",
                                Icons.receipt_long_rounded,
                                const Color(0xFFFFD740),
                                const Color(0xFFFF6D00),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(2),
                            child: _statCard(
                              "Due Today",
                              "Rs ${dueTodayAmount.toStringAsFixed(0)}",
                              Icons.today_rounded,
                              const Color(0xFFE040FB),
                              const Color(0xFF9C27B0),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // ── Quick Actions ──
                  Text(
                    "Quick Actions",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _quickActionButton(
                        "Add New\nProduct",
                        Icons.add_box_rounded,
                        Colors.green,
                        () => widget.onNavigateToTab?.call(4),
                      ),
                      _quickActionButton(
                        "Bills &\nOrders",
                        Icons.receipt_long_rounded,
                        Colors.orange,
                        () => widget.onNavigateToTab?.call(5),
                      ),
                      _quickActionButton(
                        "Accounting\nDetails",
                        Icons.account_balance_rounded,
                        Colors.teal,
                        () => widget.onNavigateToTab?.call(2),
                      ),
                      _quickActionButton(
                        "Reports",
                        Icons.bar_chart_rounded,
                        Colors.amber,
                        () => widget.onNavigateToTab?.call(3),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── Store Details Card ──
                  if (vendor != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            "Store Details",
                            style: GoogleFonts.comicNeue(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── SECTION 1: Profile Image ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionLabel("Profile Image"),
                              TextButton.icon(
                                onPressed: _showEditProfileImageDialog,
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF009FFD),
                                  size: 15,
                                ),
                                label: Text(
                                  "Edit",
                                  style: GoogleFonts.comicNeue(
                                    color: const Color(0xFF009FFD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                if (vendor!.profileImage != null &&
                                    vendor!.profileImage!.isNotEmpty) {
                                  _openFullScreenImage(vendor!.profileImage!);
                                }
                              },
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  _profileAvatar(50),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF009FFD),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),

                          // ── SECTION 2: Store Info ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionLabel("Store Info"),
                              TextButton.icon(
                                onPressed: _showEditInfoDialog,
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF009FFD),
                                  size: 15,
                                ),
                                label: Text(
                                  "Edit",
                                  style: GoogleFonts.comicNeue(
                                    color: const Color(0xFF009FFD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          _infoRow(
                            Icons.store_rounded,
                            "Store Name",
                            vendor!.storeName,
                          ),
                          _infoRow(
                            Icons.phone_rounded,
                            "Store Phone",
                            vendor!.storePhone,
                          ),
                          _infoRow(
                            Icons.location_on_rounded,
                            "Address",
                            vendor!.address,
                          ),
                          _infoRow(Icons.email_rounded, "Email", vendor!.email),

                          const SizedBox(height: 12),
                          _sectionLabel("Owner Info"),
                          _infoRow(
                            Icons.person_rounded,
                            "Owner Name",
                            vendor!.ownerName,
                          ),
                          _infoRow(
                            Icons.smartphone_rounded,
                            "Owner Mobile",
                            vendor!.ownerMobile,
                          ),

                          const SizedBox(height: 12),
                          _sectionLabel("Contact Person"),
                          _infoRow(
                            Icons.support_agent_rounded,
                            "Name",
                            vendor!.contactPersonName,
                          ),
                          _infoRow(
                            Icons.phone_in_talk_rounded,
                            "Phone",
                            vendor!.contactPersonPhone,
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),

                          // ── SECTION 3: Store Pictures ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionLabel("Store Pictures"),
                              TextButton.icon(
                                onPressed: _showEditStorePicturesDialog,
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF009FFD),
                                  size: 15,
                                ),
                                label: Text(
                                  "Edit",
                                  style: GoogleFonts.comicNeue(
                                    color: const Color(0xFF009FFD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (vendor!.storePictures.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white12,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.white24,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "No store pictures yet",
                                    style: GoogleFonts.comicNeue(
                                      color: Colors.white38,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: vendor!.storePictures.length,
                                itemBuilder: (context, index) {
                                  String img = vendor!.storePictures[index];
                                  String cleanBase64 = img.contains(',')
                                      ? img.split(',').last
                                      : img;
                                  return GestureDetector(
                                    onTap: () => _openFullScreenImage(img),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: MemoryImage(
                                            base64Decode(
                                              cleanBase64.replaceAll(
                                                RegExp(r'\s+'),
                                                '',
                                              ),
                                            ),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color lightColor,
    Color darkColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: lightColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: lightColor, size: 22),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.comicNeue(
              color: const Color.fromARGB(153, 255, 255, 255),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.comicNeue(
          color: const Color(0xFF009FFD),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: GoogleFonts.comicNeue(
              color: Colors.white54,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "—",
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
