import 'package:get/get.dart';
import 'vendor_report_model.dart';
import 'vendor_report_repository.dart';

class VendorReportController extends GetxController {
  final VendorReportRepository _repo = VendorReportRepository();

  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var vendorData = Rxn<VendorReportModel>();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading(true);
    errorMessage('');
    try {
      final data = await _repo.getMyReportData();
      vendorData.value = data;
    } catch (e) {
      errorMessage('Failed to load report: $e');
    } finally {
      isLoading(false);
    }
  }

  void refresh() => fetchData();

  Map<String, String> get summaryStats {
    final v = vendorData.value;
    if (v == null) return {};
    return {
      'Total Billed': 'Rs. ${_fmt(v.totalBilled)}',
      'Received': 'Rs. ${_fmt(v.totalReceived)}',
      'Pending': 'Rs. ${_fmt(v.totalPending)}',
      'Live Products': '${v.totalLiveProducts}',
      'Pending Products': '${v.totalPendingProducts}',
      'Order Requests': '${v.totalOrderRequests}',
      'Completed': '${v.completedOrders}',
    };
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
