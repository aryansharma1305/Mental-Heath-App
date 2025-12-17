import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _departmentController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  final List<UserRole> _availableRoles = [
    UserRole.patient,
    UserRole.doctor,
    UserRole.psychiatrist,
    // Admin role removed - can only be added via database
  ];
  
  UserRole? _selectedRole;

  final List<String> _departments = [
    'Emergency Department',
    'Mental Health Unit',
    'Geriatrics',
    'Neurology',
    'Psychiatry',
    'General Medicine',
    'Surgery',
    'Intensive Care',
    'Rehabilitation',
    'Community Health',
  ];

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a role'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final result = await _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole!.name,
        department: _selectedRole!.isHealthcareProfessional 
            ? _departmentController.text 
            : null,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registration successful'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registration failed. Please try again.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      // Error should be handled by auth service, but show fallback message if needed
      debugPrint('❌ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.lightBlue,
              AppTheme.lightBlue.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ).animate().fadeIn(delay: 100.ms),
                
                const SizedBox(height: 20),
                
                // Logo and Title Section
                Container(
                  width: isSmallScreen ? 80 : 100,
                  height: isSmallScreen ? 80 : 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    size: 50,
                    color: AppTheme.primaryBlue,
                  ),
                ).animate().scale(delay: 200.ms, duration: 600.ms),
                
                const SizedBox(height: 24),
                
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 8),
                
                Text(
                  'Join our healthcare professional network',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Registration Form
                CustomCard(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Registration',
                          style: AppTheme.headingMedium,
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Full Name
                        CustomInputField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _fullNameController,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Username
                        CustomInputField(
                          label: 'Username/Staff ID',
                          hint: 'Enter your staff ID',
                          controller: _usernameController,
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Email
                        CustomInputField(
                          label: 'Email Address',
                          hint: 'Enter your email',
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password
                        CustomInputField(
                          label: 'Password',
                          hint: 'Enter a strong password',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onSuffixTap: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          validator: _validatePassword,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Confirm Password
                        CustomInputField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onSuffixTap: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Role Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Your Role',
                              style: AppTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<UserRole>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                hintText: 'Select your role',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              items: _availableRoles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(role.displayName),
                                      Text(
                                        role.description,
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select your role';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        
                        // Department (only for healthcare professionals)
                        if (_selectedRole != null && _selectedRole!.isHealthcareProfessional) ...[
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Department',
                                style: AppTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _departmentController.text.isEmpty
                                    ? null
                                    : _departmentController.text,
                                decoration: const InputDecoration(
                                  hintText: 'Select your department',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                items: _departments.map((dept) {
                                  return DropdownMenuItem(
                                    value: dept,
                                    child: Text(dept),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _departmentController.text = value ?? '';
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your department';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Terms and Conditions
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() => _acceptTerms = value ?? false);
                              },
                              activeColor: AppTheme.primaryBlue,
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the Terms and Conditions and Privacy Policy',
                                style: AppTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Register Button
                        CustomButton(
                          text: 'Create Account',
                          onPressed: _register,
                          isLoading: _isLoading,
                          icon: Icons.person_add,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Sign In',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(delay: 800.ms, begin: 0.3),
                
                const SizedBox(height: 32),
                
                // Security Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your data is encrypted and secure. All information is HIPAA compliant.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

