import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';

class QueueCard extends StatelessWidget {
  final QueueModel queue;
  final VoidCallback onTap;
  final VoidCallback? onLeave;

  const QueueCard({
    super.key,
    required this.queue,
    required this.onTap,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = queue.status == QueueStatus.active;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive ? AppColors.primaryShadow : AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.cardGreenLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '#${queue.queueNumber}',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : AppColors.primary,
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
                        queue.hospitalName,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${queue.doctorName} • ${queue.specialty}',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(queue.status),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                _buildInfoItem(
                  Icons.people_outline_rounded,
                  '${queue.totalAhead} Ahead',
                ),
                const SizedBox(width: 20),
                _buildInfoItem(
                  Icons.access_time_rounded,
                  '~${queue.estimatedMinutes} min',
                ),
                const Spacer(),
                if (onLeave != null)
                  GestureDetector(
                    onTap: onLeave,
                    child: Text(
                      'Leave',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(QueueStatus status) {
    Color color;
    String text;
    switch (status) {
      case QueueStatus.active:
        color = AppColors.success;
        text = 'Active';
        break;
      case QueueStatus.waiting:
        color = AppColors.info;
        text = 'Waiting';
        break;
      case QueueStatus.completed:
        color = AppColors.textMuted;
        text = 'Completed';
        break;
      case QueueStatus.cancelled:
        color = AppColors.error;
        text = 'Cancelled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
