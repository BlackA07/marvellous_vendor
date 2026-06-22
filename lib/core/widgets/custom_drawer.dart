import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/dashboard/viewmodels/dashboard_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  int _pendingSellRequests = 0;

  @override
  void initState() {
    super.initState();
    _listenToSellRequests();
  }

  void _listenToSellRequests() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('order_requests')
        .where('vendorId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          if (mounted) setState(() => _pendingSellRequests = snap.docs.length);
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(dashboardNavProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F1F1F), Color(0xFF0A0A0A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.blueAccent, width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                  ),
                  child: Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Vendor Panel",
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _drawerTile(
                  context,
                  ref,
                  title: "Dashboard",
                  icon: Icons.dashboard_rounded,
                  index: 0,
                  currentIndex: currentIndex,
                  color: Colors.cyanAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "My Products",
                  icon: Icons.inventory_2_rounded,
                  index: 1,
                  currentIndex: currentIndex,
                  color: Colors.lightBlueAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "Finance & Wallet",
                  icon: Icons.account_balance_wallet_rounded,
                  index: 2,
                  currentIndex: currentIndex,
                  color: Colors.tealAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "Reports",
                  icon: Icons.bar_chart_rounded,
                  index: 3,
                  currentIndex: currentIndex,
                  color: Colors.amberAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "Add New Product",
                  icon: Icons.add_box_rounded,
                  index: 4,
                  currentIndex: currentIndex,
                  color: Colors.greenAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "Bills & Orders",
                  icon: Icons.receipt_long_rounded,
                  index: 5,
                  currentIndex: currentIndex,
                  color: Colors.orangeAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "Sell Requests",
                  icon: Icons.request_page_rounded,
                  index: 6,
                  currentIndex: currentIndex,
                  color: Colors.pinkAccent,
                  badgeCount: _pendingSellRequests,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required int index,
    required int currentIndex,
    required Color color,
    int? badgeCount,
  }) {
    bool isSelected = currentIndex == index;
    return ListTile(
      leading: Badge(
        isLabelVisible: badgeCount != null && badgeCount > 0,
        label: Text("${badgeCount ?? 0}"),
        child: Icon(icon, color: isSelected ? color : Colors.white38),
      ),
      title: Text(
        title,
        style: TextStyle(color: isSelected ? Colors.white : Colors.white60),
      ),
      onTap: () {
        ref.read(dashboardNavProvider.notifier).state = index;
        Navigator.pop(context);
      },
    );
  }
}
