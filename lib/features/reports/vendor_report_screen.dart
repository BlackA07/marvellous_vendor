// vendor_report_screen.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'vendor_report_controller.dart';
import 'vendor_report_model.dart';

class VendorReportScreen extends StatelessWidget {
  const VendorReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorReportController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'My Report',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh',
              onPressed: controller.isLoading.value ? null : controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          );
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final v = controller.vendorData.value;
        if (v == null) {
          return Center(
            child: Text(
              'No data found.',
              style: GoogleFonts.nunito(color: const Color(0xFF94A3B8)),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vendor Info Card ──
              _VendorInfoCard(vendor: v),
              const SizedBox(height: 16),

              // ── Finance Summary ──
              _SectionTitle('Finance Summary'),
              const SizedBox(height: 8),
              _FinanceRow(vendor: v),
              const SizedBox(height: 12),

              // ── Payment Breakdown ──
              _SectionTitle('Payment Breakdown'),
              const SizedBox(height: 8),
              _PaymentBreakdownCard(vendor: v),
              const SizedBox(height: 16),

              // ── Recent Bills ──
              if (v.recentBills.isNotEmpty) ...[
                _SectionTitle('Bills History (${v.totalBills})'),
                const SizedBox(height: 8),
                _RecentBillsCard(
                  bills: v.recentBills,
                  totalBills: v.totalBills,
                  avgBill: v.avgBillAmount,
                ),
                const SizedBox(height: 16),
              ],

              // ── Recent Payments ──
              if (v.recentPayments.isNotEmpty) ...[
                _SectionTitle('Payments History (${v.recentPayments.length})'),
                const SizedBox(height: 8),
                _RecentPaymentsCard(payments: v.recentPayments),
                const SizedBox(height: 16),
              ],

              // ── Products Summary ──
              _SectionTitle('Products Overview'),
              const SizedBox(height: 8),
              _ProductsOverviewCard(vendor: v),
              const SizedBox(height: 16),

              // ── Live Products List ──
              if (v.liveProductsList.isNotEmpty) ...[
                _SectionTitle('Live Products (${v.totalLiveProducts})'),
                const SizedBox(height: 8),
                _ProductsListCard(products: v.liveProductsList, isLive: true),
                const SizedBox(height: 16),
              ],

              // ── Pending Products List ──
              if (v.pendingProductsList.isNotEmpty) ...[
                _SectionTitle('Pending / Hold Products'),
                const SizedBox(height: 8),
                _ProductsListCard(
                  products: v.pendingProductsList,
                  isLive: false,
                ),
                const SizedBox(height: 16),
              ],

              // ── Order Requests ──
              _SectionTitle('Order Requests'),
              const SizedBox(height: 8),
              _OrderStatsCard(vendor: v),
              const SizedBox(height: 30),

              // ── Export Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.ios_share, color: Colors.white),
                  label: Text(
                    'Export My Report',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () => _showExportSheet(context, controller),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  void _showExportSheet(
    BuildContext context,
    VendorReportController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExportSheet(controller: controller),
    );
  }
}

// ── Section Title ──
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Vendor Info Card ──
class _VendorInfoCard extends StatelessWidget {
  final VendorReportModel vendor;
  const _VendorInfoCard({required this.vendor});

  Color get _statusColor {
    switch (vendor.status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFD97706);
      case 'hold':
        return const Color(0xFF9333EA);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.storeName.isNotEmpty
                          ? vendor.storeName
                          : 'My Store',
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      vendor.ownerName,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  vendor.status.toUpperCase(),
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          if (vendor.phone.isNotEmpty)
            _InfoRow(Icons.store_outlined, 'Store Phone', vendor.phone),
          if (vendor.ownerMobile.isNotEmpty)
            _InfoRow(Icons.phone_outlined, 'Owner Mobile', vendor.ownerMobile),
          if (vendor.contactPersonName.isNotEmpty)
            _InfoRow(
              Icons.support_agent_outlined,
              'Contact Person',
              vendor.contactPersonName,
            ),
          if (vendor.contactPersonPhone.isNotEmpty)
            _InfoRow(
              Icons.phone_in_talk_outlined,
              'Contact Phone',
              vendor.contactPersonPhone,
            ),
          if (vendor.email.isNotEmpty)
            _InfoRow(Icons.email_outlined, 'Email', vendor.email),
          if (vendor.address.isNotEmpty)
            _InfoRow(Icons.location_on_outlined, 'Address', vendor.address),
          if (vendor.categories.isNotEmpty)
            _InfoRow(
              Icons.category_outlined,
              'Categories',
              vendor.categories.join(', '),
            ),
          if (vendor.subCategories.isNotEmpty)
            _InfoRow(
              Icons.subdirectory_arrow_right_outlined,
              'Sub-Categories',
              vendor.subCategories.join(', '),
            ),
          if (vendor.createdAt != null)
            _InfoRow(
              Icons.calendar_today_outlined,
              'Joined',
              DateFormat('dd MMM yyyy').format(vendor.createdAt!),
            ),
          if (vendor.beginningBalance > 0)
            _InfoRow(
              Icons.account_balance_wallet_outlined,
              'Beginning Balance',
              'Rs. ${vendor.beginningBalance.toStringAsFixed(0)}',
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _InfoRow(this.icon, this.label, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Finance Row ──
class _FinanceRow extends StatelessWidget {
  final VendorReportModel vendor;
  const _FinanceRow({required this.vendor});

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs.${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'Rs.${(v / 1000).toStringAsFixed(1)}K';
    return 'Rs.${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Billed',
            value: _fmt(vendor.totalBilled),
            icon: Icons.receipt_outlined,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Received',
            value: _fmt(vendor.totalReceived),
            icon: Icons.payments_outlined,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: _fmt(vendor.totalPending),
            icon: Icons.pending_actions_outlined,
            color: vendor.totalPending > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

// ── Payment Breakdown ──
class _PaymentBreakdownCard extends StatelessWidget {
  final VendorReportModel vendor;
  const _PaymentBreakdownCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _PRow(
            label: 'Cash Received',
            value: vendor.cashReceived,
            color: Colors.green.shade700,
          ),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          _PRow(
            label: 'Cheque Total',
            value: vendor.chequeReceived,
            color: Colors.blue.shade700,
          ),
          _PRow(
            label: '  ↳ Cleared',
            value: vendor.chequeCleared,
            color: Colors.teal.shade600,
          ),
          _PRow(
            label: '  ↳ Pending Clearance',
            value: vendor.chequePending,
            color: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }
}

class _PRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _PRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Bills Card (Full List) ──
class _RecentBillsCard extends StatelessWidget {
  final List<Map<String, dynamic>> bills;
  final int totalBills;
  final double avgBill;
  const _RecentBillsCard({
    required this.bills,
    required this.totalBills,
    required this.avgBill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Bills: $totalBills',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Avg: Rs. ${avgBill.toStringAsFixed(0)}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          // Added ListView for better performance with large data
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bills.length,
            itemBuilder: (context, index) => _BillRow(bill: bills[index]),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _BillRow({required this.bill});

  @override
  Widget build(BuildContext context) {
    final remaining = bill['remaining'] as double;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill #${bill['billNumber']}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(bill['date'] as DateTime),
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${(bill['amount'] as double).toStringAsFixed(0)}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (remaining > 0)
                Text(
                  'Rem: Rs. ${remaining.toStringAsFixed(0)}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  'Cleared',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent Payments Card (Full List) ──
class _RecentPaymentsCard extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  const _RecentPaymentsCard({required this.payments});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final p = payments[index];
          final bool isCleared = p['isCleared'] as bool;
          final String mode = p['mode'] as String;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Via $mode',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (mode.toLowerCase() == 'cheque' &&
                          (p['chequeNumber'] as String).isNotEmpty)
                        Text(
                          'Cheque #${p['chequeNumber']}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      Text(
                        DateFormat('dd MMM yyyy').format(p['date'] as DateTime),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${(p['amount'] as double).toStringAsFixed(0)}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (mode.toLowerCase() == 'cheque')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCleared
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCleared
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Text(
                          isCleared ? 'Cleared' : 'Pending',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCleared
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Products Overview ──
class _ProductsOverviewCard extends StatelessWidget {
  final VendorReportModel vendor;
  const _ProductsOverviewCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Live',
                value: '${vendor.totalLiveProducts}',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${vendor.totalPendingProducts}',
                icon: Icons.hourglass_top_outlined,
                color: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Hold',
                value: '${vendor.totalHoldProducts}',
                icon: Icons.pause_circle_outline,
                color: const Color(0xFF9333EA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _StatCard(
          label: 'Rejected Requests',
          value: '${vendor.totalRejectedProducts}',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

// ── Products List Card (Full List) ──
class _ProductsListCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isLive;
  const _ProductsListCard({required this.products, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name']?.toString() ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        p['category']?.toString() ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      if (!isLive &&
                          (p['holdReason']?.toString() ?? '').isNotEmpty)
                        Text(
                          'Hold: ${p['holdReason']}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isLive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${(p['salePrice'] as double).toStringAsFixed(0)}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        'Brand: ${p['brand']}',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p['status'] == 'hold'
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (p['status']?.toString() ?? '').toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: p['status'] == 'hold'
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Order Stats Card ──
class _OrderStatsCard extends StatelessWidget {
  final VendorReportModel vendor;
  const _OrderStatsCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: '${vendor.totalOrderRequests}',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Completed',
                value: '${vendor.completedOrders}',
                icon: Icons.done_all_rounded,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${vendor.pendingOrders}',
                icon: Icons.pending_outlined,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Confirmed',
                value: '${vendor.confirmedOrders}',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF0891B2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Shipped',
                value: '${vendor.shippedOrders}',
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Rejected',
                value: '${vendor.rejectedOrders}',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Export Sheet ──
class _ExportSheet extends StatefulWidget {
  final VendorReportController controller;
  const _ExportSheet({required this.controller});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _isWorking = false;
  String _status = '';
  bool _isError = false;
  String? _lastPath;

  // New features: Section toggles
  bool _incVendorInfo = true;
  bool _incFinance = true;
  bool _incProductsSummary = true;
  bool _incProductsList = false; // Default false to avoid huge PDFs initially
  bool _incOrders = true;
  bool _incBills = true;
  bool _incPayments = true;

  void _setStatus(String msg, {bool error = false}) => setState(() {
    _status = msg;
    _isError = error;
  });

  Future<Uint8List> _buildPdf() async {
    final v = widget.controller.vendorData.value!;
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final now = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

    final headerBg = const PdfColor.fromInt(0xFF2563EB);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) {
          List<pw.Widget> elements = [];

          // HEADER
          elements.addAll([
            pw.Text(
              'My Vendor Report',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 20,
                color: const PdfColor.fromInt(0xFF1E3A5F),
              ),
            ),
            pw.Text(
              'Generated: $now',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1.5, color: headerBg),
            pw.SizedBox(height: 14),
          ]);

          // VENDOR INFO
          if (_incVendorInfo) {
            elements.addAll([
              _pdfSection(fontBold, 'Vendor Information'),
              _pdfRow(fontBold, font, 'Store Name', v.storeName),
              _pdfRow(fontBold, font, 'Owner', v.ownerName),
              _pdfRow(fontBold, font, 'Store Phone', v.phone),
              _pdfRow(fontBold, font, 'Owner Mobile', v.ownerMobile),
              if (v.contactPersonName.isNotEmpty)
                _pdfRow(fontBold, font, 'Contact Person', v.contactPersonName),
              _pdfRow(fontBold, font, 'Email', v.email),
              _pdfRow(fontBold, font, 'Address', v.address),
              _pdfRow(fontBold, font, 'Categories', v.categories.join(', ')),
              _pdfRow(fontBold, font, 'Status', v.status.toUpperCase()),
              if (v.createdAt != null)
                _pdfRow(
                  fontBold,
                  font,
                  'Joined',
                  DateFormat('dd MMM yyyy').format(v.createdAt!),
                ),
              pw.SizedBox(height: 14),
            ]);
          }

          // FINANCE
          if (_incFinance) {
            elements.addAll([
              _pdfSection(fontBold, 'Finance Summary'),
              _pdfRow(
                fontBold,
                font,
                'Total Billed',
                'Rs. ${v.totalBilled.toStringAsFixed(0)}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Total Received',
                'Rs. ${v.totalReceived.toStringAsFixed(0)}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Pending Amount',
                'Rs. ${v.totalPending.toStringAsFixed(0)}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Cash Received',
                'Rs. ${v.cashReceived.toStringAsFixed(0)}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Cheque Cleared',
                'Rs. ${v.chequeCleared.toStringAsFixed(0)}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Cheque Pending',
                'Rs. ${v.chequePending.toStringAsFixed(0)}',
              ),
              pw.SizedBox(height: 14),
            ]);
          }

          // PRODUCTS SUMMARY
          if (_incProductsSummary) {
            elements.addAll([
              _pdfSection(fontBold, 'Products Summary'),
              _pdfRow(
                fontBold,
                font,
                'Live Products',
                '${v.totalLiveProducts}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Pending Requests',
                '${v.totalPendingProducts}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Hold Requests',
                '${v.totalHoldProducts}',
              ),
              _pdfRow(
                fontBold,
                font,
                'Rejected Requests',
                '${v.totalRejectedProducts}',
              ),
              pw.SizedBox(height: 14),
            ]);
          }

          // ORDERS
          if (_incOrders) {
            elements.addAll([
              _pdfSection(fontBold, 'Order Requests'),
              _pdfRow(
                fontBold,
                font,
                'Total Orders',
                '${v.totalOrderRequests}',
              ),
              _pdfRow(fontBold, font, 'Completed', '${v.completedOrders}'),
              _pdfRow(fontBold, font, 'Confirmed', '${v.confirmedOrders}'),
              _pdfRow(fontBold, font, 'Shipped', '${v.shippedOrders}'),
              _pdfRow(fontBold, font, 'Pending', '${v.pendingOrders}'),
              _pdfRow(fontBold, font, 'Rejected', '${v.rejectedOrders}'),
              pw.SizedBox(height: 14),
            ]);
          }

          // PRODUCTS LIST (Table to prevent overflow)
          if (_incProductsList && v.liveProductsList.isNotEmpty) {
            elements.addAll([
              _pdfSection(fontBold, 'Live Products List'),
              pw.TableHelper.fromTextArray(
                context: ctx,
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: headerBg),
                data: <List<String>>[
                  ['Name', 'Brand', 'Category', 'Price', 'Stock'],
                  ...v.liveProductsList.map(
                    (p) => [
                      p['name'].toString(),
                      p['brand'].toString(),
                      p['category'].toString(),
                      'Rs. ${p['salePrice']}',
                      p['stockQuantity'].toString(),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
            ]);
          }

          // BILLS LIST
          if (_incBills && v.recentBills.isNotEmpty) {
            elements.addAll([
              _pdfSection(fontBold, 'Bills History'),
              pw.TableHelper.fromTextArray(
                context: ctx,
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: headerBg),
                data: <List<String>>[
                  ['Bill #', 'Date', 'Amount', 'Remaining'],
                  ...v.recentBills.map(
                    (b) => [
                      b['billNumber'].toString(),
                      DateFormat('dd MMM yyyy').format(b['date'] as DateTime),
                      'Rs. ${b['amount']}',
                      'Rs. ${b['remaining']}',
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
            ]);
          }

          // PAYMENTS LIST
          if (_incPayments && v.recentPayments.isNotEmpty) {
            elements.addAll([
              _pdfSection(fontBold, 'Payments History'),
              pw.TableHelper.fromTextArray(
                context: ctx,
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: headerBg),
                data: <List<String>>[
                  ['Mode', 'Date', 'Amount', 'Details'],
                  ...v.recentPayments.map((p) {
                    bool isCheque =
                        p['mode'].toString().toLowerCase() == 'cheque';
                    String details = isCheque
                        ? "Chq #${p['chequeNumber']} (${p['isCleared'] ? 'Cleared' : 'Pending'})"
                        : 'Cash';
                    return [
                      p['mode'].toString(),
                      DateFormat('dd MMM yyyy').format(p['date'] as DateTime),
                      'Rs. ${p['amount']}',
                      details,
                    ];
                  }),
                ],
              ),
            ]);
          }

          return elements;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfSection(pw.Font bold, String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: bold,
          fontSize: 13,
          color: const PdfColor.fromInt(0xFF2563EB),
        ),
      ),
    );
  }

  pw.Widget _pdfRow(pw.Font bold, pw.Font regular, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start, // Align to top
        children: [
          pw.SizedBox(
            width: 140, // Slightly reduced to give value more space
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
          // Wrapped in Expanded to prevent overflow
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: regular, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _isWorking = true);
    _setStatus('Generating PDF...');
    try {
      final bytes = await _buildPdf();
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/my_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(path).writeAsBytes(bytes);
      setState(() {
        _lastPath = path;
        _isWorking = false;
      });
      _setStatus('PDF saved!');
    } catch (e) {
      setState(() => _isWorking = false);
      _setStatus('Error: $e', error: true);
    }
  }

  Future<void> _print() async {
    setState(() => _isWorking = true);
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _setStatus('Error: $e', error: true);
    } finally {
      setState(() => _isWorking = false);
    }
  }

  Future<void> _share() async {
    if (_lastPath == null) await _exportPdf();
    if (_lastPath != null) await Share.shareXFiles([XFile(_lastPath!)]);
  }

  Widget _buildFilterChip(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: value ? Colors.white : const Color(0xFF475569),
          fontWeight: value ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      selected: value,
      onSelected: onChanged,
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2563EB),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: value ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Ensure safe area for bottom sheet and padding
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Export My Report',
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select sections to include in PDF:',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          // Section Selection Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                'Vendor Info',
                _incVendorInfo,
                (v) => setState(() => _incVendorInfo = v),
              ),
              _buildFilterChip(
                'Finance Summary',
                _incFinance,
                (v) => setState(() => _incFinance = v),
              ),
              _buildFilterChip(
                'Products Summary',
                _incProductsSummary,
                (v) => setState(() => _incProductsSummary = v),
              ),
              _buildFilterChip(
                'Orders Summary',
                _incOrders,
                (v) => setState(() => _incOrders = v),
              ),
              _buildFilterChip(
                'Bills History',
                _incBills,
                (v) => setState(() => _incBills = v),
              ),
              _buildFilterChip(
                'Payments History',
                _incPayments,
                (v) => setState(() => _incPayments = v),
              ),
              _buildFilterChip(
                'Full Products List',
                _incProductsList,
                (v) => setState(() => _incProductsList = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isWorking)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            ),
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Ye add kiya taake icon upar rahay
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 2,
                    ), // Icon thoda center theek karne ke liye
                    child: Icon(
                      _isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 15,
                      color: _isError
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    // <---- YAHAN EXPANDED ADD KIYA HAI OVERFLOW KHATAM KARNE KE LIYE
                    child: Text(
                      _status,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isError
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _Btn(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  subtitle: 'Save report',
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: _isWorking ? null : _exportPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Btn(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  subtitle: 'System print',
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: _isWorking ? null : _print,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Btn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  subtitle: _lastPath != null ? 'Ready' : 'Creates PDF',
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF3E8FF),
                  onTap: _isWorking ? null : _share,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  const _Btn({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
