import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

class PostProjectScreen extends StatefulWidget {
  final ProjectModel? existingProject;
  final Function(int)? onTabChange;

  const PostProjectScreen({
    super.key,
    this.existingProject,
    this.onTabChange,
  });

  @override
  State<PostProjectScreen> createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends State<PostProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _deliverablesController = TextEditingController();
  final _openingsController = TextEditingController(text: '1');
  final _instructionsController = TextEditingController();
  final _customSkillController = TextEditingController();

  String _selectedCategory = 'Mobile App Development';
  String _selectedProjectType = 'Remote';
  DateTime? _selectedDeadline;
  bool _isPublishing = false;
  bool _isSavingDraft = false;

  final List<String> _categories = [
    'Mobile App Development',
    'Web Development',
    'AI / Machine Learning & Data',
    'UI/UX Design & Prototyping',
    'Cybersecurity & Ethical Hacking',
    'Cloud & DevOps Engineering',
    'IoT & Embedded Systems',
    'Blockchain & Distributed Systems',
  ];

  final List<String> _projectTypes = ['Remote', 'On-site', 'Hybrid'];

  final List<String> _availableSkills = [
    'Flutter',
    'Dart',
    'React',
    'Python',
    'Node.js',
    'Figma',
    'FastAPI',
    'SQL',
    'Git',
    'Docker',
    'TypeScript',
    'Firebase',
    'REST API',
  ];

  final List<String> _selectedSkills = [];

