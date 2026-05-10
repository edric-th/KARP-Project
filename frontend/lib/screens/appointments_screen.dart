import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/app_strings.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/dummy_data.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/appointment/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<AppointmentModel> _appointments;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _appointments = List.from(DummyData.appointments);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppointmentModel> _getFiltered(int tab) {
    switch (tab) {
      case 0:
        return _appointments
            .where((a) => a.status == AppointmentStatus.upcoming)
            .toList();
      case 1:
        return _appointments
            .where((a) => a.status == AppointmentStatus.completed)
            .toList();
      case 2:
        return _appointments
            .where((a) => a.status == AppointmentStatus.cancelled)
            .toList();
      default:
        return _appointments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: AppStrings.appointments,
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/book-appointment'),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (tabIndex) {
                final list = _getFiltered(tabIndex);
                if (list.isEmpty) return _buildEmpty(tabIndex);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => AppointmentCard(
                    appointment: list[i],
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Appointment with ${list[i].doctor.name}'),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                    onCancel: list[i].status == AppointmentStatus.upcoming
                        ? () => _showCancelDialog(list[i])
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(int tabIndex) {
    final labels = ['upcoming', 'completed', 'cancelled'];
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: AppColors.cardGreenLight, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.calendar_today_outlined,
              color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 20),
        Text('No ${labels[tabIndex]} appointments',
            style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        if (tabIndex == 0) ...[
          Text('Book an appointment with a doctor',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/book-appointment'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14)),
              child: Text('Book Appointment',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ]),
    );
  }

  void _showCancelDialog(AppointmentModel appt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Icon(Icons.cancel_outlined, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text('Cancel Appointment?',
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Cancel appointment with ${appt.doctor.name}?',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Keep it', style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    final idx = _appointments.indexWhere((a) => a.id == appt.id);
                    if (idx != -1) {
                      _appointments[idx] = AppointmentModel(
                        id: appt.id, doctor: appt.doctor,
                        date: appt.date, time: appt.time,
                        status: AppointmentStatus.cancelled, reason: appt.reason,
                      );
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment cancelled'),
                        backgroundColor: AppColors.error),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel', style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                    fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
