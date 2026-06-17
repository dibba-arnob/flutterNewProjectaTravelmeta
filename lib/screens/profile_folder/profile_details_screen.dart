import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ─── Enum mirrors (match Supabase enum values exactly) ───────────────────────

enum GenderT { male, female, other, prefer_not_to_say }

extension _GenderX on GenderT {
  String get dbValue => name;
  String get label {
    switch (this) {
      case GenderT.male:            return 'Male';
      case GenderT.female:          return 'Female';
      case GenderT.other:           return 'Other';
      case GenderT.prefer_not_to_say: return 'Prefer not to say';
    }
  }
  static GenderT? parse(String? v) {
    if (v == null) return null;
    for (final e in GenderT.values) { if (e.name == v) return e; }
    return null;
  }
}

enum KycStatusT { unverified, pending, verified, failed }

extension _KycX on KycStatusT {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
  Color get color {
    switch (this) {
      case KycStatusT.verified:   return AppColors.success;
      case KycStatusT.pending:    return AppColors.warning;
      case KycStatusT.failed:     return AppColors.error;
      case KycStatusT.unverified: return AppColors.textMuted;
    }
  }
  IconData get icon {
    switch (this) {
      case KycStatusT.verified: return Icons.verified_rounded;
      case KycStatusT.pending:  return Icons.hourglass_top_rounded;
      case KycStatusT.failed:   return Icons.cancel_outlined;
      case KycStatusT.unverified: return Icons.shield_outlined;
    }
  }
  static KycStatusT parse(String? v) {
    for (final e in KycStatusT.values) { if (e.name == v) return e; }
    return KycStatusT.unverified;
  }
}

enum LoyaltyTierT { bronze, silver, gold, platinum }

extension _LoyaltyX on LoyaltyTierT {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
  Color get color {
    switch (this) {
      case LoyaltyTierT.bronze:   return const Color(0xFF92400E);
      case LoyaltyTierT.silver:   return const Color(0xFF64748B);
      case LoyaltyTierT.gold:     return const Color(0xFFB45309);
      case LoyaltyTierT.platinum: return AppColors.secondary;
    }
  }
  static LoyaltyTierT parse(String? v) {
    for (final e in LoyaltyTierT.values) { if (e.name == v) return e; }
    return LoyaltyTierT.bronze;
  }
}

// ─── Profile Details Screen ──────────────────────────────────────────────────

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _State();
}

class _State extends State<ProfileDetailsScreen> {
  // ── status flags
  bool _loading = true;
  bool _saving  = false;
  bool _editing = false;
  String? _errorMsg;

  // ── read-only fields (never editable)
  String       _email         = '';
  KycStatusT   _kycStatus     = KycStatusT.unverified;
  LoyaltyTierT _loyaltyTier   = LoyaltyTierT.bronze;
  int          _loyaltyPoints = 0;
  bool         _isGuide       = false;
  DateTime?    _createdAt;
  String?      _avatarUrl;  // resolved from storage path

  // ── editable fields — controllers
  final _cName        = TextEditingController();
  final _cUsername    = TextEditingController();
  final _cPhone       = TextEditingController();
  final _cNationality = TextEditingController();
  final _cHomeCountry = TextEditingController();
  final _cBio         = TextEditingController();

  // ── editable fields — special types
  DateTime? _dob;
  GenderT?  _gender;

  // ── snapshot for cancel-revert
  late Map<String, dynamic> _snap;

