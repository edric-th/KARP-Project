import 'package:frontend/models/models.dart';
import 'package:frontend/services/api_client.dart';

class NotificationService {
  NotificationService(this._api);
  final ApiClient _api;

  Future<List<NotificationModel>> list() async {
    final data = await _api.get('/notifications', auth: true);
    return (data as List)
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> markRead(String id) =>
      _api.post('/notifications/$id/read', auth: true);
}
