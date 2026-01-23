import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SimpleSplashScreen extends StatefulWidget {
  const SimpleSplashScreen({super.key});

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    
    // Check if user is already authenticated
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isAuthenticated ? const HomeScreen() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background orbs
            _buildAnimatedOrbs(),
            
            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    
                    // Animated Logo
                    _buildAnimatedLogo(),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'DSM-5',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ).animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                    
                    Text(
                      'Cross-Cutting Measure',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 3,
                      ),
                    ).animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Professional Psychiatric Assessment',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                    
                    const Spacer(flex: 2),
                    
                    // Loading indicator
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 4,
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: 900.ms)
                      .shimmer(duration: 1500.ms, delay: 1000.ms),
                    
                    const SizedBox(height: 60),
                    
                    // Copyright
                    Text(
                      '© 2026 Mental Health Assessment Suite',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedOrbs() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Positioned(
              top: -100 + (50 * _breatheController.value),
              right: -100 + (30 * _rotateController.value),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _breatheController,
          builder: (context, child) {
            return Positioned(
              bottom: -150 + (40 * _breatheController.value),
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        return Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3 + (_breatheController.value * 0.2)),
                blurRadius: 30 + (_breatheController.value * 20),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Brain icon with gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              // Pulse effect
              AnimatedBuilder(
                animation: _breatheController,
                builder: (context, child) {
                  return Container(
                    width: 130 - (_breatheController.value * 10),
                    height: 130 - (_breatheController.value * 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: const Color(0xFF667eea).withOpacity(0.3 - (_breatheController.value * 0.2)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    ).animate()
      .scale(duration: 800.ms, curve: Curves.easeOutBack)
      .fadeIn(duration: 600.ms);
  }
}
