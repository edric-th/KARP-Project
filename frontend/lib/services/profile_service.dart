import 'package:frontend/models/profile_model.dart';
import 'package:frontend/services/api_client.dart';

class ProfileService {
  ProfileService(this._api);
  final ApiClient _api;

  Future<ProfileModel> getProfile() async {
    final data = await _api.get('/profile', auth: true);
    return ProfileModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// [fields] is a flat camelCase map; the backend splits name/phone to the
  /// top level and merges the rest under `profile`.
  Future<ProfileModel> updateProfile(Map<String, dynamic> fields) async {
    final data = await _api.put('/profile', auth: true, body: fields);
    return ProfileModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
