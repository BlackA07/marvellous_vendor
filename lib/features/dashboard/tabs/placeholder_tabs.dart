import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ NAYE IMPORTS
import '../../orders/presentation/screens/vendor_order_requests_screen.dart';
import '../../orders/presentation/screens/vendor_orders_screen.dart';
import '../../products/views/vendor_my_products_screen.dart';
import '../../finance/presentation/screens/vendor_finance_screen.dart';
// ✅ Dashboard ViewModel Import (Back Navigation handle karne ke liye)
import '../../reports/vendor_report_screen.dart';
import '../viewmodels/dashboard_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Index Map (dashboardNavProvider state values):
//   0 = Dashboard (HomeTab)
//   1 = My Products ✅ (Connected)
//   2 = Manage Stores
//   3 = Finance & Wallet ✅ (Connected)
//   4 = Reports
//   5 = Add New Product
//   6 = Bills & Orders ✅ (Connected)
//   7 = Sell Requests ✅ (NOW CONNECTED)
// ─────────────────────────────────────────────────────────────────────────────

// ── Products Tab ─────────────────────────────────────────────────────────────
class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const VendorMyProductsScreen();
  }
}

// ── Stores Tab ────────────────────────────────────────────────────────────────
class StoresTab extends StatelessWidget {
  const StoresTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _comingSoon(
      "Manage Stores",
      Icons.store_rounded,
      Colors.purpleAccent,
    );
  }
}

// ── Finance Tab ───────────────────────────────────────────────
class FinanceTab extends StatelessWidget {
  const FinanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const VendorFinanceScreen();
  }
}

// ── Reports Tab ───────────────────────────────────────────────────────────────
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const VendorReportScreen();
  }
}

// ── Add New Product Tab ───────────────────────────────────────────────────────
class AddProductTab extends StatelessWidget {
  const AddProductTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _comingSoon(
      "Add New Product",
      Icons.add_box_rounded,
      Colors.greenAccent,
    );
  }
}

// ── Orders Tab ───────────────────────────────────────────────────────────────
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const VendorOrdersScreen();
  }
}

// ── Sell Requests Tab (NOW CONNECTED WITH BACK NAVIGATION) ────────────────────
class SellRequestsTab extends ConsumerWidget {
  const SellRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ WillPopScope: App ko close hone se rokega aur wapas HomeTab (Index 0) pe le jayega
    return WillPopScope(
      onWillPop: () async {
        ref.read(dashboardNavProvider.notifier).state = 0;
        return false; // False ka matlab default back behaviour (app close) rok do
      },
      child: const VendorOrderRequestsScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared "Coming Soon" Widget
// ─────────────────────────────────────────────────────────────────────────────
Widget _comingSoon(String title, IconData icon, Color color) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 52),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Coming Soon",
          style: GoogleFonts.comicNeue(
            color: Colors.white38,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
