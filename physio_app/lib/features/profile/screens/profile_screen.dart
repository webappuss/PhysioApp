import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../models/physio_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => profileAsync.whenData(
              (p) => _showEditSheet(context, ref, p),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) => RefreshIndicator(
          onRefresh: () => ref.refresh(profileProvider.future),
          child: _ProfileBody(
            profile: profile,
            onLogout: () => _logout(context, ref),
            onAvailability: () => context.push('/availability'),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(logoutProvider.notifier).logout();
    }
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, PhysioProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(profile: profile, ref: ref),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final PhysioProfile profile;
  final VoidCallback onLogout;
  final VoidCallback onAvailability;
  const _ProfileBody({
    required this.profile,
    required this.onLogout,
    required this.onAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AvatarCard(profile: profile),
        const SizedBox(height: 16),
        _VerificationBanner(status: profile.verificationStatus),
        const SizedBox(height: 16),
        _StatsRow(profile: profile),
        const SizedBox(height: 16),
        _InfoCard(profile: profile),
        const SizedBox(height: 16),
        _FeesCard(profile: profile),
        const SizedBox(height: 16),
        _SpecializationsCard(profile: profile),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onAvailability,
          icon: const Icon(Icons.schedule),
          label: const Text('Manage Availability'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.push('/earnings'),
          icon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryGreen),
          label: const Text('My Earnings', style: TextStyle(color: AppTheme.primaryGreen)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryGreen),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: AppTheme.errorRed),
          label: const Text('Logout', style: TextStyle(color: AppTheme.errorRed)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.errorRed),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final PhysioProfile profile;
  const _AvatarCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: profile.profilePhotoUrl != null
              ? NetworkImage(profile.profilePhotoUrl!) : null,
          child: profile.profilePhotoUrl == null
              ? Text(
                  (profile.name?.isNotEmpty == true ? profile.name![0] : 'D').toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Dr. ${profile.name ?? 'Physiotherapist'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text('+91 ${profile.phone}',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              Text(' ${profile.rating.toStringAsFixed(1)}  ·  ${profile.totalReviews} reviews',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  final String status;
  const _VerificationBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'approved') return const SizedBox.shrink();
    final (color, icon, msg) = switch (status) {
      'pending'  => (AppTheme.warningAmber, Icons.hourglass_empty, 'Verification pending — admin will review your documents.'),
      'rejected' => (AppTheme.errorRed, Icons.cancel_outlined, 'Verification rejected. Please contact support.'),
      _          => (AppTheme.textSecondary, Icons.info_outline, 'Verification status: $status'),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: color))),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PhysioProfile profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Stat('${profile.totalSessions}', 'Sessions', Icons.medical_services_outlined, AppTheme.primaryGreen),
      const SizedBox(width: 12),
      _Stat('${profile.experienceYears}y', 'Experience', Icons.workspace_premium_outlined, AppTheme.accentBlue),
      const SizedBox(width: 12),
      _Stat('${profile.totalReviews}', 'Reviews', Icons.rate_review_outlined, Colors.orange),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _Stat(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final PhysioProfile profile;
  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) => _Card(title: 'Professional Info', rows: [
    _Row('Name',        profile.name ?? '—'),
    _Row('Email',       profile.email ?? '—'),
    _Row('Reg. No.',    profile.registrationNumber ?? '—'),
    _Row('Experience',  '${profile.experienceYears} years'),
    if (profile.bio != null && profile.bio!.isNotEmpty)
      _Row('Bio', profile.bio!),
  ]);
}

class _FeesCard extends StatelessWidget {
  final PhysioProfile profile;
  const _FeesCard({required this.profile});

  @override
  Widget build(BuildContext context) => _Card(title: 'Consultation Fees', rows: [
    _Row('Video Consult', '₹${profile.consultationFee.toStringAsFixed(0)}'),
    _Row('Home Visit',    '₹${profile.homeVisitFee.toStringAsFixed(0)}'),
  ]);
}

class _SpecializationsCard extends StatelessWidget {
  final PhysioProfile profile;
  const _SpecializationsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Specializations',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profile.specializations.isEmpty
              ? [const Text('—', style: TextStyle(color: AppTheme.textSecondary))]
              : profile.specializations.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
                )).toList(),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _Card({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 12),
      ...rows,
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
      ],
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final PhysioProfile profile;
  final WidgetRef ref;
  const _EditProfileSheet({required this.profile, required this.ref});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _expCtrl;
  late final TextEditingController _consultCtrl;
  late final TextEditingController _homeCtrl;
  late final TextEditingController _regCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl    = TextEditingController(text: p.name ?? '');
    _emailCtrl   = TextEditingController(text: p.email ?? '');
    _bioCtrl     = TextEditingController(text: p.bio ?? '');
    _expCtrl     = TextEditingController(text: p.experienceYears.toString());
    _consultCtrl = TextEditingController(text: p.consultationFee.toStringAsFixed(0));
    _homeCtrl    = TextEditingController(text: p.homeVisitFee.toStringAsFixed(0));
    _regCtrl     = TextEditingController(text: p.registrationNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _bioCtrl.dispose();
    _expCtrl.dispose(); _consultCtrl.dispose(); _homeCtrl.dispose();
    _regCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.ref.read(profileUpdateProvider.notifier).update({
        if (_nameCtrl.text.isNotEmpty)    'name':               _nameCtrl.text,
        if (_emailCtrl.text.isNotEmpty)   'email':              _emailCtrl.text,
        if (_bioCtrl.text.isNotEmpty)     'bio':                _bioCtrl.text,
        if (_expCtrl.text.isNotEmpty)     'experience_years':   int.tryParse(_expCtrl.text) ?? 0,
        if (_consultCtrl.text.isNotEmpty) 'consultation_fee':   double.tryParse(_consultCtrl.text) ?? 0,
        if (_homeCtrl.text.isNotEmpty)    'home_visit_fee':     double.tryParse(_homeCtrl.text) ?? 0,
        if (_regCtrl.text.isNotEmpty)     'registration_number':_regCtrl.text,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(children: [
              _field('Full Name', _nameCtrl),
              _field('Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
              _field('Bio', _bioCtrl, maxLines: 3),
              _field('Years of Experience', _expCtrl, keyboardType: TextInputType.number),
              _field('Video Consult Fee (₹)', _consultCtrl, keyboardType: TextInputType.number),
              _field('Home Visit Fee (₹)', _homeCtrl, keyboardType: TextInputType.number),
              _field('Registration Number', _regCtrl),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
