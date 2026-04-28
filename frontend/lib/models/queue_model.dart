class QueueEntry {
  final int tokenNumber;
  final String status;
  final String patientType;
  final String? estimatedTime;
  final bool isCurrentUser;

  QueueEntry({
    required this.tokenNumber,
    required this.status,
    required this.patientType,
    this.estimatedTime,
    this.isCurrentUser = false,
  });
}

class CurrentToken {
  final int servingToken;
  final String doctorName;
  final String specialization;
  final int userToken;
  final String waitingTime;
  final int peopleInQueue;

  CurrentToken({
    required this.servingToken,
    required this.doctorName,
    required this.specialization,
    required this.userToken,
    required this.waitingTime,
    required this.peopleInQueue,
  });
}
