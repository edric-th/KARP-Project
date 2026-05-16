import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/dummy_data.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/segmented_tabs.dart';
import 'package:frontend/widgets/queue/queue_card.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<QueueModel> _getFiltered(int tab) {
    switch (tab) {
      case 0:
        return DummyData.queues;
      case 1:
        return DummyData.queues
            .where((q) =>
                q.status == QueueStatus.active ||
                q.status == QueueStatus.waiting)
            .toList();
      case 2:
        return DummyData.queues
            .where((q) =>
                q.status == QueueStatus.completed ||
                q.status == QueueStatus.cancelled)
            .toList();
      default:
        return DummyData.queues;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: 'My Queue',
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/hospitals'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+ Join',
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SegmentedTabs(
              labels: const ['All', 'Active', 'History'],
              currentIndex: _tabController.index,
              onChanged: (i) {
                _tabController.animateTo(i);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(
                3,
                (tabIndex) {
                  final list = _getFiltered(tabIndex);
                  if (list.isEmpty) {
                    return _buildEmpty();
                  }
                  return ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => QueueCard(
                      queue: list[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/queue-detail',
                        arguments: list[i],
                      ),
                      onLeave: (list[i].status == QueueStatus.active ||
                              list[i].status == QueueStatus.waiting)
                          ? () => _showLeaveDialog(context, list[i])
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.queue_rounded,
              color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 20),
        Text('No queues here',
            style: TextStyle(fontFamily: 'Inter', 
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Join a queue at a nearby hospital',
            style: TextStyle(fontFamily: 'Inter', 
                fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/hospitals'),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14)),
            child: Text('Find Hospitals',
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  void _showLeaveDialog(BuildContext context, QueueModel queue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 48),
          const SizedBox(height: 16),
          Text('Leave Queue?',
              style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
              'Are you sure you want to leave the queue at ${queue.hospitalName}? You will lose your spot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel',
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You left the queue'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Leave',
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

