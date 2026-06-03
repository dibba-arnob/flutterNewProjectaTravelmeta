import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  int _tab = 0; // 0 = Email, 1 = Phone
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
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
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Auth actions (wire to Supabase here) ──────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_tab == 0) {
        // EMAIL LOGIN
        // ────────────────────────────────────────────────────────────────
        // final res = await Supabase.instance.client.auth.signInWithPassword(
        //   email: _emailController.text.trim(),
        //   password: _passwordController.text,
        // );
        // if (res.user == null) throw Exception('Login failed');
        // ────────────────────────────────────────────────────────────────
        await Future.delayed(const Duration(milliseconds: 1200)); // remove later
      } else {
        // PHONE OTP — Supabase sends an SMS code; navigate to OTP verify screen
        // ────────────────────────────────────────────────────────────────
        // await Supabase.instance.client.auth.signInWithOtp(
        //   phone: _phoneController.text.trim(),
        // );
        // if (mounted) Navigator.pushNamed(context, '/otp-verify');
        // ────────────────────────────────────────────────────────────────
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    // GOOGLE OAUTH
    // ────────────────────────────────────────────────────────────────
    // await Supabase.instance.client.auth.signInWithOAuth(
    //   OAuthProvider.google,
    //   redirectTo: 'io.supabase.travelmeta://login-callback',
    // );
    // ────────────────────────────────────────────────────────────────
  }

  Future<void> _forgotPassword() async {
    // PASSWORD RESET
    // ────────────────────────────────────────────────────────────────
    // await Supabase.instance.client.auth.resetPasswordForEmail(
    //   _emailController.text.trim(),
    //   redirectTo: 'io.supabase.travelmeta://reset-password',
    // );
    // ────────────────────────────────────────────────────────────────
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
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildCard(),
                            const SizedBox(height: 28),
                            _buildDivider(),
                            const SizedBox(height: 22),
                            _buildSocials(),
                            const SizedBox(height: 32),
                            _buildSignUpRow(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TravelMeta',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: Colors.white.withValues(alpha: 0.80),
                size: 18,
              ),
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
          'Welcome Back',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your global journey.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.60),
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ─── Glass card ────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTabs(),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _tab == 0
                      ? _buildField(
                          key: const ValueKey('email'),
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        )
                      : _buildField(
                          key: const ValueKey('phone'),
                          controller: _phoneController,
                          hint: 'Phone Number',
                          icon: Icons.phone_outlined,
                          type: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your phone number';
                            }
                            return null;
                          },
                        ),
                ),
                const SizedBox(height: 14),
                _buildPasswordField(),
                const SizedBox(height: 18),
                _buildForgotRow(),
                const SizedBox(height: 22),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Email / Phone tabs ────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TabPill(
            label: 'EMAIL',
            selected: _tab == 0,
            onTap: () => setState(() => _tab = 0),
          ),
          _TabPill(
            label: 'PHONE',
            selected: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
        ],
      ),
    );
  }

  // ─── Shared input field ────────────────────────────────────────────────────

  Widget _buildField({
    required Key key,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType type,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: type,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      cursorColor: AppColors.accent,
      decoration: _fieldDecoration(hint, icon),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscure,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      cursorColor: AppColors.accent,
      decoration: _fieldDecoration('Password', Icons.lock_outline_rounded).copyWith(
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white.withValues(alpha: 0.45),
            size: 20,
          ),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter your password';
        if (v.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.35),
      ),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.40), size: 20),
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

  // ─── Forgot / Biometric row ────────────────────────────────────────────────

  Widget _buildForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _forgotPassword,
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            // local_auth biometric + restore Supabase session
          },
          child: Row(
            children: [
              Icon(
                Icons.fingerprint_rounded,
                color: Colors.white.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Biometric',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Login button ──────────────────────────────────────────────────────────

  Widget _buildLoginButton() {
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
            color: AppColors.secondary.withValues(alpha: 0.30),
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
          onTap: _loading ? null : _login,
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
                    'Login',
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

  // ─── Divider ───────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.18),
            thickness: 0.8,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR CONTINUE WITH',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.40),
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.18),
            thickness: 0.8,
          ),
        ),
      ],
    );
  }

  // ─── Social buttons ────────────────────────────────────────────────────────

  Widget _buildSocials() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialBtn(
          onTap: _googleSignIn,
          child: const _GoogleIcon(),
        ),
        const SizedBox(width: 16),
        _SocialBtn(
          onTap: () {
            // Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.facebook)
          },
          child: const Icon(Icons.facebook_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        _SocialBtn(
          onTap: () {
            // Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.apple)
          },
          child: const Icon(Icons.apple_rounded, color: Colors.white, size: 26),
        ),
      ],
    );
  }

  // ─── Sign-up row ───────────────────────────────────────────────────────────

  Widget _buildSignUpRow() {
    return Center(
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.50),
          ),
          children: [
            const TextSpan(text: "Don't have an account? "),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                ),
                child: Text(
                  'Join TravelMeta',
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
}

// ─── Private sub-widgets ──────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: selected
                  ? const Color(0xFF0A2540)
                  : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SocialBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Simple "G" — replace with flutter_svg + Google's official SVG if preferred
    return Text(
      'G',
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

// ─── Background (shared coastal style with SplashScreen) ──────────────────────

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x1F000000), // 0.12 opacity black
            Color(0x47000000), // 0.28 opacity black
            Color(0x8C000000), // 0.55 opacity black
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
