import 'package:frontend/models/booking_model.dart';
import 'package:frontend/models/json_utils.dart';

/// Live snapshot of a doctor's queue (GET /api/queue/{doctorId}).
class QueueStatusModel {
  final String doctorId;
  final BookingModel? nowServing;
  final List<BookingModel> waiting;
  final int waitingCount;
  final int servedCount;
  final double avgServiceMinutes;

  /// Learned expected minutes per booking type: first_visit / follow_up / report.
  final Map<String, double> typeAverages;

  const QueueStatusModel({
    required this.doctorId,
    this.nowServing,
    this.waiting = const [],
    this.waitingCount = 0,
    this.servedCount = 0,
    this.avgServiceMinutes = 0,
    this.typeAverages = const {},
  });

  static Map<String, double> _parseTypeAverages(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), asDouble(val)));
    }
    return const {};
  }

  factory QueueStatusModel.fromJson(Map<String, dynamic> json) {
    final serving = json['nowServing'];
    return QueueStatusModel(
      doctorId: asString(json['doctorId']),
      nowServing: serving is Map
          ? BookingModel.fromJson(Map<String, dynamic>.from(serving))
          : null,
      waiting: json['waiting'] is List
          ? (json['waiting'] as List)
              .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
      waitingCount: asInt(json['waitingCount']),
      servedCount: asInt(json['servedCount']),
      avgServiceMinutes: asDouble(json['avgServiceMinutes']),
      typeAverages: _parseTypeAverages(json['typeAverages']),
    );
  }

  /// The live entry (position + ETA) for a booking id, if it's in this queue.
  BookingModel? entryFor(String bookingId) {
    for (final w in waiting) {
      if (w.id == bookingId) return w;
    }
    if (nowServing?.id == bookingId) return nowServing;
    return null;
  }
}
