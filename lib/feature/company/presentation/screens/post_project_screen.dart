import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

class PostProjectScreen extends StatefulWidget {
  const PostProjectScreen({super.key});

  @override
  State<PostProjectScreen> createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends State<PostProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _deliverablesController = TextEditingController();
  final _openingsController = TextEditingController(text: '2');
  final _instructionsController = TextEditingController();
  final _customSkillController = TextEditingController();

  // State values
  String _selectedCategory = 'Mobile App Development';
  String _selectedProjectType = 'Remote';
  DateTime? _selectedDeadline;
  bool _isPublishing = false;
  bool _isSavingDraft = false;

  // Categories list
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

  // Project Types
  final List<String> _projectTypes = ['Remote', 'On-site', 'Hybrid'];

  // Skill pool & Selected skills
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

  final List<String> _selectedSkills = ['Flutter', 'Dart', 'REST API'];

  @override
  void initState() {
    super.initState();
    // Default deadline: 3 weeks from today
    _selectedDeadline = DateTime.now().add(const Duration(days: 21));
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

  // Date Picker with Future Date Validation
  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final firstAllowed = now.add(const Duration(days: 1)); // Minimum tomorrow
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
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.darkNavy,
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

  // Add custom skill
  void _addCustomSkill() {
    final text = _customSkillController.text.trim();
    if (text.isNotEmpty && !_selectedSkills.contains(text)) {
      setState(() {
        _selectedSkills.add(text);
        _customSkillController.clear();
      });
    }
  }

  // Toggle pre-set skill
  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  // Build Project Model instance
  ProjectModel _buildProjectFromForm({required String status}) {
    final company = _profileService.currentProfile;
    final deadlineString = _selectedDeadline != null
        ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}'
        : 'Flexible';

    return ProjectModel(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
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
      companyName: company.companyName,
      companyId: company.id,
      status: status,
      applicantsCount: 0,
      progress: 0.0,
      createdAt: 'Just now',
    );
  }

