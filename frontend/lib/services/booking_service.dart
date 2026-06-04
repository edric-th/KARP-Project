import 'package:frontend/models/booking_model.dart';
import 'package:frontend/services/api_client.dart';

class BookingService {
  BookingService(this._api);
  final ApiClient _api;

  Future<BookingModel> create({
    required String doctorId,
    required String patientName,
    String? patientPhone,
    required String bookingType,
    String? bookingDate,
    String? paymentMethod,
    String? paymentStatus,
  }) async {
    final data = await _api.post('/bookings', auth: true, body: {
      'doctorId': doctorId,
      'patientName': patientName,
      if (patientPhone != null) 'patientPhone': patientPhone,
      'bookingType': bookingType,
      if (bookingDate != null) 'bookingDate': bookingDate,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
    });
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<BookingModel>> mine() async {
    final data = await _api.get('/bookings/me', auth: true);
    return (data as List)
        .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<BookingModel> getById(String id) async {
    final data = await _api.get('/bookings/$id', auth: true);
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> cancel(String id) => _api.post('/bookings/$id/cancel', auth: true);

  Future<BookingModel> reschedule(String id, String bookingDate) async {
    final data = await _api.post('/bookings/$id/reschedule',
        auth: true, body: {'bookingDate': bookingDate});
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
