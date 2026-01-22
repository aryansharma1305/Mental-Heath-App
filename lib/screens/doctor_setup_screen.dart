import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import 'assessment_home_screen.dart';

class DoctorSetupScreen extends StatefulWidget {
  const DoctorSetupScreen({super.key});

  @override
  State<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends State<DoctorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _registrationController = TextEditingController();
  String _designation = 'Resident Doctor';
  bool _isLoading = false;

  final List<String> _designations = [
    'Resident Doctor',
    'Senior Resident',
    'Consultant',
    'Psychiatrist',
    'Senior Consultant',
    'HOD',
  ];

  @override
  void dispose() {
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
      
      final doctorData = {
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
          MaterialPageRoute(builder: (context) => const AssessmentHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 24),
                
                Center(
                  child: Text(
                    'Welcome, Doctor',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                Center(
                  child: Text(
                    'Set up your profile to get started',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 40),
                
                // Full Name
                _buildLabel('Full Name *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    hint: 'Dr. John Smith',
                    icon: Icons.person_outline,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Designation
                _buildLabel('Designation *'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _designation,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _designations.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _designation = value!);
                    },
                  ),
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Department
                _buildLabel('Department'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _departmentController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration(
                    hint: 'Psychiatry',
                    icon: Icons.local_hospital_outlined,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Hospital
                _buildLabel('Hospital / Institution'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hospitalController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration(
                    hint: 'City General Hospital',
                    icon: Icons.business_outlined,
                  ),
                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Registration Number
                _buildLabel('Registration Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registrationController,
                  decoration: _buildInputDecoration(
                    hint: 'MCI/State Medical Council No.',
                    icon: Icons.numbers_outlined,
                  ),
                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 40),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 900.ms).scale(),
                
                const SizedBox(height: 20),
                
                // Privacy note
                Center(
                  child: Text(
                    'Your data is stored locally on this device',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.errorRed),
      ),
    );
  }
}
