import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/assessment_template.dart';
import '../models/consent_basis.dart';
import '../services/template_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';

/// Full CRUD screen for workflow-preset templates, accessible from Settings.
class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() =>
      _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  List<AssessmentTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final templates = await TemplateService.instance.getAllTemplates();
    if (mounted) {
      setState(() {
        _templates = templates;
        _loading = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
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
        title: Text(
          'Assessment Templates',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTemplate,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New template',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? _buildEmptyState()
          : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: EmptyStateWidget(
        icon: Icons.bookmark_add_outlined,
        iconColor: Colors.teal,
        title: 'No templates yet',
        subtitle:
            'Save time by creating templates that pre-fill common assessment contexts — clinician name, consent basis, and contextual notes.',
        actionLabel: 'Create template',
        onAction: _createTemplate,
      ),
    );
  }

  Widget _buildList() {
    // Group by assessment type.
    final grouped = <String, List<AssessmentTemplate>>{};
    for (final t in _templates) {
      grouped.putIfAbsent(t.assessmentType, () => []).add(t);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          for (final entry in grouped.entries) ...[
            _buildSectionHeader(entry.key, entry.value.length),
            const SizedBox(height: 8),
            for (var i = 0; i < entry.value.length; i++)
              _buildTemplateCard(entry.value[i], i)
                  .animate(delay: (i * 40).ms)
                  .fadeIn()
                  .slideY(begin: 0.04, end: 0),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String type, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            type,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(AssessmentTemplate template, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.bookmark,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      if (template.useCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '×${template.useCount}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  _buildSubtitle(template),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppTheme.textGrey,
                  tooltip: 'Edit',
                  onPressed: () => _editTemplate(template),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.errorRed.withValues(alpha: 0.8),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(template),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(AssessmentTemplate template) {
    final parts = <String>[];
    if (template.defaultClinician?.isNotEmpty == true) {
      parts.add(template.defaultClinician!);
    }
    final cb = template.consentBasis;
    if (cb != null) parts.add(cb.label);
    if (parts.isEmpty) {
      return Text(
        'No defaults set',
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey),
      );
    }
    return Text(
      parts.join(' · '),
      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _createTemplate() async {
    final blank = TemplateService.instance.createBlank('MHCA');
    await _openEditSheet(blank, isNew: true);
  }

  Future<void> _editTemplate(AssessmentTemplate template) async {
    await _openEditSheet(template, isNew: false);
  }

  Future<void> _confirmDelete(AssessmentTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete template?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${template.name}"? This cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TemplateService.instance.deleteTemplate(template.id);
      await _load();
    }
  }

  // ── Edit bottom sheet ─────────────────────────────────────────────────────

  Future<void> _openEditSheet(
    AssessmentTemplate initial, {
    required bool isNew,
  }) async {
    final result = await showModalBottomSheet<AssessmentTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateEditSheet(template: initial, isNew: isNew),
    );
    if (result != null) {
      await TemplateService.instance.saveTemplate(result);
      await _load();
    }
  }
}

// ── Edit sheet ─────────────────────────────────────────────────────────────

class _TemplateEditSheet extends StatefulWidget {
  final AssessmentTemplate template;
  final bool isNew;

  const _TemplateEditSheet({required this.template, required this.isNew});

  @override
  State<_TemplateEditSheet> createState() => _TemplateEditSheetState();
}

class _TemplateEditSheetState extends State<_TemplateEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _clinicianCtrl;
  late final TextEditingController _contextualNoteCtrl;

  String _assessmentType = 'MHCA';
  ConsentBasis? _consentBasis;
  bool _followUpDefault = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.template.name);
    _descCtrl = TextEditingController(text: widget.template.description ?? '');
    _clinicianCtrl = TextEditingController(
      text: widget.template.defaultClinician ?? '',
    );
    _contextualNoteCtrl = TextEditingController(
      text: widget.template.contextualNote ?? '',
    );
    _assessmentType = widget.template.assessmentType;
    _consentBasis = widget.template.consentBasis;
    _followUpDefault = widget.template.followUpRecommendedDefault;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _clinicianCtrl.dispose();
    _contextualNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.isNew ? 'New template' : 'Edit template',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Templates save workflow defaults only — not patient data or clinical scores.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 20),

                // Template name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDecor('Template name *', null),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  decoration: _inputDecor('Description (optional)', null),
                  maxLines: 2,
                  minLines: 1,
                ),
                const SizedBox(height: 14),

                // Assessment type dropdown
                DropdownButtonFormField<String>(
                  initialValue: _assessmentType,
                  decoration: _inputDecor('Assessment type', null),
                  items: const [
                    DropdownMenuItem(value: 'MHCA', child: Text('MHCA')),
                    DropdownMenuItem(value: 'DSM5', child: Text('DSM-5')),
                    DropdownMenuItem(
                      value: 'Capacity',
                      child: Text('Capacity'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _assessmentType = v);
                  },
                ),
                const SizedBox(height: 14),

                // Default clinician
                TextFormField(
                  controller: _clinicianCtrl,
                  decoration: _inputDecor(
                    'Default clinician name',
                    'Dr. Patel',
                  ),
                ),
                const SizedBox(height: 14),

                // Default consent basis
                DropdownButtonFormField<ConsentBasis?>(
                  initialValue: _consentBasis,
                  decoration: _inputDecor('Default consent basis', null),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None — do not pre-select'),
                    ),
                    ...ConsentBasis.values.map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(b.label),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _consentBasis = v),
                ),
                const SizedBox(height: 14),

                // Contextual note
                TextFormField(
                  controller: _contextualNoteCtrl,
                  decoration: _inputDecor(
                    'Contextual note (seeds place/context field)',
                    'e.g. Ward 3 — routine review',
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 14),

                // Follow-up toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Default follow-up recommended',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  value: _followUpDefault,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (v) => setState(() => _followUpDefault = v),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _save,
                    child: Text(
                      widget.isNew ? 'Create template' : 'Save changes',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppTheme.backgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final saved = widget.template.copyWith(
      id: widget.isNew ? const Uuid().v4() : widget.template.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      assessmentType: _assessmentType,
      defaultClinician: _clinicianCtrl.text.trim().isEmpty
          ? null
          : _clinicianCtrl.text.trim(),
      defaultConsentBasis: _consentBasis?.name,
      contextualNote: _contextualNoteCtrl.text.trim().isEmpty
          ? null
          : _contextualNoteCtrl.text.trim(),
      followUpRecommendedDefault: _followUpDefault,
    );
    Navigator.pop(context, saved);
  }
}
