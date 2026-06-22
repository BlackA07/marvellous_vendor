import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/viewmodels/dashboard_viewmodel.dart';
import '../../controllers/vendor_order_request_controller.dart';
import '../../models/order_request_model.dart';

class VendorOrderRequestsScreen extends ConsumerWidget {
  const VendorOrderRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = Get.put(VendorOrderRequestController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // ✅ FIX: Get.back() se ye theek tarah HomeTab ya pichli screen par chala jayega
            Get.back();
          },
        ),
        title: Text(
          "Admin Order Requests",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.orderRequests.isEmpty) {
          return Center(
            child: Text(
              "No order requests from Admin yet.",
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          itemCount: controller.orderRequests.length,
          itemBuilder: (context, index) {
            OrderRequestModel request = controller.orderRequests[index];
            return _buildRequestCard(context, request, controller);
          },
        );
      }),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    OrderRequestModel request,
    VendorOrderRequestController controller,
  ) {
    Color statusColor = Colors.orange.shade800; // Pending
    if (request.status == 'confirmed') statusColor = Colors.blue.shade800;
    if (request.status == 'shipped') statusColor = Colors.purple.shade800;
    if (request.status == 'rejected') statusColor = Colors.red.shade900;
    if (request.status == 'completed') statusColor = Colors.green.shade900;
    if (request.status == 'hold') statusColor = Colors.amber.shade900;

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: ExpansionTile(
        shape: const Border(),
        initiallyExpanded: request.status == 'pending',
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Request from Admin",
                style: GoogleFonts.comicNeue(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Text(
                request.status.toUpperCase(),
                style: GoogleFonts.comicNeue(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt)}\nTotal Items: ${request.items.length}",
            style: GoogleFonts.comicNeue(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        children: [
          const Divider(color: Colors.black12, thickness: 1.5),

          // ── ITEMS LIST ──
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: request.items.length,
            itemBuilder: (ctx, i) {
              var item = request.items[i];
              bool isAvail = item['isAvailable'] ?? true;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isAvail ? Colors.transparent : Colors.red.shade50,
                  border: const Border(
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item['productName']}",
                            style: GoogleFonts.comicNeue(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isAvail
                                  ? Colors.black
                                  : Colors.red.shade900,
                            ),
                          ),
                          // ✅ Company name
                          if ((item['brand'] ?? '').toString().isNotEmpty)
                            Text(
                              item['brand'],
                              style: GoogleFonts.comicNeue(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          // ✅ FIX: Added Purchase Price here!
                          Text(
                            "Qty Required: ${item['requestQty']}  |  Price: PKR ${item['purchasePrice'] ?? 0}  |  Model: ${item['model']}",
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          // ✅ RAM / ROM
                          if ((item['ram'] ?? '').toString().isNotEmpty ||
                              (item['storage'] ?? '').toString().isNotEmpty)
                            Text(
                              [
                                if ((item['ram'] ?? '').toString().isNotEmpty)
                                  'RAM: ${item['ram']}',
                                if ((item['storage'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  'ROM: ${item['storage']}',
                              ].join('  |  '),
                              style: GoogleFonts.comicNeue(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (request.status == 'pending')
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              isAvail ? "Available" : "Not Avail.",
                              style: GoogleFonts.comicNeue(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isAvail
                                    ? Colors.green.shade800
                                    : Colors.red.shade900,
                              ),
                            ),
                            Switch(
                              value: isAvail,
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              onChanged: (val) {
                                controller.toggleItemAvailability(
                                  request.id!,
                                  request.items,
                                  i,
                                  val,
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        isAvail ? "Available" : "Not Available",
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isAvail
                              ? Colors.green.shade800
                              : Colors.red.shade900,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // ── ACTION BUTTONS ──
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                if (request.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.red.shade900,
                              width: 1.5,
                            ),
                          ),
                          icon: Icon(
                            Icons.close,
                            color: Colors.red.shade900,
                            size: 18,
                          ),
                          label: Text(
                            "REJECT",
                            style: GoogleFonts.comicNeue(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () => _showRejectDialog(
                            context,
                            request.id!,
                            controller,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.amber.shade900,
                              width: 1.5,
                            ),
                          ),
                          icon: Icon(
                            Icons.pause_circle_filled_rounded,
                            color: Colors.amber.shade900,
                            size: 18,
                          ),
                          label: Text(
                            "HOLD",
                            style: GoogleFonts.comicNeue(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () =>
                              _showHoldDialog(context, request.id!, controller),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            "CONFIRM",
                            style: GoogleFonts.comicNeue(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () {
                            bool allUnavailable = request.items.every(
                              (item) => (item['isAvailable'] ?? true) == false,
                            );

                            if (allUnavailable) {
                              _confirmActionDialog(
                                "Auto Reject",
                                "All items are marked as Not Available. This order will be rejected automatically. Proceed?",
                                () {
                                  controller.updateOrderStatus(
                                    request.id!,
                                    'rejected',
                                    rejectReason:
                                        "All products were marked as Not Available.",
                                  );
                                },
                              );
                            } else {
                              _confirmActionDialog(
                                "Confirm Bill",
                                "Confirm this bill? Ensure you marked unavailable items correctly.",
                                () {
                                  controller.updateOrderStatus(
                                    request.id!,
                                    'confirmed',
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                if (request.status == 'confirmed')
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                      ),
                      icon: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                      ),
                      label: Text(
                        "MARK AS SHIPPED",
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: () => _confirmActionDialog(
                        "Mark Shipped",
                        "Have you shipped the available items to the Admin?",
                        () {
                          controller.updateOrderStatus(request.id!, 'shipped');
                        },
                      ),
                    ),
                  ),

                if (request.status == 'shipped' ||
                    request.status == 'completed')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade900),
                    ),
                    child: Center(
                      child: Text(
                        request.status == 'shipped'
                            ? "Waiting for Admin to receive and generate final bill."
                            : "Order Completed & Billed by Admin.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.comicNeue(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NAYA: Reject karne k liye Dialog jo reason mangay ga
  void _showRejectDialog(
    BuildContext context,
    String requestId,
    VendorOrderRequestController controller,
  ) {
    TextEditingController reasonCtrl = TextEditingController();
    Get.defaultDialog(
      title: "Reject Order",
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        fontSize: 24,
        color: Colors.black,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            Text(
              "Please provide a reason for rejection:",
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Out of stock, unavailable etc...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text(
          "Cancel",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
        onPressed: () {
          if (reasonCtrl.text.trim().isEmpty) {
            Get.snackbar(
              "Required",
              "Please enter a reason",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }
          Get.back(); // close dialog
          controller.updateOrderStatus(
            requestId,
            'rejected',
            rejectReason: reasonCtrl.text.trim(),
          );
        },
        child: const Text(
          "Reject",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _confirmActionDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    Get.defaultDialog(
      title: title,
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        fontSize: 24,
        color: Colors.black,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text(
          "Cancel",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
        onPressed: () {
          Get.back(); // Close Dialog
          onConfirm();
        },
        child: const Text(
          "Yes, Proceed",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ✅ NEW METHOD: Hold Status Input Dialog
  void _showHoldDialog(
    BuildContext context,
    String requestId,
    VendorOrderRequestController controller,
  ) {
    TextEditingController reasonCtrl = TextEditingController();
    Get.defaultDialog(
      title: "Hold Order Request",
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        fontSize: 22,
        color: Colors.black,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            Text(
              "Provide a reason to put this order on hold:",
              style: GoogleFonts.comicNeue(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText:
                    "E.g., Please adjust the product purchase price, it's lower than current rates...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text(
          "Cancel",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
        onPressed: () {
          if (reasonCtrl.text.trim().isEmpty) {
            Get.snackbar(
              "Reason Required",
              "Please enter a reason to put on hold.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }
          Get.back(); // close dialog
          controller.updateOrderStatus(
            requestId,
            'hold',
            holdReason: reasonCtrl.text.trim(),
          );
        },
        child: const Text(
          "Send Hold Reason",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