  // Save As Draft
  Future<void> _handleSaveDraft() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a Project Title to save draft.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSavingDraft = true;
    });

    final draftProject = _buildProjectFromForm(status: 'Draft');
    await _projectService.saveDraft(draftProject);

    if (!mounted) return;

    setState(() {
      _isSavingDraft = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project "${draftProject.title}" saved to Drafts!'),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.pop(context, true);
  }

  // Show Confirmation Dialog before publishing
  Future<void> _confirmAndPublish() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please resolve the highlighted validation errors.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 required skill.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedDeadline == null ||
        !_selectedDeadline!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a valid future deadline date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Confirmation Dialog
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Publish Project?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to publish "${_titleController.text.trim()}"?\n\nIt will immediately become visible to eligible university students across CAMPUSCONNECT.',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm & Publish'),
            ),
          ],
        );
      },
    );

    if (shouldPublish != true) return;

    setState(() {
      _isPublishing = true;
    });

    final newProject = _buildProjectFromForm(status: 'Open');
    await _projectService.publishProject(newProject);

    if (!mounted) return;

    setState(() {
      _isPublishing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Project "${newProject.title}" published! Available to eligible students.',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );

    // Pops back with signal to update Company Dashboard statistics immediately
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Post New Project (Screen 25)'),
        actions: [
          TextButton(
            onPressed: _isSavingDraft || _isPublishing ? null : _handleSaveDraft,
            child: _isSavingDraft
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save Draft',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // Header Instructions Card
            _buildHeaderInstructions(),
            const SizedBox(height: 18),

            // Section 1: Core Project Details
            _buildSectionCard(
              title: '1. Core Project Information',
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
            const SizedBox(height: 20),

            // Section 2: Scope & Requirements
            _buildSectionCard(
              title: '2. Project Scope & Eligibility',
              icon: Icons.description_outlined,
              children: [
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildRequirementsField(),
              ],
            ),
            const SizedBox(height: 20),

            // Section 3: Required Skills (Multi-select)
            _buildSectionCard(
              title: '3. Required Skills & Tech Stack',
              icon: Icons.code_rounded,
              children: [
                _buildSkillsSelector(),
              ],
            ),
            const SizedBox(height: 20),

            // Section 4: Deliverables & Timeline
            _buildSectionCard(
              title: '4. Deliverables & Submission Deadline',
              icon: Icons.event_available_rounded,
              children: [
                _buildDeliverablesField(),
                const SizedBox(height: 16),
                _buildDeadlineNumberPicker(),
              ],
            ),
            const SizedBox(height: 20),

            // Section 5: Additional Guidelines
            _buildSectionCard(
              title: '5. Additional Guidelines (Optional)',
              icon: Icons.speaker_notes_outlined,
              children: [
                _buildAdditionalInstructionsField(),
              ],
            ),
            const SizedBox(height: 28),

            // Bottom Action Buttons
            _buildBottomActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Header Instructions
  Widget _buildHeaderInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightIceBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post Campus Challenge Listing',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Provide clear scope, required skills, and deliverables. Published projects will be matched with university students.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section Card Container
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // 1. Project Title Field
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
      decoration: InputDecoration(
        labelText: 'Project Title *',
        hintText: 'e.g. Flutter Mobile E-Commerce Redesign',
        prefixIcon: const Icon(Icons.work_outline_rounded, size: 18),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // 2. Project Category Dropdown
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Project Category *',
        prefixIcon: const Icon(Icons.category_outlined, size: 18),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: _categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: const TextStyle(fontSize: 13.5)),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedCategory = val;
          });
        }
      },
    );
  }

  // 3. Project Type Selector (Remote / On-site / Hybrid)
  Widget _buildProjectTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Mode / Type *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _projectTypes.map((type) {
            final isSelected = _selectedProjectType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedProjectType = type;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
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

  // 4. Number of Student Openings
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
      decoration: InputDecoration(
        labelText: 'Number of Student Openings *',
        hintText: 'e.g. 2',
        prefixIcon: const Icon(Icons.people_outline_rounded, size: 18),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // Section 2: Description Field
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
      decoration: InputDecoration(
        labelText: 'Project Description & Objectives *',
        hintText:
            'Detail the problem statement, product context, and what the student will build...',
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // Section 2: Requirements Field
  Widget _buildRequirementsField() {
    return TextFormField(
      controller: _requirementsController,
      maxLines: 3,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Project requirements are required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Student Prerequisites & Requirements *',
        hintText:
            'e.g. 3rd/4th year CS student, familiar with clean architecture and Git workflow...',
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // Section 3: Skills Selector
  Widget _buildSkillsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Required Skills (Tap to toggle):',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
              selectedColor: AppColors.lightIceBlue,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onSelected: (_) => _toggleSkill(skill),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Add custom skill input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customSkillController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add other specific skill (e.g. GraphQL)',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onFieldSubmitted: (_) => _addCustomSkill(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _addCustomSkill,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),

        // Display selected chips with remove option
        if (_selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Active Selected Skills:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
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
                backgroundColor: AppColors.lightIceBlue,
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // Section 4: Deliverables Field
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
      decoration: InputDecoration(
        labelText: 'Expected Deliverables *',
        hintText:
            'e.g. Modular GitHub repository, test suite, and runnable APK/Web link...',
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // Section 4: Deadline Date Picker
  Widget _buildDeadlineNumberPicker() {
    final dateString = _selectedDeadline != null
        ? '${_selectedDeadline!.day.toString().padLeft(2, '0')} / ${_selectedDeadline!.month.toString().padLeft(2, '0')} / ${_selectedDeadline!.year}'
        : 'Choose a date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Application & Submission Deadline *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      dateString,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Change Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Section 5: Additional Instructions Field
  Widget _buildAdditionalInstructionsField() {
    return TextFormField(
      controller: _instructionsController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Additional Instructions (Optional)',
        hintText:
            'e.g. Preferred university chapters, orientation meeting timings, contact channel...',
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // Bottom Action Buttons
  Widget _buildBottomActionButtons() {
    return Row(
      children: [
        // Save As Draft
        Expanded(
          flex: 1,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                _isSavingDraft || _isPublishing ? null : _handleSaveDraft,
            child: const Text(
              'Save Draft',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Publish Project
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
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
              _isPublishing ? 'Publishing...' : 'Publish Project',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