  final _formKey = GlobalKey<FormState>();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _cName.dispose();
    _cUsername.dispose();
    _cPhone.dispose();
    _cNationality.dispose();
    _cHomeCountry.dispose();
    _cBio.dispose();
    super.dispose();
  }

  // ── fetch ─────────────────────────────────────────────────────────────────
  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() { _loading = true; _errorMsg = null; });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() { _loading = false; _errorMsg = 'Not logged in.'; });
      return;
    }
    _email = user.email ?? '';

    try {
      final Map<String, dynamic> row = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // ── populate editable controllers
      _cName.text        = (row['full_name']   as String?) ?? '';
      _cUsername.text    = (row['username']    as String?) ?? '';
      _cPhone.text       = (row['phone']       as String?) ?? '';
      _cNationality.text = (row['nationality'] as String?) ?? '';
      _cHomeCountry.text = (row['home_country']as String?) ?? '';
      _cBio.text         = (row['bio']         as String?) ?? '';
      _dob    = row['dob'] != null ? DateTime.tryParse(row['dob'] as String) : null;
      _gender = _GenderX.parse(row['gender'] as String?);

      // ── populate read-only fields
      _kycStatus     = _KycX.parse(row['kyc_status']     as String?);
      _loyaltyTier   = _LoyaltyX.parse(row['loyalty_tier'] as String?);
      _loyaltyPoints = (row['loyalty_points'] as int?) ?? 0;
      _isGuide       = (row['is_guide']       as bool?) ?? false;
      _createdAt     = row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null;

      // ── avatar: path → public URL
      final path = row['avatar_url'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          _avatarUrl = supabase.storage.from('avatars').getPublicUrl(path);
        } catch (_) {
          _avatarUrl = null;
        }
      } else {
        _avatarUrl = null;
      }

      _saveSnap();
    } catch (e) {
      _errorMsg = 'Could not load profile.\n$e\n\n'
          'Make sure the profiles table has RLS SELECT policy:\n'
          'USING (auth.uid() = id)';
    }

    if (mounted) setState(() => _loading = false);
  }

  // ── save / revert ─────────────────────────────────────────────────────────
  void _saveSnap() {
    _snap = {
      'name':        _cName.text,
      'username':    _cUsername.text,
      'phone':       _cPhone.text,
      'nationality': _cNationality.text,
      'home_country':_cHomeCountry.text,
      'bio':         _cBio.text,
      'dob':         _dob,
      'gender':      _gender,
    };
  }

  void _revert() {
    _cName.text        = (_snap['name']         as String?) ?? '';
    _cUsername.text    = (_snap['username']     as String?) ?? '';
    _cPhone.text       = (_snap['phone']        as String?) ?? '';
    _cNationality.text = (_snap['nationality']  as String?) ?? '';
    _cHomeCountry.text = (_snap['home_country'] as String?) ?? '';
    _cBio.text         = (_snap['bio']          as String?) ?? '';
    _dob               = _snap['dob']    as DateTime?;
    _gender            = _snap['gender'] as GenderT?;
    setState(() {});
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await supabase.from('profiles').update({
        'full_name':    _cName.text.trim().isEmpty       ? null : _cName.text.trim(),
        'username':     _cUsername.text.trim().isEmpty   ? null : _cUsername.text.trim(),
        'phone':        _cPhone.text.trim().isEmpty      ? null : _cPhone.text.trim(),
        'nationality':  _cNationality.text.trim().isEmpty? null : _cNationality.text.trim().toUpperCase(),
        'home_country': _cHomeCountry.text.trim().isEmpty? null : _cHomeCountry.text.trim(),
        'bio':          _cBio.text.trim().isEmpty        ? null : _cBio.text.trim(),
        'dob':          _dob != null
            ? '${_dob!.year}-${_dob!.month.toString().padLeft(2,'0')}-${_dob!.day.toString().padLeft(2,'0')}'
            : null,
        'gender':       _gender?.dbValue,
        'updated_at':   DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);

      _saveSnap();
      if (mounted) setState(() { _editing = false; _saving = false; });
      _toast('Profile saved successfully!');
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      final msg = e.toString();
      if (msg.contains('profiles_username_key') || msg.contains('unique')) {
        _toast('That username is already taken.', error: true);
      } else {
        _toast('Save failed: $e', error: true);
      }
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTextStyles.bodySm.copyWith(color: Colors.white)),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}/'
           '${dt.month.toString().padLeft(2,'0')}/'
           '${dt.year}';
  }

  String get _initials {
    final n = _cName.text.trim();
    if (n.isNotEmpty) {
      final p = n.split(' ').where((w) => w.isNotEmpty).toList();
      if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
      return p[0][0].toUpperCase();
    }
    return _email.isNotEmpty ? _email[0].toUpperCase() : '?';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.secondary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Profile Details',
            style: AppTextStyles.h6.copyWith(color: Colors.white)),
        actions: _actions(),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                strokeWidth: 2.5,
              ),
            )
          : _errorMsg != null
              ? _errorBody()
              : _body(),
    );
  }

  // ── error state ──────────────────────────────────────────────────────────
  Widget _errorBody() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Failed to load profile',
                  style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(_errorMsg ?? '',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );

  // ── main body ────────────────────────────────────────────────────────────
  Widget _body() => RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.secondary,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              children: [
                _avatarHeader(),
                const SizedBox(height: 28),
                _personalCard(),
                const SizedBox(height: 16),
                _locationCard(),
                const SizedBox(height: 16),
                _bioCard(),
                const SizedBox(height: 16),
                _accountCard(),
              ],
            ),
          ),
        ),
      );

  // ── appbar actions ───────────────────────────────────────────────────────
  List<Widget> _actions() {
    if (_loading || _errorMsg != null) return [];
    if (_saving) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          ),
        ),
      ];
    }
    if (_editing) {
      return [
        TextButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
          label: Text('Save', style: AppTextStyles.btn.copyWith(color: Colors.white)),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
          onPressed: () { _revert(); setState(() => _editing = false); },
          tooltip: 'Cancel',
        ),
      ];
    }
    return [
      TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
        label: Text('Edit', style: AppTextStyles.btn.copyWith(color: Colors.white)),
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SECTION WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  // ── avatar header ─────────────────────────────────────────────────────────
  Widget _avatarHeader() {
    return Column(
      children: [
        // circle avatar
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _avatarUrl == null
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: _avatarUrl != null ? AppColors.borderLight : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: _avatarUrl != null
                ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsBox())
                : _initialsBox(),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          _cName.text.isNotEmpty ? _cName.text : 'Traveler',
          style: AppTextStyles.h4.copyWith(color: AppColors.primary),
        ),

        if (_cUsername.text.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text('@${_cUsername.text}',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
        ],

        const SizedBox(height: 12),

        // status chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _Chip(label: _loyaltyTier.label, color: _loyaltyTier.color, icon: Icons.star_rounded),
            _Chip(label: '$_loyaltyPoints pts', color: AppColors.primary, icon: Icons.toll_rounded),
            _Chip(label: _kycStatus.label, color: _kycStatus.color, icon: _kycStatus.icon),
            if (_isGuide)
              const _Chip(label: 'Guide', color: AppColors.accent, icon: Icons.tour_rounded),
          ],
        ),
      ],
    );
  }

  Widget _initialsBox() => Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Text(
          _initials,
          style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      );

  // ── Personal Information card ─────────────────────────────────────────────
  Widget _personalCard() {
    return _Card(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      color: AppColors.secondary,
      children: [
        _field(
          label: 'Full Name',
          icon: Icons.badge_outlined,
          ctrl: _cName,
          hint: 'Enter your full name',
          keyboardType: TextInputType.name,
          validator: (v) => v != null && v.isNotEmpty && v.trim().length < 2
              ? 'At least 2 characters' : null,
        ),
        _divider(),
        _field(
          label: 'Username',
          icon: Icons.alternate_email_rounded,
          ctrl: _cUsername,
          hint: 'your_handle',
          prefix: '@',
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (v.trim().length < 3) return 'At least 3 characters';
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
              return 'Letters, numbers and _ only';
            }
            return null;
          },
        ),
        _divider(),
        _field(
          label: 'Phone',
          icon: Icons.phone_outlined,
          ctrl: _cPhone,
          hint: '+8801XXXXXXXXX',
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (!RegExp(r'^\+?[0-9\s\-()]{6,20}$').hasMatch(v.trim())) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
        _divider(),

        // Gender — dropdown or display
        if (_editing)
          _Dropdown<GenderT>(
            label: 'Gender',
            icon: Icons.wc_rounded,
            value: _gender,
            items: GenderT.values,
            labelFor: (g) => g.label,
            onChanged: (g) => setState(() => _gender = g),
          )
        else
          _Display(
            label: 'Gender',
            icon: Icons.wc_rounded,
            value: _gender?.label ?? '—',
          ),

        _divider(),

        // Date of Birth — date picker or display
        if (_editing)
          _DateTile(
            label: 'Date of Birth',
            icon: Icons.cake_outlined,
            value: _fmt(_dob),
            placeholder: 'Tap to select',
            onTap: _pickDob,
          )
        else
          _Display(
            label: 'Date of Birth',
            icon: Icons.cake_outlined,
            value: _fmt(_dob),
          ),

        _divider(),

        // Loyalty Tier — always read-only
        _Display(
          label: 'Loyalty Tier',
          icon: Icons.star_outline_rounded,
          value: _loyaltyTier.label,
          valueColor: _loyaltyTier.color,
          locked: true,
        ),
        _divider(),

        // Loyalty Points — always read-only
        _Display(
          label: 'Loyalty Points',
          icon: Icons.toll_rounded,
          value: '$_loyaltyPoints pts',
          locked: true,
        ),
        _divider(),

        // Email — always read-only
        _Display(
          label: 'Email',
          icon: Icons.email_outlined,
          value: _email.isNotEmpty ? _email : '—',
          subtitle: 'Cannot be changed here',
          locked: true,
        ),
      ],
    );
  }

  // ── Location card ─────────────────────────────────────────────────────────
  Widget _locationCard() {
    return _Card(
      title: 'Location & Nationality',
      icon: Icons.public_rounded,
      color: AppColors.accent,
      children: [
        _field(
          label: 'Nationality',
          icon: Icons.flag_outlined,
          ctrl: _cNationality,
          hint: '2-letter code, e.g. BD',
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (v.trim().length != 2) return 'Use 2-letter ISO code e.g. BD, US';
            return null;
          },
        ),
        _divider(),
        _field(
          label: 'Home Country',
          icon: Icons.home_outlined,
          ctrl: _cHomeCountry,
          hint: 'e.g. Bangladesh',
        ),
      ],
    );
  }

  // ── Bio card ──────────────────────────────────────────────────────────────
  Widget _bioCard() {
    return _Card(
      title: 'About Me',
      icon: Icons.edit_note_rounded,
      color: AppColors.primary,
      children: [
        if (_editing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextFormField(
              controller: _cBio,
              maxLines: 4,
              maxLength: 300,
              style: AppTextStyles.body.copyWith(color: AppColors.textLight),
              decoration: _deco('Bio', Icons.edit_note_rounded,
                  hint: 'Tell the community about yourself...'),
              validator: (v) {
                if (v != null && v.trim().length > 300) return 'Max 300 characters';
                return null;
              },
            ),
          )
        else
          _Display(
            label: 'Bio',
            icon: Icons.edit_note_rounded,
            value: _cBio.text.isEmpty ? '—' : _cBio.text,
            multiline: true,
          ),
      ],
    );
  }

  // ── Account Status card ───────────────────────────────────────────────────
  Widget _accountCard() {
    return _Card(
      title: 'Account Status',
      icon: Icons.account_circle_outlined,
      color: AppColors.textMuted,
      children: [
        _Display(label: 'KYC Status',    icon: Icons.verified_user_outlined,
            value: _kycStatus.label, valueColor: _kycStatus.color, locked: true),
        _divider(),
        _Display(label: 'Guide Account', icon: Icons.tour_outlined,
            value: _isGuide ? 'Yes — you are a guide' : 'No', locked: true,
            valueColor: _isGuide ? AppColors.success : null),
        _divider(),
        _Display(label: 'Member Since',  icon: Icons.calendar_today_outlined,
            value: _fmt(_createdAt), locked: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FIELD HELPER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required String hint,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    if (_editing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: AppTextStyles.body.copyWith(color: AppColors.textLight),
          validator: validator,
          decoration: _deco(label, icon, hint: hint, prefixText: prefix),
        ),
      );
    }
    // view mode
    String v = ctrl.text;
    if (prefix != null && v.isNotEmpty) v = '$prefix$v';
    return _Display(label: label, icon: icon, value: v.isEmpty ? '—' : v);
  }

  Widget _divider() => const Divider(
      height: 1, indent: 16, endIndent: 16, color: AppColors.borderLight);

  InputDecoration _deco(String label, IconData icon,
      {String? hint, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: Icon(icon, size: 18, color: AppColors.secondary),
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.secondary),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8)),
    );
  }
}

