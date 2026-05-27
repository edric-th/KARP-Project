import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/dummy_data.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_input_field.dart';
import 'package:frontend/widgets/home/hospital_card.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<HospitalModel> get _filtered => DummyData.hospitals.where((h) {
        return _searchQuery.isEmpty ||
            h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            h.address.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: 'Hospitals'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SearchField(
              hint: 'Search hospitals, location...',
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_hospital_outlined,
                          color: AppColors.textMuted,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hospitals found',
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => HospitalCard(
                      hospital: _filtered[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/hospital-detail',
                        arguments: _filtered[i],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
