import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/vendor_orders_controller.dart';
import 'vendor_bill_detail_screen.dart';

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorOrdersController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text(
            "My Orders & Payments",
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
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "PENDING RECEIPTS"),
              Tab(text: "COMPLETED"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.allOrders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          return Column(
            children: [
              // ── Summary Cards ──
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.black12, width: 2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statBox(
                            "Total Billed",
                            "PKR ${controller.totalSalesValue.value.toStringAsFixed(0)}",
                            Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statBox(
                            "Total Received",
                            "PKR ${controller.totalAmountReceived.value.toStringAsFixed(0)}",
                            Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Remaining Receivable:",
                            style: GoogleFonts.comicNeue(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                          Text(
                            "PKR ${controller.totalAmountPending.value.toStringAsFixed(0)}",
                            style: GoogleFonts.comicNeue(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Views ──
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOrderList(controller.pendingOrders, isPending: true),
                    _buildOrderList(
                      controller.completedOrders,
                      isPending: false,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _statBox(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.comicNeue(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List orders, {required bool isPending}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isPending ? "No pending payments." : "No completed orders.",
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        var order = orders[index];
        return GestureDetector(
          onTap: () => Get.to(() => VendorBillDetailScreen(order: order)),
          child: Card(
            color: Colors.white,
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: isPending
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Bill #: ${order.billNumber}",
                        style: GoogleFonts.comicNeue(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPending ? "PENDING" : "PAID",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isPending
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Date: ${DateFormat('dd MMM yyyy').format(order.date)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(height: 20, thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Bill",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            "PKR ${order.totalBillAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Pending Receivable",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            "PKR ${order.remainingBalance.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Tap to view full details & schedule",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
