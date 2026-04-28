class Doctor {
  final String name;
  final String specialization;
  final String? experience;
  final double? rating;
  final String status;
  final int? waitingCount;
  final String? waitTime;

  Doctor({
    required this.name,
    required this.specialization,
    this.experience,
    this.rating,
    required this.status,
    this.waitingCount,
    this.waitTime,
  });
}

import 'package:flutter/material.dart';

class Specialty {
  final String name;
  final IconData icon;

  Specialty({
    required this.name,
    required this.icon,
  });
}
