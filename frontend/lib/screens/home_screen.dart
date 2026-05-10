import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/app_strings.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/dummy_data.dart';
import 'package:frontend/widgets/common/custom_input_field.dart';
import 'package:frontend/widgets/home/doctor_card.dart';
import 'package:frontend/widgets/home/hospital_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final user = DummyData.currentUser;
    final activeQueue = DummyData.queues
        .where((q) => q.status == QueueStatus.active)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, user),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SearchField(
                  hint: 'Search hospitals, doctors...',
                  onChanged: (q) {
                    if (q.isNotEmpty) {
                      Navigator.pushNamed(context, '/doctors');
                    }
                  },
                ),
                if (activeQueue != null) ...[
                  const SizedBox(height: 24),
                  _buildActiveBanner(context, activeQueue),
                ],
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  context,
                  'Nearby Hospitals',
                  onSeeAll: () => Navigator.pushNamed(context, '/hospitals'),
                ),
                const SizedBox(height: 14),
                ...DummyData.hospitals.take(3).map(
                      (h) => HospitalCard(
                        hospital: h,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/hospital-detail',
                          arguments: h,
                        ),
                      ),
                    ),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  context,
                  'Top Doctors',
                  onSeeAll: () => Navigator.pushNamed(context, '/doctors'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: DummyData.doctors.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) => DoctorCard(
                      doctor: DummyData.doctors[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/doctor-detail',
                        arguments: DummyData.doctors[i],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.backgroundDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.darkGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting, 👋',
                              style: TextStyle(fontFamily: 'Inter', 
                                fontSize: 13,
                                color: AppColors.textOnDarkSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.name,
                              style: TextStyle(fontFamily: 'Inter', 
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                        child: Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.calendar_today_rounded,
                        label:
                            '${DummyData.appointments.where((a) => a.status == AppointmentStatus.upcoming).length} upcoming',
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        icon: Icons.queue_rounded,
                        label:
                            '${DummyData.queues.where((q) => q.status == QueueStatus.active || q.status == QueueStatus.waiting).length} active queues',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBanner(BuildContext context, QueueModel queue) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/queue-detail', arguments: queue),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.primaryShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '#${queue.queueNumber}',
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Queue',
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    queue.hospitalName,
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${queue.totalAhead} ahead • ~${queue.estimatedMinutes} min',
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.local_hospital_rounded,
            label: 'Join Queue',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/hospitals'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_today_rounded,
            label: 'Book Appt.',
            color: AppColors.info,
            onTap: () => Navigator.pushNamed(context, '/book-appointment'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_search_rounded,
            label: 'Doctors',
            color: const Color(0xFF8B5CF6),
            onTap: () => Navigator.pushNamed(context, '/doctors'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    required VoidCallback onSeeAll,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            AppStrings.viewAll,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textOnDarkSecondary, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
