import 'package:frontend/models/models.dart';
import 'package:frontend/services/api_client.dart';

class HospitalService {
  HospitalService(this._api);
  final ApiClient _api;

  Future<List<HospitalModel>> list() async {
    final data = await _api.get('/hospitals');
    return (data as List)
        .map((e) => HospitalModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<HospitalModel> getById(String id) async {
    final data = await _api.get('/hospitals/$id');
    return HospitalModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
