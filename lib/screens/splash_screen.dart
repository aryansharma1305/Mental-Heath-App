import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for minimum splash duration
    await Future.delayed(const Duration(seconds: 2));
    
    // Check authentication
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isAuthenticated ? const HomeScreen() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.lightBlue,
              AppTheme.lightBlue.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(flex: 2),
              
              // Logo and Icon Animation
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: screenWidth * 0.3,
                        height: screenWidth * 0.3,
                        constraints: const BoxConstraints(
                          minWidth: 100,
                          maxWidth: 150,
                          minHeight: 100,
                          maxHeight: 150,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology,
                          size: 70,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: screenHeight * 0.04),
              
              // App Title with Animation
              Text(
                'MindCare',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth < 400 ? 36 : 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.3, end: 0)
                  .then()
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
              
              const SizedBox(height: 12),
              
              Text(
                'Mental Capacity Assessment',
                style: GoogleFonts.inter(
                  fontSize: screenWidth < 400 ? 15 : 17,
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
              
              SizedBox(height: screenHeight * 0.08),
              
              // Loading Animation with enhanced design
              Container(
                width: screenWidth * 0.6,
                constraints: const BoxConstraints(maxWidth: 250),
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                        .slideX(
                          duration: 2000.ms,
                          begin: -1,
                          end: 1,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Initializing Healthcare Platform...',
                style: GoogleFonts.inter(
                  fontSize: screenWidth < 400 ? 13 : 15,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                ),
              ).animate()
                  .fadeIn(delay: 800.ms),
              
              const Spacer(flex: 3),
              
              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    Text(
                      'Professional Healthcare Solution',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'v1.0.0 • Secure & Compliant',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1200.ms),
            ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}