import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../auth/models/vendor_model.dart';
import '../../orders/controllers/vendor_orders_controller.dart';
import '../../products/viewmodels/vendor_products_controller.dart'; // ✅ Added import

class HomeTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomeTab({super.key, this.onNavigateToTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  VendorModel? vendor;
  bool isLoading = true;

  // ✅ Initialize Orders Controller to fetch real-time pending bills
  final VendorOrdersController _ordersCtrl = Get.put(VendorOrdersController());

  @override
  void initState() {
    super.initState();
    _fetchVendor();
  }

  Future<void> _fetchVendor() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(uid)
          .get();
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
      debugPrint('Vendor fetch error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Base64 → Profile Image ────────────────────────────────────────────────
  Widget _profileAvatar(double radius) {
    if (vendor?.profileImage != null && vendor!.profileImage!.isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(vendor!.profileImage!);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }
    // Fallback: first letter of name
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

  // ── Edit Dialog ───────────────────────────────────────────────────────────
  void _showEditDialog() {
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
          "Edit Store Details",
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
            child: Text(
              "Cancel",
              style: GoogleFonts.comicNeue(color: Colors.white54, fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009FFD),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveDetails(
                storeName: storeNameCtrl.text.trim(),
                storePhone: storePhoneCtrl.text.trim(),
                ownerName: ownerNameCtrl.text.trim(),
                ownerMobile: ownerMobileCtrl.text.trim(),
                contactPersonName: contactPersonCtrl.text.trim(),
                contactPersonPhone: contactPhoneCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
            },
            child: Text(
              "Save",
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF009FFD), width: 1.5),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDetails({
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
      await FirebaseFirestore.instance.collection('vendors').doc(uid).update({
        'storeName': storeName,
        'storePhone': storePhone,
        'ownerName': ownerName,
        'ownerMobile': ownerMobile,
        'contactPersonName': contactPersonName,
        'contactPersonPhone': contactPersonPhone,
        'address': address,
      });
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Details saved successfully!",
              style: GoogleFonts.comicNeue(fontSize: 16),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: $e",
              style: GoogleFonts.comicNeue(fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // ── Welcome Card ──────────────────────────────────────
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
                        _profileAvatar(36),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Overview",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Stats Grid ────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                      // ✅ NAYA: Product Controller Call For Live Count
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
                          _statCard(
                            "Available Balance",
                            "Rs ${vendor?.beginningBalance.toStringAsFixed(0) ?? '0'}",
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF00E676),
                            const Color(0xFF00C853),
                          ),

                          // ✅ FIX: Connected to VendorProductsController for Live Products count
                          Obx(
                            () => _statCard(
                              "Total Products",
                              productsCtrl.isLoadingLive.value
                                  ? "..."
                                  : "${productsCtrl.liveProducts.length}",
                              Icons.inventory_2_rounded,
                              const Color(0xFF40C4FF),
                              const Color(0xFF0091EA),
                            ),
                          ),

                          Obx(
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

                          _statCard(
                            "Categories",
                            "${vendor?.categories.length ?? 0}",
                            Icons.category_rounded,
                            const Color(0xFFE040FB),
                            const Color(0xFF9C27B0),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "Quick Actions",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Quick Actions ───────────────
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _quickActionButton(
                        "Add New\nProduct",
                        Icons.add_box_rounded,
                        const Color(0xFF40C4FF),
                        () => widget.onNavigateToTab?.call(5),
                      ),
                      // ✅ FIX: Added a Quick Action button for Bills & Orders
                      _quickActionButton(
                        "Bills &\nOrders",
                        Icons.receipt_long_rounded,
                        const Color(0xFFFFD740),
                        () => widget.onNavigateToTab?.call(6),
                      ),
                      _quickActionButton(
                        "Accounting\nDetails",
                        Icons.account_balance_rounded,
                        const Color(0xFF00E676),
                        () => widget.onNavigateToTab?.call(3),
                      ),
                      _quickActionButton(
                        "Add New\nStore",
                        Icons.add_business_rounded,
                        const Color(0xFFFF6090),
                        () => widget.onNavigateToTab?.call(2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── Complete Store Details Card ────────────────────────
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Store Details",
                                style: GoogleFonts.comicNeue(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              IconButton(
                                onPressed: _showEditDialog,
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF009FFD),
                                  size: 22,
                                ),
                                tooltip: "Edit Details",
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _sectionLabel("Store Info"),
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

                          const SizedBox(height: 10),
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

                          const SizedBox(height: 10),
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
