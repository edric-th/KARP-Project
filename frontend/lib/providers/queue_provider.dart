import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/queue_service.dart';

/// One queue the provider should track: a doctor's queue or a hospital
/// reception desk's queue. Identified by [key] so callers can look its snapshot
/// up via [QueueProvider.statusFor].
class QueueTarget {
  final String key; // "doctor:<id>" or "reception:<id>"
  final String id; // doctorId, or hospitalId when [reception] is true
  final bool reception;
  final String? date;
  const QueueTarget(this.key, this.id, this.reception, this.date);

  static String doctorKey(String id) => 'doctor:$id';
  static String receptionKey(String id) => 'reception:$id';
}

/// Tracks any number of live queues at once (doctors' and/or hospital reception
/// desks'), polling them all every [_interval]. A patient who holds both a
/// doctor appointment and an online token has two queues tracked side by side.
class QueueProvider extends ChangeNotifier {
  QueueProvider(this._queue);
  final QueueService _queue;

  static const _interval = Duration(seconds: 40);

  final Map<String, QueueStatusModel> _statuses = {}; // key -> snapshot
  final Map<String, QueueTarget> _targets = {}; // key -> tracked target
  final Set<String> _loadingKeys = {}; // keys with an in-flight first fetch
  String? error;

  Timer? _timer;

  /// The latest snapshot for a tracked queue, or null if not (yet) loaded.
  QueueStatusModel? statusFor(String key) => _statuses[key];

  /// True while a queue's first snapshot is still loading (nothing cached yet).
  bool isLoading(String key) => _loadingKeys.contains(key);

  /// Track exactly [targets]: new ones start loading, ones no longer present are
  /// dropped (with their cached snapshot), and a single shared timer polls them
  /// all. Pass `[]` to stop tracking everything.
  Future<void> sync(List<QueueTarget> targets) async {
    final desired = {for (final t in targets) t.key: t};

    // Drop stale targets and their cached snapshots so a switched/cancelled
    // booking can't leak an old "now serving" number.
    final stale = _targets.keys.where((k) => !desired.containsKey(k)).toList();
    for (final k in stale) {
      _statuses.remove(k);
      _loadingKeys.remove(k);
    }
    _targets
      ..clear()
      ..addAll(desired);

    if (_targets.isEmpty) {
      stop();
      notifyListeners();
      return;
    }

    await _fetchAll();
    _timer ??= Timer.periodic(_interval, (_) => _fetchAll());
  }

  Future<void> refreshNow() => _fetchAll();

  Future<void> _fetchAll() async {
    if (_targets.isEmpty) return;
    // Show a spinner only for queues with no cached snapshot yet.
    var changed = false;
    for (final key in _targets.keys) {
      if (!_statuses.containsKey(key) && _loadingKeys.add(key)) changed = true;
    }
    if (changed) notifyListeners();

    await Future.wait(_targets.values.map(_fetchOne));
    notifyListeners();
  }

  Future<void> _fetchOne(QueueTarget t) async {
    try {
      _statuses[t.key] = t.reception
          ? await _queue.forReception(t.id, date: t.date)
          : await _queue.forDoctor(t.id, date: t.date);
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load queue';
    } finally {
      _loadingKeys.remove(t.key);
    }
  }

  /// Stops polling but keeps cached snapshots. [sync] with `[]` clears state.
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
