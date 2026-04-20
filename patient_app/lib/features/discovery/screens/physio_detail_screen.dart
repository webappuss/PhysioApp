import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/discovery_provider.dart';
import '../models/physio_model.dart';
import '../../../core/theme/app_theme.dart';

class PhysioDetailScreen extends ConsumerWidget {
  final int physioId;
  const PhysioDetailScreen({super.key, required this.physioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(physioDetailProvider(physioId));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (detail) => _DetailBody(detail: detail, physioId: physioId),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final PhysioDetail detail;
  final int physioId;
  const _DetailBody({required this.detail, required this.physioId});

  @override
  Widget build(BuildContext context) {
    final p = detail.profile;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF0D4FA8)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                  backgroundColor: Colors.white24,
                  child: p.avatarUrl == null ? Text(p.name[0], style: const TextStyle(fontSize: 28, color: Colors.white)) : null,
                ),
                const SizedBox(height: 8),
                Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(p.qualification ?? '', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StatsRow(physio: p),
              const SizedBox(height: 16),
              _PricingCard(physio: p),
              const SizedBox(height: 16),
              if (p.specializations.isNotEmpty) _SpecsSection(specs: p.specializations),
              const SizedBox(height: 16),
              if (detail.reviews.isNotEmpty) _ReviewsSection(reviews: detail.reviews),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PhysioCard physio;
  const _StatsRow({required this.physio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(value: physio.rating.toStringAsFixed(1), label: 'Rating', icon: '⭐'),
        _divider(),
        _Stat(value: '${physio.totalSessions}', label: 'Sessions', icon: '📋'),
        _divider(),
        _Stat(value: '${physio.yearsExperience ?? 0}y', label: 'Experience', icon: '🏥'),
        _divider(),
        _Stat(value: '${physio.totalReviews}', label: 'Reviews', icon: '💬'),
      ],
    );
  }

  Widget _divider() => const SizedBox(
    height: 40, child: VerticalDivider(color: AppTheme.divider),
  );
}

class _Stat extends StatelessWidget {
  final String value, label, icon;
  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]),
  );
}

class _PricingCard extends StatelessWidget {
  final PhysioCard physio;
  const _PricingCard({required this.physio});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Session Fees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (physio.homeVisitCharge != null)
            _FeeRow(icon: '🏠', label: 'Home Visit', amount: physio.homeVisitCharge!),
          if (physio.videoConsultCharge != null)
            _FeeRow(icon: '📱', label: 'Video Consult', amount: physio.videoConsultCharge!),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.push('/book/${physio.id}'),
            child: const Text('Book Appointment'),
          ),
        ]),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String icon, label;
  final double amount;
  const _FeeRow({required this.icon, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$icon $label', style: const TextStyle(color: AppTheme.textPrimary)),
        Text('₹${amount.toStringAsFixed(0)}/session',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
      ],
    ),
  );
}

class _SpecsSection extends StatelessWidget {
  final List<String> specs;
  const _SpecsSection({required this.specs});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Specializations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: specs.map((s) => Chip(
          label: Text(s, style: const TextStyle(fontSize: 12)),
          backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
          side: BorderSide.none,
        )).toList(),
      ),
    ]);
  }
}

class _ReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  const _ReviewsSection({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Reviews (${reviews.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ...reviews.take(3).map((r) => _ReviewCard(review: r)),
    ]);
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(review.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          ...List.generate(5, (i) => Icon(
            i < review.rating ? Icons.star : Icons.star_border,
            size: 14, color: Colors.amber,
          )),
        ]),
        if (review.reviewText != null) ...[
          const SizedBox(height: 4),
          Text(review.reviewText!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ]),
    ),
  );
}
