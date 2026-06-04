import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_input_field.dart';
import 'package:frontend/widgets/common/state_views.dart';
import 'package:frontend/widgets/home/hospital_card.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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

  List<HospitalModel> _filter(List<HospitalModel> all) {
    final q = _searchQuery.toLowerCase();
    return all.where((h) {
      return q.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q) ||
          h.city.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final filtered = _filter(catalog.hospitals);

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
          Expanded(child: _buildBody(catalog, filtered)),
        ],
      ),
    );
  }

  Widget _buildBody(CatalogProvider catalog, List<HospitalModel> filtered) {
    if (catalog.loading && catalog.hospitals.isEmpty) {
      return const LoadingView();
    }
    if (catalog.error != null && catalog.hospitals.isEmpty) {
      return ErrorRetry(
        message: catalog.error!,
        onRetry: () => context.read<CatalogProvider>().load(force: true),
      );
    }
    if (filtered.isEmpty) {
      return const EmptyView(
        icon: Icons.local_hospital_outlined,
        title: 'No hospitals found',
        subtitle: 'Try a different search term',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<CatalogProvider>().load(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) => HospitalCard(
          hospital: filtered[i],
          onTap: () => Navigator.pushNamed(
            context,
            '/hospital-detail',
            arguments: filtered[i],
          ),
        ),
      ),
    );
  }
}
