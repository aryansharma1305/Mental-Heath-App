import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class DoctorSetupScreen extends StatefulWidget {
  const DoctorSetupScreen({super.key});

  @override
  State<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends State<DoctorSetupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _registrationController = TextEditingController();
  String _designation = 'Resident Doctor';
  bool _isLoading = false;
  late AnimationController _pulseController;

  final List<String> _designations = [
    'Resident Doctor',
    'Senior Resident',
    'Consultant',
    'Psychiatrist',
    'Senior Consultant',
    'HOD',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _hospitalController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = 'DOC_${DateTime.now().millisecondsSinceEpoch}';
      final doctorData = {
        'doctor_id': doctorId,
        'name': _nameController.text.trim(),
        'designation': _designation,
        'department': _departmentController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'registration_number': _registrationController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('doctor_profile', jsonEncode(doctorData));
      await prefs.setBool('doctor_setup_complete', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildPrivacyNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3 + _pulseController.value * 0.2),
                    blurRadius: 25 + _pulseController.value * 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ).createShader(bounds),
                child: const Icon(Icons.medical_services_outlined, size: 50, color: Colors.white),
              ),
            );
          },
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text('Welcome, Doctor', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
          .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text('Set up your profile to get started', style: GoogleFonts.inter(fontSize: 15, color: Colors.white70))
          .animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Full Name *'),
          const SizedBox(height: 8),
          _buildTextField(_nameController, 'Dr. John Smith', Icons.person_outline, true),
          const SizedBox(height: 18),
          
          _buildLabel('Designation *'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(14)),
            child: DropdownButtonFormField<String>(
              value: _designation,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _designations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _designation = v!),
            ),
          ),
          const SizedBox(height: 18),
          
          _buildLabel('Department'),
          const SizedBox(height: 8),
          _buildTextField(_departmentController, 'Psychiatry', Icons.local_hospital_outlined, false),
          const SizedBox(height: 18),
          
          _buildLabel('Hospital / Institution'),
          const SizedBox(height: 8),
          _buildTextField(_hospitalController, 'City General Hospital', Icons.business_outlined, false),
          const SizedBox(height: 18),
          
          _buildLabel('Registration Number'),
          const SizedBox(height: 8),
          _buildTextField(_registrationController, 'MCI/State Medical Council No.', Icons.numbers_outlined, false),
          const SizedBox(height: 28),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 5,
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get Started', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 13));
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool required) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textGrey),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.errorRed)),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Your data is stored securely on this device', style: GoogleFonts.inter(fontSize: 12, color: Colors.white))),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
