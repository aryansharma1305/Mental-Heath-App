import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final QuestionService _questionService = QuestionService();
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Question> _questions = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuestions();
  }
  
  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      // Try Supabase first
      if (SupabaseService.isAvailable) {
        _questions = await _supabaseService.getAllQuestions();
      } else {
        // Fallback to local
        _questions = await _questionService.getAllQuestions();
      }
      _questions.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } catch (e) {
      debugPrint('Error loading questions: $e');
    } finally {
      setState(() => _isLoading = false);
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
        _loadQuestions();
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
        _loadQuestions();
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
  
  Future<void> _deleteQuestion(Question question) async {
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
    
    if (confirm == true && question.id != null) {
      try {
        if (SupabaseService.isAvailable) {
          await _supabaseService.deleteQuestion(question.id!);
        } else {
          await _questionService.deleteQuestion(question.id!);
        }
        _loadQuestions();
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Questions'),
            Tab(icon: Icon(Icons.insights), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionsTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddQuestionDialog,
              backgroundColor: AppTheme.primaryBlue,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            )
          : null,
    );
  }
  
  Widget _buildQuestionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_questions.isEmpty) {
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
      onRefresh: _loadQuestions,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        onReorder: (oldIndex, newIndex) async {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _questions.removeAt(oldIndex);
            _questions.insert(newIndex, item);
            
            // Update order for all questions
            for (int i = 0; i < _questions.length; i++) {
              _questions[i] = _questions[i].copyWith(
                order: i,
                updatedAt: DateTime.now(),
              );
            }
          });
          
          // Save new order
          for (var question in _questions) {
            try {
              if (SupabaseService.isAvailable) {
                await _supabaseService.updateQuestion(question);
              } else {
                await _questionService.updateQuestion(question);
              }
            } catch (e) {
              debugPrint('Error updating question order: $e');
            }
          }
        },
        itemBuilder: (context, index) {
          final question = _questions[index];
          return Card(
            key: ValueKey(question.id),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: question.isActive ? AppTheme.primaryBlue : Colors.grey,
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
                            fontSize: 11,
                            color: _getTypeColor(question.type.name),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (question.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            question.category!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(
                        question.required ? Icons.star : Icons.star_border,
                        size: 14,
                        color: question.required ? Colors.orange : Colors.grey,
                      ),
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
                    onPressed: () => _deleteQuestion(question),
                  ),
                  const Icon(Icons.drag_handle, color: Colors.grey),
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
          _buildStatCard('Total Questions', _questions.length.toString(), Icons.quiz, AppTheme.primaryBlue),
          const SizedBox(height: 12),
          _buildStatCard('Active Questions', _questions.where((q) => q.isActive).length.toString(), Icons.check_circle, AppTheme.accentGreen),
          const SizedBox(height: 12),
          _buildStatCard('Inactive Questions', _questions.where((q) => !q.isActive).length.toString(), Icons.cancel, AppTheme.errorRed),
          const SizedBox(height: 24),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryBreakdown() {
    final categories = <String, int>{};
    for (var question in _questions) {
      if (question.category != null) {
        categories[question.category!] = (categories[question.category!] ?? 0) + 1;
      }
    }
    
    if (categories.isEmpty) {
      return const SizedBox();
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questions by Category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: entry.value / _questions.length,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value.toString(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            }),
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
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Add/Edit Question Dialog
class AddEditQuestionDialog extends StatefulWidget {
  final Question? question;
  
  const AddEditQuestionDialog({super.key, this.question});
  
  @override
  State<AddEditQuestionDialog> createState() => _AddEditQuestionDialogState();
}

class _AddEditQuestionDialogState extends State<AddEditQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _optionsController;
  late TextEditingController _categoryController;
  
  String _questionType = 'yesNo';
  bool _required = true;
  bool _isActive = true;
  
  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question?.text ?? '');
    _optionsController = TextEditingController(text: widget.question?.options?.join(', ') ?? '');
    _categoryController = TextEditingController(text: widget.question?.category ?? '');
    
    if (widget.question != null) {
      _questionType = widget.question!.type.name;
      _required = widget.question!.required;
      _isActive = widget.question!.isActive;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.question == null ? 'Add Question' : 'Edit Question',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Question Text
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.question_answer),
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
                
                // Question Type
                DropdownButtonFormField<String>(
                  value: _questionType,
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'yesNo', child: Text('Yes/No')),
                    DropdownMenuItem(value: 'multipleChoice', child: Text('Multiple Choice')),
                    DropdownMenuItem(value: 'textInput', child: Text('Text Input')),
                    DropdownMenuItem(value: 'scale', child: Text('Scale (1-10)')),
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                  ],
                  onChanged: (value) {
                    setState(() => _questionType = value!);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Options (for multiple choice)
                if (_questionType == 'multipleChoice')
                  TextFormField(
                    controller: _optionsController,
                    decoration: const InputDecoration(
                      labelText: 'Options (comma-separated)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list),
                      hintText: 'Option 1, Option 2, Option 3',
                    ),
                    validator: (value) {
                      if (_questionType == 'multipleChoice' && (value == null || value.isEmpty)) {
                        return 'Please enter options';
                      }
                      return null;
                    },
                  ),
                
                if (_questionType == 'multipleChoice')
                  const SizedBox(height: 16),
                
                // Category
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                    hintText: 'e.g., Understanding, Retention',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Required Switch
                SwitchListTile(
                  title: const Text('Required'),
                  value: _required,
                  onChanged: (value) {
                    setState(() => _required = value);
                  },
                  activeColor: AppTheme.primaryBlue,
                ),
                
                // Active Switch
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                  activeColor: AppTheme.accentGreen,
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        widget.question == null ? 'Add' : 'Update',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      final question = Question(
        id: widget.question?.id,
        text: _questionController.text.trim(),
        type: QuestionType.values.firstWhere((t) => t.name == _questionType),
        options: _questionType == 'multipleChoice'
            ? _optionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : null,
        required: _required,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        order: widget.question?.order ?? 0,
        isActive: _isActive,
        createdBy: widget.question?.createdBy,
        createdAt: widget.question?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      Navigator.pop(context, question);
    }
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _optionsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
