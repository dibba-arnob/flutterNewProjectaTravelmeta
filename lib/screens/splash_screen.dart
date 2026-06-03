import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late AnimationController _loadingController;
  late Animation<double> _contentFade;
  late Animation<double> _contentSlide;
  late Animation<double> _loadingFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A2B3A),
    ));

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<double>(begin: 28.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _loadingFade = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeIn,
    );

    _contentController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _loadingController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3200), _navigateToLogin);
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2B3A),
      body: GestureDetector(
        onTap: _navigateToLogin,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CoastalBackground(),
            _DarkOverlay(),
            _buildContent(),
            _buildLoadingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (_, _) => Opacity(
        opacity: _contentFade.value,
        child: Transform.translate(
          offset: Offset(0, _contentSlide.value),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AppIconWidget(),
                const SizedBox(height: 28),
                Text(
                  'TravelMeta',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Beyond Boundaries',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.70),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _loadingFade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'INITIALIZING EXPERIENCE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 3.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoastalBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7B9EB8), // cloudy sky
            Color(0xFF6A8DA8), // sky midtone
            Color(0xFF4F7D93), // lower sky
            Color(0xFF3A6B7C), // horizon
            Color(0xFF1E5063), // water surface
            Color(0xFF123E50), // deep water
            Color(0xFF0A2B3A), // foreground
          ],
          stops: [0.0, 0.18, 0.35, 0.47, 0.62, 0.80, 1.0],
        ),
      ),
    );
  }
}

class _DarkOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x1A000000),
            Color(0x33000000),
            Color(0x6B000000),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _AppIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.explore_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
      ),
    );
  }
}
