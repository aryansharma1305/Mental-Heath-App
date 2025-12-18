import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../models/assessment_template.dart';
import '../services/question_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final QuestionService _questionService = QuestionService();
  final AuthService _authService = AuthService();
  
  List<AssessmentTemplate> _templates = [];
  List<Question> _allQuestions = []; // All available questions
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedTab = 0; // 0 = Assessments, 1 = Questions, 2 = Analytics
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadTemplates(),
        _loadAllQuestions(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadTemplates() async {
    if (SupabaseService.isAvailable) {
      _templates = await _supabaseService.getAllTemplates();
    }
  }
  
  Future<void> _loadAllQuestions() async {
    if (SupabaseService.isAvailable) {
      _allQuestions = await _supabaseService.getAllQuestions();
    } else {
      _allQuestions = await _questionService.getAllQuestions();
    }
  }
  
  Future<void> _showCreateTemplateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateTemplateDialog(),
    );
    
    if (result != null) {
      try {
        final currentUser = await _authService.getCurrentUserModel();
        final template = AssessmentTemplate(
          name: result['name'] as String,
          description: result['description'] as String?,
          createdBy: currentUser?.id,
        );
        
        if (SupabaseService.isAvailable) {
          final templateId = await _supabaseService.createTemplate(template);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _EditTemplateScreen(templateId: templateId),
              ),
            ).then((_) => _loadTemplates());
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating template: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Assessments'),
            Tab(icon: Icon(Icons.quiz), text: 'Questions'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAssessmentsTab(),
                _buildQuestionsTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateTemplateDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Assessment'),
            )
          : _selectedTab == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddQuestionDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                )
              : null,
    );
  }
  
  Widget _buildAssessmentsTab() {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No assessments yet',
              style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first assessment',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: template.isActive 
                    ? AppTheme.primaryBlue 
                    : Colors.grey,
                child: const Icon(Icons.assignment, color: Colors.white),
              ),
              title: Text(
                template.name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: template.description != null
                  ? Text(template.description!)
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                    onPressed: () async {
                      if (template.id != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _EditTemplateScreen(templateId: template.id!),
                          ),
                        );
                        _loadTemplates();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                    onPressed: () => _deleteTemplate(template.id!),
                  ),
                ],
              ),
              onTap: () async {
                if (template.id != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _EditTemplateScreen(templateId: template.id!),
                    ),
                  );
                  _loadTemplates();
                }
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildQuestionsTab() {
    // Keep existing questions management
    if (_allQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No questions yet',
              style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first question',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadAllQuestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allQuestions.length,
        itemBuilder: (context, index) {
          final question = _allQuestions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: question.isActive 
                    ? AppTheme.primaryBlue 
                    : Colors.grey,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                question.text,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(question.type.name).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          question.type.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTypeColor(question.type.name),
                          ),
                        ),
                      ),
                      if (question.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            question.category!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                    onPressed: () => _showEditQuestionDialog(question),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                    onPressed: () => _deleteQuestion(question.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Total Assessments', _templates.length.toString(), Icons.assignment, AppTheme.primaryBlue),
          const SizedBox(height: 12),
          _buildStatCard('Active Assessments', _templates.where((t) => t.isActive).length.toString(), Icons.check_circle, AppTheme.accentGreen),
          const SizedBox(height: 12),
          _buildStatCard('Total Questions', _allQuestions.length.toString(), Icons.quiz, AppTheme.infoBlue),
          const SizedBox(height: 12),
          _buildStatCard('Active Questions', _allQuestions.where((q) => q.isActive).length.toString(), Icons.check_circle, AppTheme.warningOrange),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'yesNo':
        return Colors.green;
      case 'multipleChoice':
        return Colors.blue;
      case 'textInput':
        return Colors.orange;
      case 'scale':
        return Colors.purple;
      case 'date':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  Future<void> _deleteTemplate(int templateId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: const Text('Are you sure you want to delete this assessment template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _supabaseService.deleteTemplate(templateId);
        _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assessment deleted successfully'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting assessment: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _showAddQuestionDialog() async {
    final result = await showDialog<Question>(
      context: context,
      builder: (context) => const AddEditQuestionDialog(),
    );
    
    if (result != null) {
      try {
        if (SupabaseService.isAvailable) {
          await _supabaseService.addQuestion(result);
        } else {
          await _questionService.addQuestion(result);
        }
        _loadAllQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question added successfully'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding question: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _showEditQuestionDialog(Question question) async {
    final result = await showDialog<Question>(
      context: context,
      builder: (context) => AddEditQuestionDialog(question: question),
    );
    
    if (result != null) {
      try {
        if (SupabaseService.isAvailable) {
          await _supabaseService.updateQuestion(result);
        } else {
          await _questionService.updateQuestion(result);
        }
        _loadAllQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question updated successfully'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating question: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _deleteQuestion(int questionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        if (SupabaseService.isAvailable) {
          await _supabaseService.deleteQuestion(questionId);
        } else {
          await _questionService.deleteQuestion(questionId);
        }
        _loadAllQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question deleted successfully'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting question: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
}

// Create Template Dialog
class _CreateTemplateDialog extends StatefulWidget {
  @override
  State<_CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<_CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Assessment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Assessment Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter assessment name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// Edit Template Screen - Shows template and allows adding/removing questions
class _EditTemplateScreen extends StatefulWidget {
  final int templateId;
  
  const _EditTemplateScreen({required this.templateId});
  
  @override
  State<_EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<_EditTemplateScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final QuestionService _questionService = QuestionService();
  
  AssessmentTemplate? _template;
  List<Question> _templateQuestions = [];
  List<Question> _availableQuestions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTemplateData();
  }
  
  Future<void> _loadTemplateData() async {
    setState(() => _isLoading = true);
    try {
      _template = await _supabaseService.getTemplateWithQuestions(widget.templateId);
      if (_template != null) {
        _templateQuestions = _template!.questions ?? [];
      }
      
      // Load all available questions
      if (SupabaseService.isAvailable) {
        _availableQuestions = await _supabaseService.getAllQuestions();
      } else {
        _availableQuestions = await _questionService.getAllQuestions();
      }
      
      // Filter out questions already in template
      final templateQuestionIds = _templateQuestions.map((q) => q.id).toSet();
      _availableQuestions = _availableQuestions
          .where((q) => !templateQuestionIds.contains(q.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading template: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addQuestionToTemplate(int questionId) async {
    try {
      final orderIndex = _templateQuestions.length;
      await _supabaseService.addQuestionToTemplate(
        widget.templateId,
        questionId,
        orderIndex,
      );
      _loadTemplateData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question added to assessment'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding question: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  Future<void> _removeQuestionFromTemplate(int questionId) async {
    try {
      await _supabaseService.removeQuestionFromTemplate(widget.templateId, questionId);
      _loadTemplateData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question removed from assessment'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing question: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_template?.name ?? 'Edit Assessment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Assessment')),
        body: const Center(child: Text('Assessment not found')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_template!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddQuestionDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Template Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryBlue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _template!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_template!.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _template!.description!,
                    style: GoogleFonts.inter(color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
          
          // Questions in Template
          Expanded(
            child: _templateQuestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No questions in this assessment',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add questions',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _templateQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _templateQuestions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(question.text),
                          subtitle: Text(question.type.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppTheme.errorRed),
                            onPressed: () => _removeQuestionFromTemplate(question.id!),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuestionDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Future<void> _showAddQuestionDialog() async {
    if (_availableQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available questions. Please create questions first.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }
    
    final selectedQuestion = await showDialog<Question>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Question to Assessment'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableQuestions.length,
            itemBuilder: (context, index) {
              final question = _availableQuestions[index];
              return ListTile(
                title: Text(question.text),
                subtitle: Text(question.type.name),
                onTap: () => Navigator.pop(context, question),
              );
            },
          ),
        ),
      ),
    );
    
    if (selectedQuestion != null && selectedQuestion.id != null) {
      await _addQuestionToTemplate(selectedQuestion.id!);
    }
  }
}

// Keep existing AddEditQuestionDialog
class AddEditQuestionDialog extends StatefulWidget {
  final Question? question;
  
  const AddEditQuestionDialog({this.question});
  
  @override
  State<AddEditQuestionDialog> createState() => _AddEditQuestionDialogState();
}

class _AddEditQuestionDialogState extends State<AddEditQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionsController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String? _questionType;
  bool _required = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!.text;
      _questionType = widget.question!.type.name;
      _required = widget.question!.required;
      _categoryController.text = widget.question!.category ?? '';
      if (widget.question!.options != null) {
        _optionsController.text = widget.question!.options!.join(', ');
      }
    }
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _optionsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question Text *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter question text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _questionType,
                decoration: const InputDecoration(
                  labelText: 'Question Type *',
                  border: OutlineInputBorder(),
                ),
                items: QuestionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type.name,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _questionType = value),
                validator: (value) {
                  if (value == null) {
                    return 'Please select question type';
                  }
                  return null;
                },
              ),
              if (_questionType == 'multipleChoice') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Options (comma-separated) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_questionType == 'multipleChoice' && (value == null || value.isEmpty)) {
                      return 'Please enter options';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Required'),
                value: _required,
                onChanged: (value) => setState(() => _required = value ?? true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final question = Question(
                id: widget.question?.id,
                text: _questionController.text.trim(),
                type: QuestionType.values.firstWhere((t) => t.name == _questionType),
                options: _questionType == 'multipleChoice'
                    ? _optionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                    : null,
                required: _required,
                category: _categoryController.text.trim().isEmpty
                    ? null
                    : _categoryController.text.trim(),
                order: widget.question?.order ?? 0,
                createdBy: widget.question?.createdBy,
                createdAt: widget.question?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              Navigator.pop(context, question);
            }
          },
          child: Text(widget.question == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
