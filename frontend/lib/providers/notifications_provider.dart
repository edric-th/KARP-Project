import 'package:flutter/foundation.dart';

import 'package:frontend/models/models.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._svc);
  final NotificationService _svc;

  List<NotificationModel> items = [];
  bool loading = false;
  String? error;

  int get unreadCount => items.where((n) => !n.isRead).length;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      items = await _svc.list();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load notifications';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    // Optimistic local update.
    items = [
      for (final n in items) n.id == id ? n.copyWith(isRead: true) : n,
    ];
    notifyListeners();
    try {
      await _svc.markRead(id);
    } catch (_) {/* ignore; will reconcile on next load */}
  }
}
