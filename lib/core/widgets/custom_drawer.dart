import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../features/dashboard/viewmodels/dashboard_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(dashboardNavProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: Column(
        children: [
          // ── Drawer Header ─────────────────────────────────────────────
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
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    color: Colors.black54,
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.cyanAccent,
                    size: 35,
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
                const SizedBox(height: 5),
                Text(
                  user?.email ?? "vendor@example.com",
                  style: GoogleFonts.comicNeue(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation Items ──────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                // Section label: Main
                _sectionLabel("Main"),

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

                // Section label: Sales
                _sectionLabel("Sales"),

                _drawerTile(
                  context,
                  ref,
                  title: "Add New Product",
                  icon: Icons.add_box_rounded,
                  index: 5,
                  currentIndex: currentIndex,
                  color: Colors.greenAccent,
                ),

                // ✅ FIX: "Orders" ko "Bills & Orders" kar diya aur Icon change kar diya
                _drawerTile(
                  context,
                  ref,
                  title: "Bills & Orders",
                  icon: Icons.receipt_long_rounded,
                  index: 6,
                  currentIndex: currentIndex,
                  color: Colors.orangeAccent,
                ),

                _drawerTile(
                  context,
                  ref,
                  title: "Sell Requests",
                  icon: Icons.request_page_rounded,
                  index: 7,
                  currentIndex: currentIndex,
                  color: Colors.pinkAccent,
                ),

                // Section label: Management
                _sectionLabel("Management"),

                _drawerTile(
                  context,
                  ref,
                  title: "Manage Stores",
                  icon: Icons.store_rounded,
                  index: 2,
                  currentIndex: currentIndex,
                  color: Colors.purpleAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "Finance & Wallet",
                  icon: Icons.account_balance_wallet_rounded,
                  index: 3,
                  currentIndex: currentIndex,
                  color: Colors.tealAccent,
                ),
                _drawerTile(
                  context,
                  ref,
                  title: "Reports",
                  icon: Icons.bar_chart_rounded,
                  index: 4,
                  currentIndex: currentIndex,
                  color: Colors.amberAccent,
                ),
              ],
            ),
          ),

          // ── Logout ────────────────────────────────────────────────────
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(
              "Logout",
              style: GoogleFonts.comicNeue(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => const LoginScreen());
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 14, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.comicNeue(
          color: Colors.white24,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ── Drawer Tile ───────────────────────────────────────────────────────────
  Widget _drawerTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required int index,
    required int currentIndex,
    required Color color,
  }) {
    bool isSelected = currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? color : Colors.white38,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.comicNeue(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 17,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
        onTap: () {
          ref.read(dashboardNavProvider.notifier).state = index;
          Navigator.pop(context);
        },
      ),
    );
  }
}
