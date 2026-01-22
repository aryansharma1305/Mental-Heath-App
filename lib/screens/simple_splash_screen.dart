import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'assessment_home_screen.dart';
import 'doctor_setup_screen.dart';

class SimpleSplashScreen extends StatefulWidget {
  const SimpleSplashScreen({super.key});

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
    
    // Check doctor profile and navigate
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final isSetupComplete = prefs.getBool('doctor_setup_complete') ?? false;
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isSetupComplete 
                  ? const AssessmentHomeScreen()
                  : const DoctorSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.lavender,
              const Color(0xFF6B73FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Logo/Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ).animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
              
              const SizedBox(height: 40),
              
              // App Title
              Text(
                'Mental Capacity',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ).animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 300.ms),
              
              Text(
                'Assessment',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.95),
                  letterSpacing: 2,
                ),
              ).animate()
                .fadeIn(delay: 500.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 500.ms),
              
              const SizedBox(height: 16),
              
              // Tagline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Professional Assessment Tool',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ).animate()
                .fadeIn(delay: 700.ms, duration: 500.ms),
              
              const Spacer(flex: 2),
              
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ).animate()
                .fadeIn(delay: 900.ms, duration: 500.ms),
              
              const SizedBox(height: 16),
              
              Text(
                'Loading...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ).animate()
                .fadeIn(delay: 1000.ms, duration: 500.ms),
              
              const Spacer(),
              
              // Footer
              Text(
                'For Healthcare Professionals',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ).animate()
                .fadeIn(delay: 1200.ms, duration: 500.ms),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
