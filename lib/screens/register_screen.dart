import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // text controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportController = TextEditingController();
  final _ageController = TextEditingController();

  // selections
  String? _country;
  String? _gender;
  String? _bloodGroup;

  bool _loading = false;

  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ─── Auth action (wire Supabase here) ──────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _showError('Please select your gender.');
      return;
    }
    if (_country == null) {
      _showError('Please select your country.');
      return;
    }
    if (_bloodGroup == null) {
      _showError('Please select your blood group.');
      return;
    }

    setState(() => _loading = true);
    try {
      // SUPABASE SIGN-UP
      // ──────────────────────────────────────────────────────────────────
      // final res = await Supabase.instance.client.auth.signUp(
      //   email: _emailController.text.trim(),
      //   password: 'generated-or-user-provided',   // add a password field if needed
      //   data: {
      //     'full_name':    _nameController.text.trim(),
      //     'phone':        _phoneController.text.trim(),
      //     'passport_id':  _passportController.text.trim(),
      //     'country':      _country,
      //     'gender':       _gender,
      //     'age':          int.tryParse(_ageController.text) ?? 0,
      //     'blood_group':  _bloodGroup,
      //   },
      // );
      // ──────────────────────────────────────────────────────────────────

      await Future.delayed(const Duration(milliseconds: 1400)); // remove later
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2B3A),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),
          const _Overlay(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildForm(),
                            const SizedBox(height: 28),
                            _buildSignInRow(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'TravelMeta',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start your global journey today.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.58),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── Full form card ────────────────────────────────────────────────────────

  Widget _buildForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Personal Info ──────────────────────────
                _sectionLabel('Personal Info'),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  type: TextInputType.name,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _ageController,
                        hint: 'Age',
                        icon: Icons.cake_outlined,
                        type: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _MaxValueFormatter(120),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = int.tryParse(v);
                          if (n == null || n < 1 || n > 120) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGenderField()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBloodGroupField(),

                const SizedBox(height: 20),
                _dividerLine(),
                const SizedBox(height: 16),

                // ── Contact ────────────────────────────────
                _sectionLabel('Contact'),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  hint: 'Phone Number',
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter phone number' : null,
                ),

                const SizedBox(height: 20),
                _dividerLine(),
                const SizedBox(height: 16),

                // ── Travel Document ────────────────────────
                _sectionLabel('Travel Document'),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _passportController,
                  hint: 'Passport ID',
                  icon: Icons.badge_outlined,
                  type: TextInputType.text,
                  capitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter passport ID' : null,
                ),
                const SizedBox(height: 12),
                _buildCountryField(),

                const SizedBox(height: 24),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.accent,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _dividerLine() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.12),
      thickness: 0.6,
    );
  }

  // ─── Generic text field ────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType type,
    required String? Function(String?) validator,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      cursorColor: AppColors.accent,
      decoration: _dec(hint, icon),
      validator: validator,
    );
  }

  // ─── Gender selector ───────────────────────────────────────────────────────

  Widget _buildGenderField() {
    return GestureDetector(
      onTap: _pickGender,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _gender != null
                ? AppColors.accent.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.14),
            width: _gender != null ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _genderIcon(_gender),
              color: _gender != null
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.40),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _gender ?? 'Gender',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _gender != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded,
                color: Colors.white.withValues(alpha: 0.35), size: 18),
          ],
        ),
      ),
    );
  }

  IconData _genderIcon(String? g) {
    switch (g) {
      case 'Male':
        return Icons.male_rounded;
      case 'Female':
        return Icons.female_rounded;
      default:
        return Icons.people_outline_rounded;
    }
  }

  void _pickGender() {
    _showPickerSheet(
      title: 'Select Gender',
      items: const ['Male', 'Female', 'Non-binary', 'Prefer not to say'],
      selected: _gender,
      onSelect: (v) => setState(() => _gender = v),
    );
  }

  // ─── Blood group selector ──────────────────────────────────────────────────

  Widget _buildBloodGroupField() {
    const groups = ['A+', 'A−', 'B+', 'B−', 'O+', 'O−', 'AB+', 'AB−'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bloodtype_outlined,
                color: Colors.white.withValues(alpha: 0.40), size: 16),
            const SizedBox(width: 6),
            Text(
              'Blood Group',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups
              .map((g) => _BloodChip(
                    label: g,
                    selected: _bloodGroup == g,
                    onTap: () => setState(() => _bloodGroup = g),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ─── Country picker ────────────────────────────────────────────────────────

  Widget _buildCountryField() {
    return GestureDetector(
      onTap: _pickCountry,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _country != null
                ? AppColors.accent.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.14),
            width: _country != null ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.public_rounded,
              color: _country != null
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.40),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _country ?? 'Select Country',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _country != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded,
                color: Colors.white.withValues(alpha: 0.35), size: 18),
          ],
        ),
      ),
    );
  }

  void _pickCountry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountrySheet(
        selected: _country,
        onSelect: (c) => setState(() => _country = c),
      ),
    );
  }

  void _showPickerSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePickerSheet(
        title: title,
        items: items,
        selected: selected,
        onSelect: onSelect,
      ),
    );
  }

  // ─── Register button ───────────────────────────────────────────────────────

  Widget _buildRegisterButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2540), Color(0xFF0891B2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading ? null : _register,
          splashColor: Colors.white.withValues(alpha: 0.10),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Create Account',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Sign-in row ───────────────────────────────────────────────────────────

  Widget _buildSignInRow() {
    return Center(
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.50),
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared field decoration ───────────────────────────────────────────────

  InputDecoration _dec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.35),
      ),
      prefixIcon:
          Icon(icon, color: Colors.white.withValues(alpha: 0.40), size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
    );
  }
}

