import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/vendor_finance_controller.dart';

class VendorFinanceScreen extends StatelessWidget {
  const VendorFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorFinanceController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
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

              // ✅ FIX: Chart Removed completely from here!
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
                        // ✅ FIX: Only Date will show, No Time (12:00 AM Issue Fixed)
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
                        trailing: Text(
                          "${item.isPayment ? '+' : '-'} PKR ${item.amount.toStringAsFixed(0)}",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: item.isPayment
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
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
