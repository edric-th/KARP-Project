import 'package:flutter/foundation.dart';

import 'package:frontend/models/booking_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/booking_service.dart';

class BookingsProvider extends ChangeNotifier {
  BookingsProvider(this._bookings);
  final BookingService _bookings;

  List<BookingModel> items = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _bookings.mine();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load bookings';
    }
    loading = false;
    notifyListeners();
  }

  /// The patient's current live token (pending/active), if any.
  BookingModel? get activeBooking {
    for (final b in items) {
      if (b.isLive) return b;
    }
    return null;
  }

  /// The patient's current live doctor appointment (not an online token), if any.
  BookingModel? get activeAppointment {
    for (final b in items) {
      if (b.isLive && !b.isReceptionToken) return b;
    }
    return null;
  }

  /// The patient's current live online reception token, if any.
  BookingModel? get activeReceptionToken {
    for (final b in items) {
      if (b.isLive && b.isReceptionToken) return b;
    }
    return null;
  }

  /// Up to two live bookings — the appointment and the online token — in the
  /// order they should be shown. Empty when the patient is in no queue.
  List<BookingModel> get activeBookings =>
      [?activeAppointment, ?activeReceptionToken];

  List<BookingModel> get upcoming =>
      items.where((b) => b.isLive).toList();
  List<BookingModel> get past => items.where((b) => !b.isLive).toList();

  /// Creates a booking and refreshes the list. Rethrows on failure so the
  /// caller (payment screen) can surface the error.
  Future<BookingModel> create({
    required String doctorId,
    required String patientName,
    String? patientPhone,
    required String bookingType,
    String? bookingDate,
    String? paymentMethod,
    String? paymentStatus,
    String? bookingSource,
  }) async {
    final booking = await _bookings.create(
      doctorId: doctorId,
      patientName: patientName,
      patientPhone: patientPhone,
      bookingType: bookingType,
      bookingDate: bookingDate,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      bookingSource: bookingSource,
    );
    await load();
    return booking;
  }

  /// Reserves an online token (hospital reception queue) and refreshes the list.
  Future<BookingModel> createReceptionToken({
    required String hospitalId,
    required String patientName,
    String? patientPhone,
  }) async {
    final booking = await _bookings.createReceptionToken(
      hospitalId: hospitalId,
      patientName: patientName,
      patientPhone: patientPhone,
    );
    await load();
    return booking;
  }

  Future<bool> cancel(String id) async {
    try {
      await _bookings.cancel(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<BookingModel?> reschedule(String id, String date,
      {String? time}) async {
    try {
      final b = await _bookings.reschedule(id, date, time: time);
      await load();
      return b;
    } catch (_) {
      return null;
    }
  }
}
