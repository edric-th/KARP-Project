import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_input_field.dart';
import 'package:frontend/widgets/common/state_views.dart';
import 'package:frontend/widgets/home/doctor_card.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});
  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String _selectedSpecialty = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorModel> _filter(List<DoctorModel> all) {
    final q = _searchQuery.toLowerCase();
    return all.where((d) {
      final matchesSearch = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.specialty.toLowerCase().contains(q);
      final matchesSpecialty =
          _selectedSpecialty == 'All' || d.specialty == _selectedSpecialty;
      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final filtered = _filter(catalog.doctors);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: 'Find Doctors', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SearchField(
              hint: 'Search doctors, specialties...',
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecialtyChips(catalog.specialties),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(catalog, filtered)),
        ],
      ),
    );
  }

  Widget _buildBody(CatalogProvider catalog, List<DoctorModel> filtered) {
    if (catalog.loading && catalog.doctors.isEmpty) {
      return const LoadingView();
    }
    if (catalog.error != null && catalog.doctors.isEmpty) {
      return ErrorRetry(
        message: catalog.error!,
        onRetry: () => context.read<CatalogProvider>().load(force: true),
      );
    }
    if (filtered.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<CatalogProvider>().load(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => DoctorCard(
          doctor: filtered[i],
          isHorizontal: true,
          onTap: () => Navigator.pushNamed(
            context,
            '/doctor-detail',
            arguments: filtered[i],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyChips(List<String> specialties) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final spec = specialties[i];
          final isSelected = _selectedSpecialty == spec;
          return GestureDetector(
            onTap: () => setState(() => _selectedSpecialty = spec),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                spec,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.person_search_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No doctors found',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Try a different search or specialty',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
