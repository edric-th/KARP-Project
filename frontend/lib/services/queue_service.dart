import 'package:frontend/models/models.dart';
import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/services/api_client.dart';

class QueueService {
  QueueService(this._api);
  final ApiClient _api;

  Future<QueueStatusModel> forDoctor(String doctorId, {String? date}) async {
    final data = await _api.get(
      '/queue/$doctorId',
      query: date != null ? {'date': date} : null,
    );
    return QueueStatusModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Live waiting count + ETA for many doctors at once (booking doctor-picker).
  Future<List<QueueSummaryModel>> summaryFor(
    List<String> doctorIds, {
    String? date,
  }) async {
    if (doctorIds.isEmpty) return const [];
    final data = await _api.get('/queue/summary', query: {
      'doctorIds': doctorIds.join(','),
      'date': ?date,
    });
    final list = data is List ? data : const [];
    return list
        .map((e) =>
            QueueSummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Live reception-desk queue for a hospital (online tokens only). Reuses the
  /// QueueStatusModel shape — `doctorId` carries the hospital id.
  Future<QueueStatusModel> forReception(String hospitalId, {String? date}) async {
    final data = await _api.get(
      '/reception/$hospitalId',
      query: date != null ? {'date': date} : null,
    );
    return QueueStatusModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Live waiting count + ETA for many hospitals' reception queues at once
  /// (online-token hospital picker).
  Future<List<QueueSummaryModel>> receptionSummaryFor(
    List<String> hospitalIds, {
    String? date,
  }) async {
    if (hospitalIds.isEmpty) return const [];
    final data = await _api.get('/reception/summary', query: {
      'hospitalIds': hospitalIds.join(','),
      'date': ?date,
    });
    final list = data is List ? data : const [];
    return list
        .map((e) =>
            QueueSummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