  bool get _isEditMode => widget.existingProject != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProject;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _requirementsController.text = existing.requirements;
      _deliverablesController.text = existing.deliverables;
      _openingsController.text = existing.openings.toString();
      _instructionsController.text = existing.additionalInstructions;
      if (_categories.contains(existing.category)) {
        _selectedCategory = existing.category;
      } else if (existing.category.isNotEmpty) {
        _categories.insert(0, existing.category);
        _selectedCategory = existing.category;
      }
      if (_projectTypes.contains(existing.projectType)) {
        _selectedProjectType = existing.projectType;
      }
      _selectedSkills.addAll(existing.skillsRequired);
      _selectedDeadline =
          DateTime.tryParse(existing.deadline) ??
          DateTime.now().add(const Duration(days: 21));
    } else {
      _selectedDeadline = DateTime.now().add(const Duration(days: 21));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _deliverablesController.dispose();
    _openingsController.dispose();
    _instructionsController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final firstAllowed = now.add(const Duration(days: 1));
    final initialDate = _selectedDeadline != null &&
            _selectedDeadline!.isAfter(firstAllowed)
        ? _selectedDeadline!
        : firstAllowed;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.deepNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _addCustomSkill() {
    final text = _customSkillController.text.trim();
    if (text.isNotEmpty && !_selectedSkills.contains(text)) {
      setState(() {
        _selectedSkills.add(text);
        _customSkillController.clear();
      });
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  ProjectModel _buildProjectFromForm({required String status}) {
    final company = _profileService.currentProfile;
    final existing = widget.existingProject;
    final deadlineString = _selectedDeadline != null
        ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}'
        : 'Flexible';

    return ProjectModel(
      id: existing?.id ?? SupabaseHelper.generateUuid(),
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      requirements: _requirementsController.text.trim(),
      skillsRequired: List<String>.from(_selectedSkills),
      deliverables: _deliverablesController.text.trim(),
      deadline: deadlineString,
      projectType: _selectedProjectType,
      openings: int.tryParse(_openingsController.text.trim()) ?? 1,
      additionalInstructions: _instructionsController.text.trim(),
      companyName: company.companyName.isNotEmpty
          ? company.companyName
          : (existing?.companyName ?? 'Company Partner'),
      companyId: company.id.isNotEmpty
          ? company.id
          : (existing?.companyId ?? ''),
      status: status,
      applicantsCount: existing?.applicantsCount ?? 0,
      assignedStudent: existing?.assignedStudent,
      progress: existing?.progress ?? 0.0,
      createdAt: existing?.createdAt ?? 'Just now',
    );
  }

  Future<void> _handleSaveDraft() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Project Title before saving draft.'),
          backgroundColor: AppColors.statusPending,
        ),
      );
      return;
    }

    setState(() => _isSavingDraft = true);

    try {
      final draftProject = _buildProjectFromForm(status: 'Draft');
      if (_isEditMode) {
        await _projectService.updateProject(draftProject);
      } else {
        await _projectService.saveDraft(draftProject);
      }
      if (!mounted) return;
      setState(() => _isSavingDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft "${draftProject.title}" saved.'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
        widget.onTabChange?.call(1);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save draft: $e'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
    }
  }

  Future<void> _confirmAndPublish() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields above.'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 required skill.'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
      return;
    }

    if (_selectedDeadline == null ||
        !_selectedDeadline!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a valid future deadline date.'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
      return;
    }

    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isEditMode ? 'Update Project?' : 'Publish Project?',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _isEditMode
                ? 'Save updates to "${_titleController.text.trim()}" and keep it open for university candidates?'
                : 'Publish "${_titleController.text.trim()}" to the live CampusConnect catalog for verified university students?',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                  _isEditMode ? 'Save & Publish' : 'Confirm & Publish'),
            ),
          ],
        );
      },
    );

    if (shouldPublish != true) return;

    setState(() => _isPublishing = true);

    try {
      final projectPayload = _buildProjectFromForm(status: 'Open');
      if (_isEditMode) {
        await _projectService.updateProject(projectPayload);
      } else {
        await _projectService.publishProject(projectPayload);
      }

      if (!mounted) return;
      setState(() => _isPublishing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Project "${projectPayload.title}" updated.'
                : 'Project "${projectPayload.title}" published to CampusConnect.',
          ),
          backgroundColor: AppColors.statusOpen,
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
        widget.onTabChange?.call(1);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish project: $e'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _requirementsController.clear();
    _deliverablesController.clear();
    _openingsController.text = '1';
    _instructionsController.clear();
    _customSkillController.clear();
    if (mounted) {
      setState(() {
        _selectedSkills.clear();
        _selectedCategory = 'Mobile App Development';
        _selectedProjectType = 'Remote';
        _selectedDeadline = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Project Scope' : 'Post New Challenge'),
        actions: [
          if (!_isEditMode || widget.existingProject?.status == 'Draft')
            TextButton(
              onPressed:
                  _isSavingDraft || _isPublishing ? null : _handleSaveDraft,
              child: _isSavingDraft
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Draft'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _buildHeaderInstructions(),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Core Project Information',
              icon: Icons.title_rounded,
              children: [
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildProjectTypeSelector(),
                const SizedBox(height: 16),
                _buildOpeningsField(),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Project Scope & Eligibility',
              icon: Icons.description_outlined,
              children: [
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildRequirementsField(),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Required Skills & Tech Stack',
              icon: Icons.code_rounded,
              children: [
                _buildSkillsSelector(),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Deliverables & Submission Deadline',
              icon: Icons.event_available_rounded,
              children: [
                _buildDeliverablesField(),
                const SizedBox(height: 16),
                _buildDeadlinePicker(),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Additional Guidelines (Optional)',
              icon: Icons.speaker_notes_outlined,
              children: [
                _buildAdditionalInstructionsField(),
              ],
            ),
            const SizedBox(height: 28),
            _buildBottomActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightAqua.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode
                      ? 'Update Challenge Specifications'
                      : 'Create Industry Project Challenge',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define clear deliverables, prerequisites, and skills so eligible university students can submit focused proposals.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.grayText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Project title is required';
        }
        if (val.trim().length < 5) {
          return 'Project title must be at least 5 characters';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Project Title *',
        hintText: 'e.g. Mobile Inventory & Telemetry Portal',
        prefixIcon: Icon(Icons.work_outline_rounded, size: 18),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Project Category *',
        prefixIcon: Icon(Icons.category_outlined, size: 18),
      ),
      items: _categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: const TextStyle(fontSize: 13.5)),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedCategory = val);
        }
      },
    );
  }

  Widget _buildProjectTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collaboration Mode *',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _projectTypes.map((type) {
            final isSelected = _selectedProjectType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedProjectType = type),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.lightGray,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected ? Colors.white : AppColors.darkText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOpeningsField() {
    return TextFormField(
      controller: _openingsController,
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Number of student openings is required';
        }
        final parsed = int.tryParse(val.trim());
        if (parsed == null || parsed < 1 || parsed > 20) {
          return 'Enter a valid number of openings (1 to 20)';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Number of Student Openings *',
        hintText: 'e.g. 2',
        prefixIcon: Icon(Icons.people_outline_rounded, size: 18),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Project description is required';
        }
        if (val.trim().length < 25) {
          return 'Please provide a descriptive scope (min 25 characters)';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Project Description & Objectives *',
        hintText:
            'Detail the problem statement, product context, and expected engineering outcomes...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildRequirementsField() {
    return TextFormField(
      controller: _requirementsController,
      maxLines: 3,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Project prerequisites are required';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Student Prerequisites & Requirements *',
        hintText:
            'e.g. Final-year CS/SE student familiar with Git workflow and REST APIs...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSkillsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Required Skills (Tap to toggle):',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              selectedColor: AppColors.lightAqua,
              checkmarkColor: AppColors.primaryBlue,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? AppColors.primaryBlue : AppColors.darkText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primaryBlue : AppColors.lightGray,
                ),
              ),
              onSelected: (_) => _toggleSkill(skill),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customSkillController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Add custom skill (e.g. GraphQL)',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onFieldSubmitted: (_) => _addCustomSkill(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: _addCustomSkill,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Selected Skills (${_selectedSkills.length}):',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedSkills.map((s) {
              return Chip(
                label: Text(s),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => _toggleSkill(s),
                backgroundColor: AppColors.lightAqua,
                labelStyle: GoogleFonts.inter(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDeliverablesField() {
    return TextFormField(
      controller: _deliverablesController,
      maxLines: 3,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Expected deliverables are required';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Expected Deliverables *',
        hintText:
            'e.g. Clean GitHub repository, test suite, documentation, and demo video...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    final dateString = _selectedDeadline != null
        ? '${_selectedDeadline!.day.toString().padLeft(2, '0')} / ${_selectedDeadline!.month.toString().padLeft(2, '0')} / ${_selectedDeadline!.year}'
        : 'Choose a date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Application & Submission Deadline *',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      dateString,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Change Date',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInstructionsField() {
    return TextFormField(
      controller: _instructionsController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Additional Instructions (Optional)',
        hintText:
            'e.g. Weekly mentor sync cadence, coding conventions, or preferred university focus...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    return Row(
      children: [
        if (!_isEditMode || widget.existingProject?.status == 'Draft') ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed:
                  _isSavingDraft || _isPublishing ? null : _handleSaveDraft,
              child: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed:
                _isPublishing || _isSavingDraft ? null : _confirmAndPublish,
            icon: _isPublishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.rocket_launch_rounded, size: 18),
            label: Text(
              _isPublishing
                  ? 'Saving...'
                  : (_isEditMode ? 'Update Project' : 'Publish Project'),
            ),
          ),
        ),
      ],
    );
  }
}
