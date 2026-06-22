import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../tabs/home_tab.dart';
import '../tabs/placeholder_tabs.dart';
import '../../products/views/add_product_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(dashboardNavProvider);

    // Dynamic Title based on selected tab index
    String getAppTitle() {
      switch (currentIndex) {
        case 0:
          return "Dashboard Overview";
        case 1:
          return "My Products";
        case 2:
          return "Finance & Wallet";
        case 3:
          return "Reports";
        case 4:
          return "Add New Product";
        case 5:
          return "Orders";
        case 6:
          return "Sell Requests";
        default:
          return "Vendor Panel";
      }
    }

    // Screens Array mapping
    final List<Widget> screens = [
      HomeTab(
        onNavigateToTab: (index) =>
            ref.read(dashboardNavProvider.notifier).state = index,
      ), // 0: Home
      const ProductsTab(), // 1: My Products
      const FinanceTab(), // 2: Finance
      const ReportsTab(), // 3: Reports
      const VendorAddProductScreen(), // 4: Add Product
      const OrdersTab(), // 5: Orders
      const SellRequestsTab(), // 6: Sell Requests
    ];

    return WillPopScope(
      onWillPop: () async {
        // Agar dashboard par nahi hain, to back dabane par dashboard pe le jao
        if (currentIndex != 0) {
          ref.read(dashboardNavProvider.notifier).state = 0;
          return false; // App band nahi hogi
        }
        return true; // Dashboard par hain to app band ho sakti hai
      },
      child: Scaffold(
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
              child: currentIndex >= 0 && currentIndex < screens.length
                  ? screens[currentIndex]
                  : const HomeTab(),
            ),
          ),
        ),
      ),
    );
  }
}
