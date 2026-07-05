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
    String? bookingSource,
    String? problem,
    String? notes,
  }) async {
    final data = await _api.post('/bookings', auth: true, body: {
      'doctorId': doctorId,
      'patientName': patientName,
      if (patientPhone != null) 'patientPhone': patientPhone,
      'bookingType': bookingType,
      if (bookingDate != null) 'bookingDate': bookingDate,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (bookingSource != null) 'bookingSource': bookingSource,
      if (problem != null) 'problem': problem,
      if (notes != null) 'notes': notes,
    });
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Reserve an online token (hospital reception queue only — no doctor, no
  /// payment). Returns the created token as a BookingModel.
  Future<BookingModel> createReceptionToken({
    required String hospitalId,
    required String patientName,
    String? patientPhone,
  }) async {
    final data = await _api.post('/reception-tokens', auth: true, body: {
      'hospitalId': hospitalId,
      'patientName': patientName,
      if (patientPhone != null) 'patientPhone': patientPhone,
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

  /// Tell the doctor the patient is back (after being put on hold for an X-ray /
  /// another department) so they can be called in again.
  Future<void> notifyReturn(String id) =>
      _api.post('/bookings/$id/return', auth: true);

  /// Submit post-consultation feedback: a star rating each for the doctor and
  /// the hospital plus an optional comment. Marks the booking as reviewed.
  Future<void> submitFeedback(
    String id, {
    required double doctorRating,
    required double hospitalRating,
    String? text,
  }) async {
    await _api.post('/bookings/$id/feedback', auth: true, body: {
      'doctorRating': doctorRating,
      'hospitalRating': hospitalRating,
      if (text != null && text.isNotEmpty) 'text': text,
    });
  }

  Future<BookingModel> reschedule(String id, String bookingDate,
      {String? time}) async {
    final data = await _api.post('/bookings/$id/reschedule', auth: true, body: {
      'bookingDate': bookingDate,
      if (time != null) 'time': time,
    });
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