// ─── Reusable widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 10),
                Text(title, style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16, color: AppColors.borderLight),
          ...children,
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Read-only display row ─────────────────────────────────────────────────────

class _Display extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final bool multiline;
  final bool locked;

  const _Display({
    required this.label,
    required this.icon,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.multiline = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted, fontSize: 11)),
                    if (locked) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_outline_rounded,
                          size: 10, color: AppColors.textMuted),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontSize: 14,
                    color: isEmpty
                        ? AppColors.textMuted
                        : (valueColor ?? AppColors.textLight),
                    fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) labelFor;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        hint: Text('Select', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(labelFor(e),
              style: AppTextStyles.body.copyWith(color: AppColors.textLight)),
        )).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppColors.secondary),
          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.secondary),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 1.8)),
        ),
      ),
    );
  }
}

// ── Tap-to-pick date field ────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String placeholder;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—' || value.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 18, color: AppColors.secondary),
            suffixIcon: const Icon(Icons.calendar_month_outlined,
                size: 18, color: AppColors.textMuted),
            labelStyle: AppTextStyles.caption.copyWith(color: AppColors.secondary),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondary, width: 1.8)),
          ),
          child: Text(
            isEmpty ? placeholder : value,
            style: AppTextStyles.body.copyWith(
              color: isEmpty ? AppColors.textMuted : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Chip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.labelSm.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
