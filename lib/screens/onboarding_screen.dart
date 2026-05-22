import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../services/app_lock_service.dart';
import 'home_screen.dart';

// =============================================================================
// OnboardingScreen
//
// First-launch experience for new clinicians. Shown once; subsequent launches
// skip directly to HomeScreen (or LoginScreen if unauthenticated).
//
// Page flow:
//   0 — Welcome hero
//   1 — Privacy & security guarantees
//   2 — Clinician profile setup  ← REQUIRED: name + role before advancing
//   3 — App lock configuration   ← "Get Started" writes onboarding_complete
//
// SharedPreferences keys written:
//   'onboarding_complete' (bool)   — gates future launches
//   'doctor_setup_complete' (bool) — aligns with doctor_setup_screen contract
//   'doctor_profile' (JSON string) — { name, designation, hospital }
// =============================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _appLockService = AppLockService();

  // Page 2 form
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // App lock state (page 3)
  bool _lockEnabled = false;
  int _lockTimeoutSeconds = 60;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  Future<void> _loadExistingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('doctor_profile');
    if (raw != null && raw.isNotEmpty) {
      try {
        // doctor_profile is JSON — parse manually without dart:convert import conflict.
        // Quick manual field extraction from JSON string.
        final nameMatch = RegExp(r'"name"\s*:\s*"([^"]*)"').firstMatch(raw);
        final roleMatch =
            RegExp(r'"designation"\s*:\s*"([^"]*)"').firstMatch(raw);
        final hospMatch =
            RegExp(r'"hospital"\s*:\s*"([^"]*)"').firstMatch(raw);
        if (nameMatch != null) _nameController.text = nameMatch.group(1) ?? '';
        if (roleMatch != null) _roleController.text = roleMatch.group(1) ?? '';
        if (hospMatch != null) {
          _hospitalController.text = hospMatch.group(1) ?? '';
        }
      } catch (_) {}
    }
    final lockEnabled = await _appLockService.isLockEnabled();
    final timeout = await _appLockService.getLockTimeoutSeconds();
    if (mounted) {
      setState(() {
        _lockEnabled = lockEnabled;
        _lockTimeoutSeconds = timeout < 0 ? 60 : timeout;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  bool get _canAdvanceFromCurrentPage {
    if (_currentPage == 2) {
      return _nameController.text.trim().isNotEmpty &&
          _roleController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _goNext() {
    if (_currentPage == 2) {
      if (!_formKey.currentState!.validate()) return;
      _saveProfile();
    }
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skipToProfile() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    final hospital = _hospitalController.text.trim();
    // Store as lightweight JSON string matching doctor_setup_screen format.
    await prefs.setString(
      'doctor_profile',
      '{"name":"$name","designation":"$role","hospital":"$hospital","registration_number":""}',
    );
    await prefs.setBool('doctor_setup_complete', true);
  }

  Future<void> _finish() async {
    // Persist app lock preference.
    await _appLockService.setLockEnabled(_lockEnabled);
    if (_lockEnabled) {
      await _appLockService.setLockTimeoutSeconds(_lockTimeoutSeconds);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (_) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0C29),
        body: Stack(
          children: [
            // Background gradient
            _GradientBackground(page: _currentPage),

            // Pages
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _WelcomePage(onNext: _goNext, onSkip: _skipToProfile),
                _SecurityPage(onNext: _goNext, onSkip: _skipToProfile),
                _ProfilePage(
                  formKey: _formKey,
                  nameController: _nameController,
                  roleController: _roleController,
                  hospitalController: _hospitalController,
                  onChanged: () => setState(() {}),
                ),
                _AppLockPage(
                  lockEnabled: _lockEnabled,
                  lockTimeoutSeconds: _lockTimeoutSeconds,
                  onLockToggle: (v) async {
                    setState(() => _lockEnabled = v);
                  },
                  onTimeoutChanged: (v) => setState(
                    () => _lockTimeoutSeconds = v,
                  ),
                ),
              ],
            ),

            // Bottom bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomBar(
                currentPage: _currentPage,
                pageController: _pageController,
                canAdvance: _canAdvanceFromCurrentPage,
                onSkip: _skipToProfile,
                onNext: _goNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Background
// =============================================================================

class _GradientBackground extends StatelessWidget {
  final int page;
  const _GradientBackground({required this.page});

  static const _gradients = [
    [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D2137)],
    [Color(0xFF1A0533), Color(0xFF4A1060), Color(0xFF2D0B45)],
    [Color(0xFF0D1F12), Color(0xFF1A4B25), Color(0xFF0A1A0F)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[page.clamp(0, 3)];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

// =============================================================================
// Page 0 — Welcome
// =============================================================================

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const _WelcomePage({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Animated logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.04,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 48),

            Text(
              'Clinical assessment,\nwherever care happens.',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            Text(
              'Secure, offline-capable mental capacity assessments built for the ward — with full clinical governance from day one.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const Spacer(),

            // Feature chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _FeatureChip(icon: Icons.lock_outline, label: 'AES-256 Encrypted'),
                _FeatureChip(icon: Icons.wifi_off_rounded, label: 'Works Offline'),
                _FeatureChip(
                  icon: Icons.verified_outlined,
                  label: 'Audit-Ready PDFs',
                ),
                _FeatureChip(
                  icon: Icons.people_outline,
                  label: 'Multi-Clinician Sign-Off',
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms),

            const SizedBox(height: 120), // Space for bottom bar
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Page 1 — Security
// =============================================================================

class _SecurityPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const _SecurityPage({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            Text(
              'Your data stays\nprotected.',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 8),

            Text(
              'Built for clinical environments where data security is non-negotiable.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 40),

            _SecurityRow(
              icon: Icons.enhanced_encryption_rounded,
              color: const Color(0xFF667eea),
              title: 'AES-256 encrypted storage',
              subtitle:
                  'Every assessment is encrypted on-device. Data never leaves this device unencrypted.',
              delay: 300,
            ),
            const SizedBox(height: 20),
            _SecurityRow(
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF06D6A0),
              title: 'Tamper-proof audit trail',
              subtitle:
                  'Clinical scores are immutable once saved. Amendments are tracked with a full countersignature chain.',
              delay: 450,
            ),
            const SizedBox(height: 20),
            _SecurityRow(
              icon: Icons.fingerprint_rounded,
              color: const Color(0xFFFFD166),
              title: 'Biometric lock',
              subtitle:
                  'App locks automatically when you step away. Unauthorised access is blocked at the hardware level.',
              delay: 600,
            ),
            const SizedBox(height: 20),
            _SecurityRow(
              icon: Icons.cloud_off_rounded,
              color: const Color(0xFFEF476F),
              title: 'Fully offline capable',
              subtitle:
                  'Complete assessments, countersign, and export PDFs without any network connection.',
              delay: 750,
            ),

            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int delay;

  const _SecurityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 500.ms)
        .slideX(begin: 0.08, end: 0);
  }
}

// =============================================================================
// Page 2 — Clinician Profile
// =============================================================================

class _ProfilePage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController roleController;
  final TextEditingController hospitalController;
  final VoidCallback onChanged;

  const _ProfilePage({
    required this.formKey,
    required this.nameController,
    required this.roleController,
    required this.hospitalController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Text(
                'Tell us about\nyourself.',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 8),

              Text(
                'Your name and role appear on every assessment and PDF report.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              _OnboardingField(
                controller: nameController,
                label: 'Full name',
                hint: 'Dr. Jane Smith',
                icon: Icons.person_outline,
                required: true,
                onChanged: (_) => onChanged(),
                delay: 300,
              ),

              const SizedBox(height: 16),

              _OnboardingField(
                controller: roleController,
                label: 'Role / designation',
                hint: 'Consultant Psychiatrist',
                icon: Icons.badge_outlined,
                required: true,
                onChanged: (_) => onChanged(),
                delay: 400,
              ),

              const SizedBox(height: 16),

              _OnboardingField(
                controller: hospitalController,
                label: 'Hospital / trust',
                hint: 'Optional',
                icon: Icons.local_hospital_outlined,
                required: false,
                onChanged: (_) => onChanged(),
                delay: 500,
              ),

              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;
  final ValueChanged<String> onChanged;
  final int delay;

  const _OnboardingField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.required,
    required this.onChanged,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF476F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF476F), width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(
          color: const Color(0xFFEF476F),
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

// =============================================================================
// Page 3 — App Lock
// =============================================================================

class _AppLockPage extends StatelessWidget {
  final bool lockEnabled;
  final int lockTimeoutSeconds;
  final ValueChanged<bool> onLockToggle;
  final ValueChanged<int> onTimeoutChanged;

  const _AppLockPage({
    required this.lockEnabled,
    required this.lockTimeoutSeconds,
    required this.onLockToggle,
    required this.onTimeoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            Text(
              'Secure access\nbetween consultations.',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 8),

            Text(
              'The app locks automatically when you step away, blocking unauthorised access on shared devices.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 36),

            // Lock toggle card
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: lockEnabled
                          ? const Color(0xFF06D6A0).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lockEnabled
                            ? const Color(0xFF06D6A0).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        lockEnabled
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: lockEnabled
                            ? const Color(0xFF06D6A0)
                            : Colors.white.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Biometric lock',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Uses fingerprint or Face ID',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    value: lockEnabled,
                    onChanged: onLockToggle,
                    activeThumbColor: const Color(0xFF06D6A0),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            // Timeout selector — only when lock is on
            if (lockEnabled) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lock after',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _TimeoutChip(
                              label: '30 s',
                              value: 30,
                              selected: lockTimeoutSeconds == 30,
                              onTap: () => onTimeoutChanged(30),
                            ),
                            const SizedBox(width: 8),
                            _TimeoutChip(
                              label: '1 min',
                              value: 60,
                              selected: lockTimeoutSeconds == 60,
                              onTap: () => onTimeoutChanged(60),
                            ),
                            const SizedBox(width: 8),
                            _TimeoutChip(
                              label: '5 min',
                              value: 300,
                              selected: lockTimeoutSeconds == 300,
                              onTap: () => onTimeoutChanged(300),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ],

            const SizedBox(height: 20),

            // Skip hint
            Text(
              'You can change this any time in Settings.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}

class _TimeoutChip extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _TimeoutChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF667eea).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF667eea)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom Bar
// =============================================================================

class _BottomBar extends StatelessWidget {
  final int currentPage;
  final PageController pageController;
  final bool canAdvance;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _BottomBar({
    required this.currentPage,
    required this.pageController,
    required this.canAdvance,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == 3;
    final showSkip = currentPage < 2;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Skip button (hidden on pages 2 & 3)
              SizedBox(
                width: 72,
                child: showSkip
                    ? TextButton(
                        onPressed: onSkip,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null,
              ),

              // Dot indicator
              SmoothPageIndicator(
                controller: pageController,
                count: 4,
                effect: WormEffect(
                  dotWidth: 8,
                  dotHeight: 8,
                  activeDotColor: Colors.white,
                  dotColor: Colors.white.withValues(alpha: 0.25),
                  spacing: 6,
                ),
              ),

              // Next / Get Started
              SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: isLast
                      ? FilledButton(
                          onPressed: onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06D6A0),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Go!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: canAdvance ? onNext : null,
                          child: Text(
                            'Next',
                            style: GoogleFonts.inter(
                              color: canAdvance
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