// ─── Blood group chip ─────────────────────────────────────────────────────────

class _BloodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BloodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.14),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.60),
          ),
        ),
      ),
    );
  }
}

// ─── Simple picker bottom sheet (gender) ──────────────────────────────────────

class _SimplePickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String? selected;
  final void Function(String) onSelect;

  const _SimplePickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A2B3A).withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((item) => _PickerRow(
                    label: item,
                    selected: item == selected,
                    onTap: () {
                      onSelect(item);
                      Navigator.pop(context);
                    },
                  )),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: selected ? AppColors.accent : Colors.white,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Country picker bottom sheet ──────────────────────────────────────────────

class _CountrySheet extends StatefulWidget {
  final String? selected;
  final void Function(String) onSelect;

  const _CountrySheet({required this.selected, required this.onSelect});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _search = TextEditingController();
  late List<String> _filtered;

  static const _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Armenia', 'Australia',
    'Austria', 'Azerbaijan', 'Bahrain', 'Bangladesh', 'Belarus', 'Belgium',
    'Bolivia', 'Bosnia and Herzegovina', 'Brazil', 'Bulgaria', 'Cambodia',
    'Canada', 'Chile', 'China', 'Colombia', 'Croatia', 'Cuba', 'Cyprus',
    'Czech Republic', 'Denmark', 'Dominican Republic', 'Ecuador', 'Egypt',
    'Ethiopia', 'Finland', 'France', 'Georgia', 'Germany', 'Ghana', 'Greece',
    'Guatemala', 'Honduras', 'Hong Kong', 'Hungary', 'Iceland', 'India',
    'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica',
    'Japan', 'Jordan', 'Kazakhstan', 'Kenya', 'Kuwait', 'Kyrgyzstan', 'Laos',
    'Latvia', 'Lebanon', 'Libya', 'Lithuania', 'Luxembourg', 'Macau',
    'Malaysia', 'Maldives', 'Malta', 'Mexico', 'Moldova', 'Mongolia',
    'Morocco', 'Myanmar', 'Nepal', 'Netherlands', 'New Zealand', 'Nigeria',
    'North Korea', 'Norway', 'Oman', 'Pakistan', 'Palestine', 'Panama',
    'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar',
    'Romania', 'Russia', 'Saudi Arabia', 'Serbia', 'Singapore', 'Slovakia',
    'Slovenia', 'South Africa', 'South Korea', 'Spain', 'Sri Lanka', 'Sudan',
    'Sweden', 'Switzerland', 'Syria', 'Taiwan', 'Tajikistan', 'Tanzania',
    'Thailand', 'Tunisia', 'Turkey', 'Turkmenistan', 'Ukraine',
    'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay',
    'Uzbekistan', 'Venezuela', 'Vietnam', 'Yemen', 'Zimbabwe',
  ];

  @override
  void initState() {
    super.initState();
    _filtered = List.of(_countries);
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.of(_countries)
          : _countries
              .where((c) => c.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2B3A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Country',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _search,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.40), size: 20),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No results',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _PickerRow(
                          label: _filtered[i],
                          selected: _filtered[i] == widget.selected,
                          onTap: () {
                            widget.onSelect(_filtered[i]);
                            Navigator.pop(context);
                          },
                        ),
                      ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Input formatter: max numeric value ───────────────────────────────────────

class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  _MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    if (next.text.isEmpty) return next;
    final n = int.tryParse(next.text);
    if (n == null || n > max) return old;
    return next;
  }
}

// ─── Shared background widgets ────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7B9EB8),
            Color(0xFF6A8DA8),
            Color(0xFF4F7D93),
            Color(0xFF3A6B7C),
            Color(0xFF1E5063),
            Color(0xFF123E50),
            Color(0xFF0A2B3A),
          ],
          stops: [0.0, 0.18, 0.35, 0.47, 0.62, 0.80, 1.0],
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x1F000000),
            Color(0x47000000),
            Color(0x8C000000),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
