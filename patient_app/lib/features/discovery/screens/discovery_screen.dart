import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/discovery_provider.dart';
import '../models/physio_model.dart';
import '../../../core/theme/app_theme.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(lat: pos.latitude, lng: pos.longitude));
    } catch (_) {}
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(physioSearchProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Find Physiotherapist'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilters),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchCtrl, onChanged: (v) {
            ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(specialty: v.isEmpty ? null : v));
          }),
          _TypeFilter(selected: _selectedType, onSelect: (t) {
            setState(() => _selectedType = t);
            ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(bookingType: t));
          }),
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (result) => result.physios.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: result.physios.length,
                      itemBuilder: (_, i) => _PhysioCard(physio: result.physios[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(ref: ref),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by specialty (e.g. spine, knee)',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { controller.clear(); onChanged(''); })
              : null,
        ),
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _TypeFilter({this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const types = [
      (null, 'All'),
      ('home_visit', '🏠 Home Visit'),
      ('video_consult', '📱 Video'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: types.map((t) {
          final active = selected == t.$1;
          return GestureDetector(
            onTap: () => onSelect(t.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryBlue : AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppTheme.primaryBlue : AppTheme.divider),
              ),
              alignment: Alignment.center,
              child: Text(t.$2, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppTheme.textPrimary,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PhysioCard extends StatelessWidget {
  final PhysioCard physio;
  const _PhysioCard({required this.physio});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/physio/${physio.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: physio.avatarUrl != null ? NetworkImage(physio.avatarUrl!) : null,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: physio.avatarUrl == null ? Text(physio.name[0], style: const TextStyle(fontSize: 20, color: AppTheme.primaryBlue)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(physio.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                if (physio.qualification != null)
                  Text(physio.qualification!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  Text(' ${physio.rating.toStringAsFixed(1)} (${physio.totalReviews})',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  if (physio.distanceKm != null) ...[
                    const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                    Text('${physio.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  if (physio.homeVisitCharge != null)
                    _PriceTag(label: 'Home ₹${physio.homeVisitCharge!.toStringAsFixed(0)}'),
                  if (physio.videoConsultCharge != null) ...[
                    const SizedBox(width: 6),
                    _PriceTag(label: 'Video ₹${physio.videoConsultCharge!.toStringAsFixed(0)}'),
                  ],
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final String label;
  const _PriceTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.primaryBlue.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
      SizedBox(height: 12),
      Text('No physiotherapists found', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
      Text('Try adjusting your filters', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    ]),
  );
}

class _FilterSheet extends StatelessWidget {
  final WidgetRef ref;
  const _FilterSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [1.0, 2.0, 3.0, 4.0].map((r) {
          return GestureDetector(
            onTap: () => ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(minRating: r)),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Text('${r.toStringAsFixed(0)}+ ⭐', style: const TextStyle(fontSize: 13)),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); ref.invalidate(physioSearchProvider); },
          child: const Text('Apply Filters'),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
