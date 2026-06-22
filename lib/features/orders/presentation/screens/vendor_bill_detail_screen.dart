import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/vendor_order_model.dart';
import '../../controllers/vendor_orders_controller.dart';
import '../../repository/vendor_orders_repository.dart';

class VendorBillDetailScreen extends StatelessWidget {
  final VendorOrderModel order;
  const VendorBillDetailScreen({super.key, required this.order});

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
  Widget build(BuildContext context) {
    final controller = Get.find<VendorOrdersController>();
    final repo = VendorOrdersRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "Bill Details: ${order.billNumber}",
          style: GoogleFonts.comicNeue(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BILL SUMMARY CARD
            _buildSectionCard(
              title: "Bill Summary",
              icon: Icons.receipt_long,
              content: Column(
                children: [
                  _detailRow(
                    "Date Generated:",
                    DateFormat('dd MMMM yyyy, hh:mm a').format(order.date),
                  ),
                  _detailRow("Payment Mode:", order.paymentMode),
                  if (order.paymentMode == "Credit" ||
                      order.paymentMode == "Both")
                    _detailRow("Credit Type:", order.creditType),
                  const Divider(color: Colors.black26),
                  _detailRow(
                    "Total Bill Amount:",
                    "PKR ${order.totalBillAmount.toStringAsFixed(0)}",
                    isBold: true,
                    color: Colors.black,
                  ),
                  _detailRow(
                    "Total Received:",
                    "PKR ${order.cashPaid.toStringAsFixed(0)}",
                    isBold: true,
                    color: Colors.green.shade800,
                  ),
                  _detailRow(
                    "Pending Receivable:",
                    "PKR ${order.remainingBalance.toStringAsFixed(0)}",
                    isBold: true,
                    color: Colors.red.shade800,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 2. PRODUCTS ORDERED
            _buildSectionCard(
              title: "Products Ordered",
              icon: Icons.inventory_2_outlined,
              content: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.black12),
                itemBuilder: (context, index) {
                  var item = order.items[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${item['quantity']}x",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${item['productName']} (${item['model'] ?? ''})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Unit: PKR ${item['unitPrice']}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "PKR ${item['totalItemPrice']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            // 3. INSTALLMENT SCHEDULE (DUES)
            if (order.paymentMode == "Credit" ||
                order.paymentMode == "Both") ...[
              _sectionHeader(
                "Upcoming Installments (Dues)",
                Icons.calendar_month,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: repo.getVendorDuesStream(order.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Text(
                      "No schedule found.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );

                  var dues = snapshot.data!.docs.toList();
                  dues.sort(
                    (a, b) => controller
                        .parseDate((a.data() as Map)['dueDate'])
                        .compareTo(
                          controller.parseDate((b.data() as Map)['dueDate']),
                        ),
                  );

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade100,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              "Date",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Due Amount",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Received",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Status",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: dues.map((doc) {
                          var d = doc.data() as Map<String, dynamic>;
                          DateTime dDate = controller.parseDate(d['dueDate']);
                          double original =
                              (d['originalAmountDue'] ?? d['amountDue'] ?? 0.0)
                                  .toDouble();
                          double paid = (d['paidAmount'] ?? 0.0).toDouble();
                          bool isPaid = d['isPaid'] == true;

                          Color statusColor = isPaid
                              ? Colors.green
                              : (original <= 0
                                    ? Colors.green
                                    : Colors.orange.shade800);
                          String statusText = isPaid
                              ? "RECEIVED"
                              : (original <= 0 ? "ADVANCE" : "PENDING");

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  DateFormat('dd MMM yy').format(dDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  original <= 0
                                      ? "-"
                                      : "PKR ${original.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  paid > 0
                                      ? "PKR ${paid.toStringAsFixed(0)}"
                                      : "-",
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                // ✅ NEW: Icon added before Status text specifically if Paid > 0
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (paid > 0) ...[
                                      Icon(
                                        Icons.image,
                                        size: 16,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
            ],

            // 4. PAYMENT RECEIPTS HISTORY
            _sectionHeader(
              "Payment Receipts from Admin",
              Icons.payments_rounded,
            ),
            StreamBuilder<QuerySnapshot>(
              stream: repo.getVendorPaymentHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Text(
                    "No payments received yet.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );

                // Filter payments specifically for THIS bill
                var billPayments = snapshot.data!.docs.where((doc) {
                  return (doc.data() as Map)['billNumber'] == order.billNumber;
                }).toList();

                if (billPayments.isEmpty)
                  return const Text(
                    "No payments received for this bill yet.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  );

                billPayments.sort(
                  (a, b) => controller
                      .parseDate((b.data() as Map)['paymentDate'])
                      .compareTo(
                        controller.parseDate((a.data() as Map)['paymentDate']),
                      ),
                );

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: billPayments.length,
                  itemBuilder: (context, index) {
                    var pay =
                        billPayments[index].data() as Map<String, dynamic>;
                    DateTime payDate = controller.parseDate(pay['paymentDate']);
                    double amt = (pay['paidAmount'] ?? 0.0).toDouble();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Received via ${pay['paymentMode']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(payDate),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "+ PKR ${amt.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green.shade900,
                                  fontSize: 16,
                                ),
                              ),
                              // ✅ NEW: Actual View Screenshot Button inside Receipts Section
                              if (pay['screenshot'] != null &&
                                  pay['screenshot'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _showScreenshot(
                                    context,
                                    pay['screenshot'],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
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
                                            fontSize: 12,
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
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigo, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.black12, height: 20, thickness: 1),
          content,
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: color ?? Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
