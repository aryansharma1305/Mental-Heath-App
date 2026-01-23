import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/language_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _doctorName = 'Doctor';
  String _designation = '';
  String _hospital = '';
  String _registrationNo = '';
  AppLanguage _selectedLanguage = AppLanguage.english;
  int _totalAssessments = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final langService = LanguageService();
    await langService.init();
    
    // Load doctor profile
    final doctorJson = prefs.getString('doctor_profile');
    if (doctorJson != null) {
      try {
        final data = jsonDecode(doctorJson);
        setState(() {
          _doctorName = data['name'] ?? 'Doctor';
          _designation = data['designation'] ?? '';
          _hospital = data['hospital'] ?? '';
          _registrationNo = data['registration_number'] ?? '';
        });
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
    
    // Load assessment stats
    final assessments = prefs.getStringList('capacity_assessments') ?? [];
    
    setState(() {
      _selectedLanguage = langService.currentLanguage;
      _totalAssessments = assessments.length;
    });
  }

  Future<void> _changeLanguage(AppLanguage language) async {
    final langService = LanguageService();
    await langService.setLanguage(language);
    setState(() {
      _selectedLanguage = language;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to ${language.displayName}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final isSelected = lang == _selectedLanguage;
            return ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textGrey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              title: Text(
                lang.displayName,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _changeLanguage(lang);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Data?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.errorRed),
        ),
        content: Text(
          'This will delete all assessments and reset your profile. This action cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text('Clear', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All data cleared'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorRed,
          ),
        );
        
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Center(child: Text(_doctorName.isNotEmpty ? _doctorName[0].toUpperCase() : 'D', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_doctorName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (_designation.isNotEmpty) Text(_designation, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                        if (_hospital.isNotEmpty) Text(_hospital, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),
            
            const SizedBox(height: 24),
            
            Text('Language', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: _showLanguageDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.language, color: AppTheme.primaryColor)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('App Language', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                      Text(_selectedLanguage.displayName, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textGrey)),
                    ])),
                    Icon(Icons.chevron_right, color: AppTheme.textGrey),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
            
            const SizedBox(height: 24),
            
            Text('Statistics', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
              child: Column(children: [
                _buildStatRow('Total Assessments', '$_totalAssessments', Icons.assessment),
                const Divider(height: 24),
                _buildStatRow('Registration No.', _registrationNo.isEmpty ? 'Not set' : _registrationNo, Icons.badge),
              ]),
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 24),
            
            Text('Data Management', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: _clearAllData,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)), boxShadow: AppTheme.softShadow),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.delete_outline, color: AppTheme.errorRed)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Clear All Data', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
                    Text('Delete all assessments and reset profile', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
                  ])),
                  Icon(Icons.chevron_right, color: AppTheme.textGrey),
                ]),
              ),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 32),
            
            Center(child: Column(children: [
              Text('DSM-5 Assessment', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text('Version 1.0.0', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
            ])).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.skyBlue, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: AppTheme.infoBlue)),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMedium)),
      const Spacer(),
      Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
    ]);
  }
}
