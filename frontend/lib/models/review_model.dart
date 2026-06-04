import 'package:frontend/models/json_utils.dart';

/// A patient review of a doctor (GET /api/doctors/{id}/reviews).
class ReviewModel {
  final String id;
  final String patientName;
  final double rating;
  final String text;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    this.patientName = 'Anonymous',
    this.rating = 0,
    this.text = '',
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id: asString(j['id']),
        patientName: asString(j['patientName'], 'Anonymous'),
        rating: asDouble(j['rating']),
        text: asString(j['text']),
        createdAt: asDate(j['createdAt']),
      );
}
