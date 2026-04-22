import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

final _earningsPeriodProvider = StateProvider.autoDispose<String>((ref) => 'month');

final _earningsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, period) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('${ApiEndpoints.physioEarnings}?period=$period');
  return res.data['data'] as Map<String, dynamic>;
});

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period     = ref.watch(_earningsPeriodProvider);
    final earningsAsync = ref.watch(_earningsProvider(period));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _PeriodChip(label: 'This Week',  value: 'week',  selected: period == 'week',  onTap: () => ref.read(_earningsPeriodProvider.notifier).state = 'week'),
                const SizedBox(width: 8),
                _PeriodChip(label: 'This Month', value: 'month', selected: period == 'month', onTap: () => ref.read(_earningsPeriodProvider.notifier).state = 'month'),
                const SizedBox(width: 8),
                _PeriodChip(label: 'All Time',   value: 'all',   selected: period == 'all',   onTap: () => ref.read(_earningsPeriodProvider.notifier).state = 'all'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: earningsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$e', style: TextStyle(color: AppTheme.textLight)),
                  TextButton(
                    onPressed: () => ref.invalidate(_earningsProvider(period)),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () => ref.refresh(_earningsProvider(period).future),
                child: _EarningsBody(data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _EarningsBody({required this.data});

  String _fmt(num amount) =>
      '₹${(amount / 100).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final gross     = (data['gross_earned']    as num?)?.toDouble() ?? 0;
    final net       = (data['net_earned']       as num?)?.toDouble() ?? 0;
    final commission= (data['commission_paid']  as num?)?.toDouble() ?? 0;
    final sessions  = (data['sessions_count']   as num?)?.toInt()    ?? 0;
    final pending   = (data['pending_payout']   as num?)?.toDouble() ?? 0;
    final payouts   = data['recent_payouts'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen, const Color(0xFF00695C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Net Earned', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_fmt(net),
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(children: [
                _MiniStat(label: 'Gross',      value: _fmt(gross)),
                const SizedBox(width: 24),
                _MiniStat(label: 'Commission', value: _fmt(commission)),
                const SizedBox(width: 24),
                _MiniStat(label: 'Sessions',   value: '$sessions'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pending payout card
        if (pending > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFFF8F00), size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Pending Payout',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${_fmt(pending)} will be transferred shortly',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF795548))),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Stats grid
        Row(children: [
          _StatCard(label: 'Total Sessions', value: '$sessions', icon: Icons.check_circle_outline, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          _StatCard(label: 'Commission Rate', value: '15%', icon: Icons.percent, color: const Color(0xFF7B61FF)),
        ]),
        const SizedBox(height: 16),

        // Recent payouts
        if (payouts.isNotEmpty) ...[
          const Text('Recent Payouts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...payouts.map((p) {
            final payout = p as Map<String, dynamic>;
            final amount = (payout['net_amount'] as num?)?.toDouble() ?? 0;
            final status = payout['status'] as String? ?? '';
            final date   = payout['created_at'] as String?;
            return _PayoutTile(amount: amount, status: status, date: date);
          }),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_outlined, color: AppTheme.textLight, size: 20),
              const SizedBox(width: 8),
              Text('No payouts yet for this period',
                  style: TextStyle(color: AppTheme.textLight)),
            ]),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      Text(value,  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,  style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ]),
        ]),
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final double amount;
  final String status;
  final String? date;
  const _PayoutTile({required this.amount, required this.status, this.date});

  Color get _statusColor => switch (status) {
    'completed' => const Color(0xFF4CAF50),
    'pending'   => const Color(0xFFFF9800),
    _           => AppTheme.textLight,
  };

  String _fmt(double v) =>
      '₹${(v / 100).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_downward, color: _statusColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_fmt(amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          if (date != null)
            Text(
              DateTime.tryParse(date!)?.toString().substring(0, 10) ?? date!,
              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
        ),
      ]),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryGreen : AppTheme.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textLight,
          ),
        ),
      ),
    );
  }
}
