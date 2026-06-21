import 'package:frontend/models/json_utils.dart';
import 'package:frontend/models/models.dart';

/// A booking/token as returned by the backend `bookings` endpoints.
class BookingModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String hospitalId;
  final String hospitalName;
  final String patientName;
  final String patientPhone;
  final String bookingType; // first_visit | follow_up | report
  final String bookingSource; // appointment | online_token
  final String status; // pending | active | served | no_show | cancelled
  final int tokenNumber;
  final String bookingDate; // YYYY-MM-DD
  final int? estimatedWaitMinutes;
  final String? expectedCallAt; // ISO-8601
  final int? position; // live position in queue (0 = now serving)
  final String paymentMethod;
  final String paymentStatus;
  final String? diagnosis;
  final DateTime? servedAt;
  final String? preferredTime; // patient-chosen slot label, e.g. "10:30 AM"
  final String problem; // patient's "describe your problem" text
  final String notes; // patient's "extra notes for the doctor" text
  final bool reviewed; // true once the patient has left post-visit feedback

  const BookingModel({
    required this.id,
    required this.doctorId,
    this.doctorName = '',
    this.hospitalId = '',
    this.hospitalName = '',
    this.patientName = '',
    this.patientPhone = '',
    this.bookingType = 'first_visit',
    this.bookingSource = 'appointment',
    this.status = 'pending',
    this.tokenNumber = 0,
    this.bookingDate = '',
    this.estimatedWaitMinutes,
    this.expectedCallAt,
    this.position,
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.diagnosis,
    this.servedAt,
    this.preferredTime,
    this.problem = '',
    this.notes = '',
    this.reviewed = false,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: asString(json['id']),
        doctorId: asString(json['doctorId']),
        doctorName: asString(json['doctorName']),
        hospitalId: asString(json['hospitalId']),
        hospitalName: asString(json['hospitalName']),
        patientName: asString(json['patientName']),
        patientPhone: asString(json['patientPhone']),
        bookingType: asString(json['bookingType'], 'first_visit'),
        bookingSource: asString(json['bookingSource'], 'appointment'),
        status: asString(json['status'], 'pending'),
        tokenNumber: asInt(json['tokenNumber']),
        bookingDate: asString(json['bookingDate']),
        estimatedWaitMinutes: json['estimatedWaitMinutes'] is num
            ? (json['estimatedWaitMinutes'] as num).toInt()
            : null,
        expectedCallAt:
            json['expectedCallAt'] == null ? null : asString(json['expectedCallAt']),
        position: json['position'] is num ? (json['position'] as num).toInt() : null,
        paymentMethod: asString(json['paymentMethod']),
        paymentStatus: asString(json['paymentStatus']),
        diagnosis: json['diagnosis'] == null ? null : asString(json['diagnosis']),
        servedAt: asDate(json['servedAt']),
        preferredTime: json['preferredTime'] == null
            ? null
            : asString(json['preferredTime']),
        problem: asString(json['problem']),
        notes: asString(json['notes']),
        reviewed: asBool(json['reviewed']),
      );

  AppointmentType get appointmentType => appointmentTypeFromApi(bookingType);
  AppointmentStatus get appointmentStatus => appointmentStatusFromBooking(status);
  QueueStatus get queueStatus => queueStatusFromBooking(status);

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isLive => isActive || isPending; // still in today's queue

  /// An online token is a hospital reception-desk ticket, not a doctor booking.
  bool get isReceptionToken => bookingSource == 'online_token';
  bool get isServed => status == 'served';
  bool get isCancelled => status == 'cancelled' || status == 'no_show';

  DateTime? get expectedCallTime => asDate(expectedCallAt);
  String get tokenLabel => tokenNumber.toString().padLeft(3, '0');
}
