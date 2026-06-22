import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/vendor_notifications_controller.dart';

class VendorNotificationsScreen extends StatelessWidget {
  const VendorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorNotificationsController());

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        title: Text(
          "Notifications",
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✅ Read All button
          Obx(() {
            final hasUnread = controller.notifications.any((n) => !n.isRead);
            if (!hasUnread) return const SizedBox();
            return TextButton.icon(
              onPressed: controller.markAllAsRead,
              icon: const Icon(
                Icons.done_all,
                color: Colors.cyanAccent,
                size: 18,
              ),
              label: Text(
                "Read All",
                style: GoogleFonts.comicNeue(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_off_outlined,
                  size: 60,
                  color: Colors.white24,
                ),
                const SizedBox(height: 12),
                Text(
                  "No notifications yet.",
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

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];
            return _NotifCard(notif: notif, controller: controller);
          },
        );
      }),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationItem notif;
  final VendorNotificationsController controller;

  const _NotifCard({required this.notif, required this.controller});

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_product':
        return Icons.shopping_bag_outlined;
      case 'package_updated':
      case 'new_package':
        return Icons.inventory_2_outlined;
      case 'product_updated':
        return Icons.edit_outlined;
      case 'order_status':
        return Icons.receipt_long_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'new_product':
        return Colors.cyanAccent;
      case 'new_package':
        return Colors.blueAccent;
      case 'product_updated':
      case 'package_updated':
        return Colors.orangeAccent;
      case 'order_status':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  void _showDetail(BuildContext context) {
    controller.markAsRead(notif.id);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon + Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _colorForType(notif.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForType(notif.type),
                      color: _colorForType(notif.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      notif.title,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(notif.date),
                style: GoogleFonts.comicNeue(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Body
              Text(
                notif.body,
                style: GoogleFonts.comicNeue(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Data fields (clean format)
              if (notif.data.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                ...notif.data.entries.map((e) {
                  if (e.key == 'productImage' || e.value == null) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_formatKey(e.key)}: ",
                          style: GoogleFonts.comicNeue(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value.toString(),
                            style: GoogleFonts.comicNeue(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009FFD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: Text(
                    "Close",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .trim()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? const Color(0xFF2A2A2A)
              : const Color(0xFF1E2D3D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? Colors.white10
                : _colorForType(notif.type).withOpacity(0.5),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _colorForType(notif.type).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForType(notif.type),
                color: _colorForType(notif.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: notif.isRead
                          ? FontWeight.bold
                          : FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: GoogleFonts.comicNeue(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(notif.date),
                    style: GoogleFonts.comicNeue(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!notif.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: _colorForType(notif.type),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
