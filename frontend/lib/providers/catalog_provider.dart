import 'package:flutter/foundation.dart';

import 'package:frontend/models/models.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/doctor_service.dart';
import 'package:frontend/services/hospital_service.dart';

/// Shared catalog of hospitals + doctors (browse screens).
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._hospitals, this._doctors);
  final HospitalService _hospitals;
  final DoctorService _doctors;

  List<HospitalModel> hospitals = [];
  List<DoctorModel> doctors = [];
  bool loading = false;
  String? error;
  bool _loadedOnce = false;

  Future<void> load({bool force = false}) async {
    if (_loadedOnce && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final hf = _hospitals.list();
      final df = _doctors.list();
      hospitals = await hf;
      doctors = await df;
      _loadedOnce = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load data';
    }
    loading = false;
    notifyListeners();
  }

  HospitalModel? hospitalById(String id) {
    for (final h in hospitals) {
      if (h.id == id) return h;
    }
    return null;
  }

  List<DoctorModel> doctorsForHospital(String hospitalId) =>
      doctors.where((d) => d.hospitalId == hospitalId).toList();

  /// Specialties present across loaded doctors, prefixed with "All".
  List<String> get specialties {
    final set = <String>{};
    for (final d in doctors) {
      if (d.specialty.isNotEmpty) set.add(d.specialty);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }
}
