import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/queue_service.dart';

/// Tracks a single doctor's live queue, polling every [_interval].
class QueueProvider extends ChangeNotifier {
  QueueProvider(this._queue);
  final QueueService _queue;

  static const _interval = Duration(seconds: 25);

  QueueStatusModel? status;
  bool loading = false;
  String? error;

  Timer? _timer;
  String? _doctorId;
  String? _date;

  Future<void> start(String doctorId, {String? date}) async {
    if (_doctorId != doctorId) {
      status = null; // switching doctors → reset snapshot
    }
    _doctorId = doctorId;
    _date = date;
    await _fetch();
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _fetch());
  }

  Future<void> refreshNow() => _fetch();

  Future<void> _fetch() async {
    final id = _doctorId;
    if (id == null) return;
    if (status == null) {
      loading = true;
      notifyListeners();
    }
    try {
      status = await _queue.forDoctor(id, date: _date);
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load queue';
    }
    loading = false;
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
