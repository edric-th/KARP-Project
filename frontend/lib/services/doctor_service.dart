import 'package:frontend/models/models.dart';
import 'package:frontend/models/review_model.dart';
import 'package:frontend/services/api_client.dart';

class DoctorService {
  DoctorService(this._api);
  final ApiClient _api;

  Future<List<DoctorModel>> list({String? hospitalId}) async {
    final data = await _api.get(
      '/doctors',
      query: hospitalId != null ? {'hospitalId': hospitalId} : null,
    );
    return (data as List)
        .map((e) => DoctorModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DoctorModel> getById(String id) async {
    final data = await _api.get('/doctors/$id');
    return DoctorModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ReviewModel>> reviews(String doctorId) async {
    final data = await _api.get('/doctors/$doctorId/reviews');
    return (data as List)
        .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addReview(String doctorId,
      {required double rating, String? text}) async {
    await _api.post('/doctors/$doctorId/reviews', auth: true, body: {
      'rating': rating,
      if (text != null && text.isNotEmpty) 'text': text,
    });
  }
}
