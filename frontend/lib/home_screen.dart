import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'models/models.dart';
import 'models/dummy_data.dart';
import 'widgets/common/custom_input_field.dart';
import 'widgets/home/doctor_card.dart';
import 'widgets/home/hospital_card.dart';
import 'widgets/appointment/appointment_card.dart';
import 'widgets/queue/queue_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeQueue = DummyData.queues.firstWhere(
      (q) => q.status == QueueStatus.active,
      orElse: () => DummyData.queues.first,
    );
    final upcomingAppointment = DummyData.appointments.firstWhere(
      (a) => a.status == AppointmentStatus.upcoming,
      orElse: () => DummyData.appointments.first,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: SearchField(
                hint: AppStrings.searchHint,
                controller: _searchController,
                onFilter: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildQuickStats(activeQueue)),
          SliverToBoxAdapter(child: _buildActiveQueue(activeQueue)),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildUpcomingAppointment(upcomingAppointment)),
          SliverToBoxAdapter(child: _buildNearbyHospitals()),
          SliverToBoxAdapter(child: _buildTopDoctors()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(), style: GoogleFonts.inter(fontSize: 13, color: AppColors.textOnDarkSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text(DummyData.currentUser.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _HeaderIconBtn(icon: Icons.notifications_none_rounded, badge: 2, onTap: () => Navigator.pushNamed(context, '/notifications')),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(QueueModel queue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'Your Queue No.', value: '#${queue.queueNumber}', icon: Icons.confirmation_number_outlined, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'People Ahead', value: '${queue.totalAhead}', icon: Icons.people_alt_outlined, color: const Color(0xFFF59E0B))),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Est. Wait', value: '~${queue.estimatedMinutes}m', icon: Icons.timer_outlined, color: AppColors.primaryLight)),
        ],
      ),
    );
  }

  Widget _buildActiveQueue(QueueModel queue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          _SectionHeader(title: AppStrings.myQueue, onSeeAll: () => Navigator.pushNamed(context, '/queue')),
          const SizedBox(height: 12),
          QueueCard(queue: queue, onTap: () => Navigator.pushNamed(context, '/queue-detail', arguments: queue), onLeave: () {}),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.quickActions, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _QuickActionCard(label: 'Join Queue', icon: Icons.queue_rounded, color: AppColors.primary, onTap: () => Navigator.pushNamed(context, '/hospitals')),
              const SizedBox(width: 12),
              _QuickActionCard(label: 'Book\nAppointment', icon: Icons.calendar_month_rounded, color: const Color(0xFF3B82F6), onTap: () => Navigator.pushNamed(context, '/appointments')),
              const SizedBox(width: 12),
              _QuickActionCard(label: 'Find\nDoctors', icon: Icons.person_search_rounded, color: const Color(0xFF8B5CF6), onTap: () => Navigator.pushNamed(context, '/doctors')),
              const SizedBox(width: 12),
              _QuickActionCard(label: 'Hospitals\nNearby', icon: Icons.local_hospital_rounded, color: const Color(0xFFEC4899), onTap: () => Navigator.pushNamed(context, '/hospitals')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointment(AppointmentModel appointment) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _SectionHeader(title: AppStrings.myAppointments, onSeeAll: () => Navigator.pushNamed(context, '/appointments')),
          const SizedBox(height: 12),
          AppointmentCard(appointment: appointment, onTap: () {}, onCancel: () {}, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildNearbyHospitals() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _SectionHeader(title: AppStrings.nearbyHospitals, onSeeAll: () => Navigator.pushNamed(context, '/hospitals')),
          const SizedBox(height: 12),
          ...DummyData.hospitals.take(2).map((h) => HospitalCard(hospital: h, onTap: () => Navigator.pushNamed(context, '/hospital-detail', arguments: h))),
        ],
      ),
    );
  }

  Widget _buildTopDoctors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _SectionHeader(title: AppStrings.topDoctors, onSeeAll: () => Navigator.pushNamed(context, '/doctors')),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: DummyData.doctors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => DoctorCard(doctor: DummyData.doctors[i], onTap: () => Navigator.pushNamed(context, '/doctor-detail', arguments: DummyData.doctors[i])),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (onSeeAll != null)
          GestureDetector(onTap: onSeeAll, child: Text(AppStrings.seeAll, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback? onTap;
  const _QuickActionCard({required this.label, required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.15))),
          child: Column(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon; final int badge; final VoidCallback? onTap;
  const _HeaderIconBtn({required this.icon, this.badge = 0, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 22)),
        if (badge > 0) Positioned(right: 6, top: 6, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle, border: Border.all(color: AppColors.backgroundDark, width: 1.5)), child: Center(child: Text('$badge', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))))),
      ]),
    );
  }
}