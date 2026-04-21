import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ NAYE IMPORTS: Teeno screens yahan import karni hain
import '../../orders/presentation/screens/vendor_orders_screen.dart';
import '../../products/views/vendor_my_products_screen.dart';
import '../../finance/presentation/screens/vendor_finance_screen.dart'; // ✅ Added Finance Screen Import

// ─────────────────────────────────────────────────────────────────────────────
// Index Map (dashboardNavProvider state values):
//   0 = Dashboard (HomeTab)
//   1 = My Products ✅ (Connected)
//   2 = Manage Stores
//   3 = Finance & Wallet ✅ (Now Connected)
//   4 = Reports
//   5 = Add New Product
//   6 = Bills & Orders ✅ (Connected)
//   7 = Sell Requests
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

// ── Finance Tab (NOW CONNECTED) ───────────────────────────────────────────────
class FinanceTab extends StatelessWidget {
  const FinanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Ab yahan vendor ka mukammal Finance aur Ledger dashboard khulay ga!
    return const VendorFinanceScreen();
  }
}

// ── Reports Tab ───────────────────────────────────────────────────────────────
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _comingSoon("Reports", Icons.bar_chart_rounded, Colors.amberAccent);
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

// ── Sell Requests Tab ─────────────────────────────────────────────────────────
class SellRequestsTab extends StatelessWidget {
  const SellRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _comingSoon(
      "Sell Requests",
      Icons.request_page_rounded,
      Colors.pinkAccent,
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
