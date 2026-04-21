// lib/features/dashboard/views/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../tabs/home_tab.dart';
import '../tabs/placeholder_tabs.dart'; // Baki dummy screens k liye
import '../../products/views/add_product_screen.dart'; // ✅ Nayi Vendor Add Product Screen ka import

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(dashboardNavProvider);

    // Dynamic Title based on selected tab
    String getAppTitle() {
      switch (currentIndex) {
        case 0:
          return "Dashboard Overview";
        case 1:
          return "My Products";
        case 2:
          return "Manage Stores";
        case 3:
          return "Finance & Wallet";
        case 4:
          return "Reports";
        case 5:
          return "Add New Product"; // ✅ Naya Title
        case 6:
          return "Orders";
        case 7:
          return "Sell Requests";
        default:
          return "Vendor Panel";
      }
    }

    // Screens Array (Must match the Drawer Index exactly)
    final List<Widget> screens = [
      HomeTab(
        // HomeTab k andar "Quick Actions" se navigate karne k liye callback
        onNavigateToTab: (index) {
          ref.read(dashboardNavProvider.notifier).state = index;
        },
      ), // Index 0
      const ProductsTab(), // Index 1
      const StoresTab(), // Index 2
      const FinanceTab(), // Index 3
      const ReportsTab(), // Index 4
      // ✅ Yahan hamari asli Add Product Screen aayegi
      const VendorAddProductScreen(), // Index 5

      const OrdersTab(), // Index 6
      const SellRequestsTab(), // Index 7
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: Text(
          getAppTitle(),
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            // Default check if index goes out of bounds
            child: currentIndex >= 0 && currentIndex < screens.length
                ? screens[currentIndex]
                : const HomeTab(),
          ),
        ),
      ),
    );
  }
}
