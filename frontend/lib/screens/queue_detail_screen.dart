import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';

class QueueDetailScreen extends StatelessWidget {
  final QueueModel queue;
  const QueueDetailScreen({super.key, required this.queue});

  @override
  Widget build(BuildContext context) {
    final isActive = queue.status == QueueStatus.active ||
        queue.status == QueueStatus.waiting;
    final double progress = (queue.queueNumber > 0)
        ? (1.0 - queue.totalAhead / queue.queueNumber.toDouble()).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Container(
            height: 340,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white12,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      Text('Queue Details',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(color: Colors.white12,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2)),
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('#${queue.queueNumber}',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 36,
                                  fontWeight: FontWeight.w900, color: Colors.white)),
                          Text('Your Number',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                        ]),
                  ),
                ),
                const SizedBox(height: 16),
                Text(queue.hospitalName,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 20,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(queue.department,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        Row(children: [
                          _DetailStat(label: 'Serving', value: '#${queue.currentNumber}',
                              icon: Icons.medical_services_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          _DetailStat(label: 'Ahead', value: '${queue.totalAhead}',
                              icon: Icons.people_alt_rounded, color: const Color(0xFFF59E0B)),
                          const SizedBox(width: 12),
                          _DetailStat(label: 'Wait', value: '${queue.estimatedMinutes}m',
                              icon: Icons.timer_rounded, color: const Color(0xFF3B82F6)),
                        ]),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Queue Progress',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                                          fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  Text('${(progress * 100).toInt()}%',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                                          fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ]),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: AppColors.cardGreenLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(color: AppColors.cardGreenLight,
                                  borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.person_rounded,
                                  color: AppColors.primaryMedium, size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(queue.doctorName,
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                                          fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  Text(queue.specialty,
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                          color: AppColors.primaryLight)),
                                ])),
                          ]),
                        ),
                        const SizedBox(height: 32),
                        if (isActive)
                          SizedBox(
                            width: double.infinity, height: 54,
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You have left the queue'),
                                      backgroundColor: AppColors.error),
                                );
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Leave Queue',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                                      fontWeight: FontWeight.w600, color: AppColors.error)),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _DetailStat({required this.label, required this.value,
      required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 18,
            fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textMuted)),
      ]),
    ),
  );
}
