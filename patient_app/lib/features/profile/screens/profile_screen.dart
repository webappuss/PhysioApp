import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../models/profile_model.dart';
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
          child: _ProfileBody(profile: profile, onLogout: () => _logout(context, ref)),
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

  void _showEditSheet(BuildContext context, WidgetRef ref, PatientProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(profile: profile, ref: ref),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final PatientProfile profile;
  final VoidCallback onLogout;
  const _ProfileBody({required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AvatarCard(profile: profile),
        const SizedBox(height: 20),
        _StatsRow(profile: profile),
        const SizedBox(height: 20),
        _QuickActions(),
        const SizedBox(height: 20),
        _InfoCard(profile: profile),
        const SizedBox(height: 20),
        _MedicalCard(profile: profile),
        const SizedBox(height: 28),
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
  final PatientProfile profile;
  const _AvatarCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF0A4DA0)],
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
              ? NetworkImage(profile.profilePhotoUrl!)
              : null,
          child: profile.profilePhotoUrl == null
              ? Text(
                  (profile.name?.isNotEmpty == true ? profile.name![0] : profile.phone[0])
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              profile.name ?? 'Patient',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              '+91 ${profile.phone}',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
            ),
            if (profile.email != null) ...[
              const SizedBox(height: 2),
              Text(profile.email!, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text('Lv.${profile.level}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Level', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8))),
          ]),
        ),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PatientProfile profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatTile(value: '${profile.streakDays}', label: 'Day Streak', icon: Icons.local_fire_department, color: Colors.orange),
      const SizedBox(width: 12),
      _StatTile(value: '${profile.totalXp}', label: 'Total XP', icon: Icons.star_rounded, color: AppTheme.primaryBlue),
      const SizedBox(width: 12),
      _StatTile(value: '${profile.totalSessions}', label: 'Sessions', icon: Icons.calendar_today, color: AppTheme.accentTeal),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.icon, required this.color});

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

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('My Health',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ),
          _ActionTile(
            icon: Icons.fitness_center_outlined,
            color: AppTheme.primaryBlue,
            label: 'Rehab Plans',
            subtitle: 'View your exercise programs',
            onTap: () => context.push('/rehab-plans'),
          ),
          _ActionTile(
            icon: Icons.bar_chart_outlined,
            color: const Color(0xFF7B61FF),
            label: 'Outcome Scores',
            subtitle: 'Track recovery progress',
            onTap: () => context.push('/scores'),
          ),
          _ActionTile(
            icon: Icons.checklist_outlined,
            color: AppTheme.accentTeal,
            label: 'Daily Check-in',
            subtitle: 'Log pain, mood & sleep',
            onTap: () => context.push('/checkin'),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  const _ActionTile({
    required this.icon, required this.color, required this.label,
    required this.subtitle, required this.onTap, this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 66, color: AppTheme.divider),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PatientProfile profile;
  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Personal Info',
      rows: [
        _item('Date of Birth', profile.dateOfBirth ?? '—'),
        _item('Gender', profile.gender?.capitalize() ?? '—'),
        _item('Blood Group', profile.bloodGroup ?? '—'),
        _item('Address', profile.address ?? '—'),
      ],
    );
  }

  _CardRow _item(String l, String v) => _CardRow(label: l, value: v);
}

class _MedicalCard extends StatelessWidget {
  final PatientProfile profile;
  const _MedicalCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Medical History',
      rows: [
        _CardRow(
          label: 'Notes',
          value: profile.medicalHistory?.isNotEmpty == true ? profile.medicalHistory! : 'None recorded',
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<_CardRow> rows;
  const _Card({required this.title, required this.rows});

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
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...rows,
      ]),
    );
  }
}

class _CardRow extends StatelessWidget {
  final String label, value;
  const _CardRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ),
      ],
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final PatientProfile profile;
  final WidgetRef ref;
  const _EditProfileSheet({required this.profile, required this.ref});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _bloodCtrl;
  late final TextEditingController _medCtrl;
  String? _gender;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl    = TextEditingController(text: p.name ?? '');
    _emailCtrl   = TextEditingController(text: p.email ?? '');
    _dobCtrl     = TextEditingController(text: p.dateOfBirth ?? '');
    _addressCtrl = TextEditingController(text: p.address ?? '');
    _bloodCtrl   = TextEditingController(text: p.bloodGroup ?? '');
    _medCtrl     = TextEditingController(text: p.medicalHistory ?? '');
    _gender      = p.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _dobCtrl.dispose();
    _addressCtrl.dispose(); _bloodCtrl.dispose(); _medCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.ref.read(profileUpdateProvider.notifier).update({
        if (_nameCtrl.text.isNotEmpty)    'name':             _nameCtrl.text,
        if (_emailCtrl.text.isNotEmpty)   'email':            _emailCtrl.text,
        if (_dobCtrl.text.isNotEmpty)     'date_of_birth':    _dobCtrl.text,
        if (_gender != null)              'gender':           _gender,
        if (_addressCtrl.text.isNotEmpty) 'address':          _addressCtrl.text,
        if (_bloodCtrl.text.isNotEmpty)   'blood_group':      _bloodCtrl.text,
        if (_medCtrl.text.isNotEmpty)     'medical_history':  _medCtrl.text,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(children: [
              _field('Full Name', _nameCtrl),
              _field('Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
              _field('Date of Birth (YYYY-MM-DD)', _dobCtrl),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male',   child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other',  child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 8),
              _field('Address', _addressCtrl, maxLines: 2),
              _field('Blood Group', _bloodCtrl),
              _field('Medical History', _medCtrl, maxLines: 3),
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

extension _StringX on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
