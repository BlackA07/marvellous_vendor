import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../dashboard/viewmodels/dashboard_viewmodel.dart';
import '../../../dashboard/views/dashboard_screen.dart';
import '../../controllers/vendor_finance_controller.dart';

class VendorFinanceScreen extends ConsumerWidget {
  const VendorFinanceScreen({super.key});

  // ✅ NEW: Dialog to show Screenshot Image
  void _showScreenshot(BuildContext context, String imageString) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageString.startsWith('http')
                  ? Image.network(imageString, fit: BoxFit.contain)
                  : Image.memory(
                      base64Decode(imageString),
                      fit: BoxFit.contain,
                    ),
            ),
            Positioned(
              top: -10,
              right: -10,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red, size: 35),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = Get.put(VendorFinanceController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Dashbaord tab ko 0 index (Home) pe le jayega
            ref.read(dashboardNavProvider.notifier).state = 0;
            Get.back();
          },
        ),
        title: Text(
          "Accounting & Ledger",
          style: GoogleFonts.comicNeue(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.ledgerHistory.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── MAIN DARK STAT CARDS ──
              _darkStatCard(
                "To Be Received (Pending)",
                "PKR ${controller.totalAmountPending.value.toStringAsFixed(0)}",
                Icons.account_balance_wallet_rounded,
                Colors.orangeAccent,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _darkStatCard(
                      "Total Billed",
                      "PKR ${controller.totalBilledAmount.value.toStringAsFixed(0)}",
                      Icons.receipt_long_rounded,
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _darkStatCard(
                      "Total Received",
                      "PKR ${controller.totalReceivedAmount.value.toStringAsFixed(0)}",
                      Icons.download_done_rounded,
                      Colors.greenAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ── Ledger History List ──
              Text(
                "Ledger History",
                style: GoogleFonts.comicNeue(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),

              if (controller.ledgerHistory.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text("No transactions found."),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.ledgerHistory.length,
                  itemBuilder: (context, index) {
                    var item = controller.ledgerHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.isPayment
                                ? Colors.green.shade50
                                : Colors.indigo.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isPayment
                                ? Icons.download_rounded
                                : Icons.receipt_long,
                            color: item.isPayment
                                ? Colors.green.shade700
                                : Colors.indigo.shade700,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${item.subtitle}\n${DateFormat('dd MMM yyyy').format(item.date)}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize
                              .min, // ✅ Important for ListTile trailing
                          children: [
                            Text(
                              "${item.isPayment ? '+' : '-'} PKR ${item.amount.toStringAsFixed(0)}",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: item.isPayment
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                            // ✅ NEW: Show Pending Status for Uncleared Cheques
                            if (item.paymentMode == 'Cheque' && !item.isCleared)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Pending Clearance",
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            // ✅ NEW: Show Screenshot option if Payment has a proof attached
                            if (item.isPayment &&
                                item.screenshot != null &&
                                item.screenshot!.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () =>
                                    _showScreenshot(context, item.screenshot!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 14,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "View Proof",
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  // Helper Widget for Dark Cards
  Widget _darkStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF212121), // Dark Theme
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
