import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final String type;
  final bool isRead;
  final Map<String, dynamic> data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.type,
    required this.isRead,
    required this.data,
  });
}

class VendorNotificationsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  var notifications = <NotificationItem>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _db
        .collection('vendors')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
          notifications.value = snap.docs.map((doc) {
            var d = doc.data();
            return NotificationItem(
              id: doc.id,
              title: d['title'] ?? '',
              body: d['body'] ?? '',
              date: d['timestamp'] != null
                  ? (d['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
              type: d['type'] ?? '',
              isRead: d['isRead'] ?? false,
              data: Map<String, dynamic>.from(d['data'] ?? {}),
            );
          }).toList();
          isLoading.value = false;
        });
  }

  Future<void> markAsRead(String notifId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('vendors')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    WriteBatch batch = _db.batch();
    for (var n in unread) {
      batch.update(
        _db
            .collection('vendors')
            .doc(uid)
            .collection('notifications')
            .doc(n.id),
        {'isRead': true},
      );
    }
    await batch.commit();
  }
}
