import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I create a new assessment?',
      'answer':
          'Navigate to "Take Assessment" from the home screen, select an assessment template, and answer all the questions. Review your responses before submitting.',
      'category': 'Assessments',
    },
    {
      'question': 'How do I review patient assessments?',
      'answer':
          'As a doctor or psychiatrist, go to "Review Assessments" from the home screen. You can filter by status, search for specific patients, and add review notes.',
      'category': 'Review',
    },
    {
      'question': 'Can I edit an assessment after submission?',
      'answer':
          'Once submitted, assessments cannot be edited by patients. However, doctors can add review notes and update the assessment status.',
      'category': 'Assessments',
    },
    {
      'question': 'How do I manage questions as an admin?',
      'answer':
          'Go to Admin Panel > Questions tab. You can add, edit, delete, and reorder questions. Use drag and drop to change question order.',
      'category': 'Admin',
    },
    {
      'question': 'What do the different statuses mean?',
      'answer':
          'Pending: Assessment submitted, awaiting review. Reviewed: Doctor has reviewed and added notes. Completed: Assessment finalized.',
      'category': 'Review',
    },
    {
      'question': 'How do I export an assessment report?',
      'answer':
          'Open any assessment detail view and tap the export button. You can generate a PDF report for medical records.',
      'category': 'Export',
    },
    {
      'question': 'How do I change my password?',
      'answer':
          'Go to Profile > Settings > Change Password. You\'ll need to enter your current password and set a new one.',
      'category': 'Account',
    },
    {
      'question': 'What if I forget my password?',
      'answer':
          'Use the "Forgot Password" link on the login screen. Enter your email to receive password reset instructions.',
      'category': 'Account',
    },
  ];

  List<Map<String, dynamic>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _faqs;
    _searchController.addListener(_filterFaqs);
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _faqs;
      } else {
        _filteredFaqs = _faqs.where((faq) {
          return faq['question'].toLowerCase().contains(query) ||
              faq['answer'].toLowerCase().contains(query) ||
              faq['category'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Contact Support',
                    Icons.support_agent,
                    AppTheme.primaryColor,
                    () {
                      _showContactDialog();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'User Guide',
                    Icons.menu_book,
                    AppTheme.infoBlue,
                    () {
                      _showUserGuide();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FAQs Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // FAQs List
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.help_outline,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            faq['question'],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            faq['category'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                faq['answer'],
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get in touch with our support team:',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            _buildContactItem(Icons.email, 'Email', 'support@hospital.com'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.phone, 'Phone', '+1 (555) 123-4567'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.access_time, 'Hours', 'Mon-Fri, 9 AM - 5 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'User Guide',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideSection(
                'For Patients',
                '1. Register or login to your account\n'
                    '2. Select "Take Assessment" from home\n'
                    '3. Choose an assessment template\n'
                    '4. Answer all questions honestly\n'
                    '5. Review and submit your assessment',
              ),
              const SizedBox(height: 16),
              _buildGuideSection(
                'For Doctors/Psychiatrists',
                '1. Login to your professional account\n'
                    '2. Go to "Review Assessments"\n'
                    '3. Filter by status or search patients\n'
                    '4. Review assessment details\n'
                    '5. Add notes and update status',
              ),
              const SizedBox(height: 16),
              _buildGuideSection(
                'For Administrators',
                '1. Access Admin Panel from home\n'
                    '2. Manage questions in Questions tab\n'
                    '3. View analytics and statistics\n'
                    '4. Monitor system health\n'
                    '5. Manage user accounts',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
