import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/queue_service.dart';

/// Tracks a single live queue (a doctor's, or a hospital reception desk's),
/// polling every [_interval].
class QueueProvider extends ChangeNotifier {
  QueueProvider(this._queue);
  final QueueService _queue;

  static const _interval = Duration(seconds: 25);

  QueueStatusModel? status;
  bool loading = false;
  String? error;

  Timer? _timer;
  String? _targetId; // doctorId, or hospitalId when [_reception] is true
  String? _date;
  bool _reception = false;

  /// Track a doctor's queue ([reception] = false) or a hospital reception
  /// queue ([reception] = true, [id] is the hospital id).
  Future<void> start(String id, {String? date, bool reception = false}) async {
    if (_targetId != id || _reception != reception) {
      status = null; // switching target/mode → reset snapshot
    }
    _targetId = id;
    _date = date;
    _reception = reception;
    await _fetch();
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _fetch());
  }

  Future<void> refreshNow() => _fetch();

  Future<void> _fetch() async {
    final id = _targetId;
    if (id == null) return;
    if (status == null) {
      loading = true;
      notifyListeners();
    }
    try {
      status = _reception
          ? await _queue.forReception(id, date: _date)
          : await _queue.forDoctor(id, date: _date);
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
