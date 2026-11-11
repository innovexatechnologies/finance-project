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

  static const Map<String, List<String>> _categorySkillsMap = {
    'Mobile App Development': [
      'Flutter',
      'Dart',
      'React Native',
      'Kotlin',
      'Swift',
      'Android SDK',
      'iOS / Xcode',
      'Firebase',
      'SQLite / Hive',
      'REST API',
      'GraphQL',
      'Provider / Bloc',
      'Git',
    ],
    'Web Development': [
      'React',
      'Next.js',
      'TypeScript',
      'JavaScript',
      'Node.js',
      'Express.js',
      'HTML5 / CSS3',
      'Tailwind CSS',
      'PostgreSQL',
      'MongoDB',
      'FastAPI',
      'Django',
      'REST API',
      'Git',
    ],
    'AI / Machine Learning & Data': [
      'Python',
      'TensorFlow',
      'PyTorch',
      'Scikit-learn',
      'Pandas',
      'NumPy',
      'OpenAI / LLMs',
      'LangChain',
      'Computer Vision',
      'NLP',
      'SQL',
      'FastAPI',
      'Jupyter',
      'Git',
    ],
    'UI/UX Design & Prototyping': [
      'Figma',
      'Adobe XD',
      'Sketch',
      'Wireframing',
      'Prototyping',
      'Design Systems',
      'User Research',
      'Auto Layout',
      'Responsive Design',
      'Micro-interactions',
      'Usability Testing',
      'Adobe Illustrator',
    ],
    'Cybersecurity & Ethical Hacking': [
      'Penetration Testing',
      'OWASP Top 10',
      'Kali Linux',
      'Burp Suite',
      'Wireshark',
      'Nmap',
      'Metasploit',
      'Network Security',
      'Vulnerability Assessment',
      'Cryptography',
      'SIEM / SOC',
      'Python',
      'Linux',
    ],
    'Cloud & DevOps Engineering': [
      'AWS',
      'Microsoft Azure',
      'Google Cloud (GCP)',
      'Docker',
      'Kubernetes',
      'CI/CD Pipelines',
      'GitHub Actions',
      'Terraform',
      'Linux',
      'Nginx',
      'Bash Scripting',
      'Prometheus / Grafana',
      'Git',
    ],
    'IoT & Embedded Systems': [
      'C / C++',
      'Embedded C',
      'Arduino',
      'ESP32 / ESP8266',
      'Raspberry Pi',
      'MQTT',
      'PCB Design',
      'RTOS',
      'Sensors & Actuators',
      'I2C / SPI / UART',
      'BLE / Wi-Fi',
      'Python',
      'Git',
    ],
    'Blockchain & Distributed Systems': [
      'Solidity',
      'Ethereum',
      'Smart Contracts',
      'Web3.js / Ethers.js',
      'Hardhat / Foundry',
      'Rust',
      'IPFS',
      'DeFi Protocols',
      'Hyperledger',
      'Cryptography',
      'Node.js',
      'React',
      'Git',
    ],
  };

  final List<String> _selectedSkills = [];
  final Set<String> _customSkills = {};

  List<String> _getSkillsForCategory(String category) {
    final exact = _categorySkillsMap[category];
    if (exact != null) return exact;

    final lower = category.toLowerCase();
    if (lower.contains('mobile') ||
        lower.contains('android') ||
        lower.contains('ios') ||
        lower.contains('flutter')) {
      return _categorySkillsMap['Mobile App Development']!;
    }
    if (lower.contains('web') ||
        lower.contains('frontend') ||
        lower.contains('backend') ||
        lower.contains('full stack')) {
      return _categorySkillsMap['Web Development']!;
    }
    if (lower.contains('ai') ||
        lower.contains('machine learning') ||
        lower.contains('data')) {
      return _categorySkillsMap['AI / Machine Learning & Data']!;
    }
    if (lower.contains('ui') ||
        lower.contains('ux') ||
        lower.contains('design')) {
      return _categorySkillsMap['UI/UX Design & Prototyping']!;
    }
    if (lower.contains('cyber') ||
        lower.contains('security') ||
        lower.contains('hack')) {
      return _categorySkillsMap['Cybersecurity & Ethical Hacking']!;
    }
    if (lower.contains('cloud') ||
        lower.contains('devops') ||
        lower.contains('infra')) {
      return _categorySkillsMap['Cloud & DevOps Engineering']!;
    }
    if (lower.contains('iot') ||
        lower.contains('embedded') ||
        lower.contains('hardware')) {
      return _categorySkillsMap['IoT & Embedded Systems']!;
    }
    if (lower.contains('block') ||
        lower.contains('web3') ||
        lower.contains('crypto')) {
      return _categorySkillsMap['Blockchain & Distributed Systems']!;
    }

    return const [
      'Git',
      'REST API',
      'SQL',
      'Python',
      'JavaScript',
      'TypeScript',
      'Docker',
      'Figma',
    ];
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('mobile') || lower.contains('flutter')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('web')) {
      return Icons.language_rounded;
    }
    if (lower.contains('ai') || lower.contains('machine') || lower.contains('data')) {
      return Icons.psychology_outlined;
    }
    if (lower.contains('ui') || lower.contains('ux') || lower.contains('design')) {
      return Icons.palette_outlined;
    }
    if (lower.contains('cyber') || lower.contains('security')) {
      return Icons.shield_outlined;
    }
    if (lower.contains('cloud') || lower.contains('devops')) {
      return Icons.cloud_queue_rounded;
    }
    if (lower.contains('iot') || lower.contains('embedded')) {
      return Icons.memory_rounded;
    }
    if (lower.contains('block')) {
      return Icons.hub_rounded;
    }
    return Icons.category_outlined;
  }

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
      final presetForCategory = _getSkillsForCategory(_selectedCategory);
      for (final skill in existing.skillsRequired) {
        if (!presetForCategory.contains(skill)) {
          _customSkills.add(skill);
        }
      }
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
              surface: Colors.white,
              onSurface: AppColors.deepNavy,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppColors.deepNavy,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
    if (text.isEmpty) return;

    final alreadySelected = _selectedSkills.any(
      (s) => s.toLowerCase() == text.toLowerCase(),
    );
    setState(() {
      if (!alreadySelected) {
        _customSkills.add(text);
        _selectedSkills.add(text);
      }
      _customSkillController.clear();
    });
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
        _customSkills.remove(skill);
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
      if (widget.onTabChange != null) {
        _resetForm();
        widget.onTabChange!(1);
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
          contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.lightAqua,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                : 'Publish "${_titleController.text.trim()}" to the live SkillBridge catalog for verified university students?',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.grayText,
              height: 1.5,
            ),
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
                : 'Project "${projectPayload.title}" published to SkillBridge.',
          ),
          backgroundColor: AppColors.statusOpen,
        ),
      );

      if (widget.onTabChange != null) {
        _resetForm();
        widget.onTabChange!(1);
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
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
        _customSkills.clear();
        _selectedCategory = 'Mobile App Development';
        _selectedProjectType = 'Remote';
        _selectedDeadline = DateTime.now().add(const Duration(days: 21));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPopModal =
        widget.onTabChange == null && Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: canPopModal ? 0 : 16,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: canPopModal
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.deepNavy,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isEditMode
                    ? Icons.edit_note_rounded
                    : Icons.post_add_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditMode ? 'Edit Project Scope' : 'Post New Challenge',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepNavy,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    'Corporate Challenge Builder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.grayText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!_isEditMode || widget.existingProject?.status == 'Draft')
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceAlt,
                  foregroundColor: AppColors.deepNavy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed:
                    _isSavingDraft || _isPublishing ? null : _handleSaveDraft,
                icon: _isSavingDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.bookmark_border_rounded,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                label: Text(
                  'Save Draft',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.lightGray),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderInstructions(),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      step: '01',
                      title: 'Core Project Information',
                      subtitle: 'Define challenge identity, domain & capacity',
                      icon: Icons.layers_outlined,
                      children: [
                        _buildTitleField(),
                        const SizedBox(height: 16),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 18),
                        _buildProjectTypeSelector(),
                        const SizedBox(height: 18),
                        _buildOpeningsField(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      step: '02',
                      title: 'Project Scope & Eligibility',
                      subtitle: 'Outline business context and student criteria',
                      icon: Icons.description_outlined,
                      children: [
                        _buildDescriptionField(),
                        const SizedBox(height: 16),
                        _buildRequirementsField(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      step: '03',
                      title: 'Required Skills & Tech Stack',
                      subtitle: 'Curated tools matching your selected category',
                      icon: Icons.code_rounded,
                      children: [
                        _buildSkillsSelector(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      step: '04',
                      title: 'Deliverables & Submission Deadline',
                      subtitle: 'Set clear milestones and submission window',
                      icon: Icons.event_available_rounded,
                      children: [
                        _buildDeliverablesField(),
                        const SizedBox(height: 18),
                        _buildDeadlinePicker(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      step: '05',
                      title: 'Additional Guidelines (Optional)',
                      subtitle: 'Mentor sync rules or technical standards',
                      icon: Icons.speaker_notes_outlined,
                      children: [
                        _buildAdditionalInstructionsField(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildBottomActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInstructions() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.deepNavy.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -32,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: -44,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      _isEditMode
                          ? Icons.tune_rounded
                          : Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isEditMode
                                ? 'EDIT SPECIFICATIONS'
                                : 'NEW OPPORTUNITY',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.lightAqua,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isEditMode
                              ? 'Update Challenge Specifications'
                              : 'Create Industry Project Challenge',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Define clear deliverables, prerequisites, and skills so eligible university students can submit focused proposals.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.86),
                            height: 1.45,
                          ),
                        ),
                      ],
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

  Widget _buildSectionCard({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightAqua.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.grayText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Text(
                  step,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: AppColors.background,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 19, color: AppColors.grayText)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.statusClosed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.statusClosed, width: 1.6),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Project title is required';
        }
        if (val.trim().length < 5) {
          return 'Project title must be at least 5 characters';
        }
        return null;
      },
      decoration: _fieldDecoration(
        labelText: 'Project Title *',
        hintText: 'e.g. Mobile Inventory & Telemetry Portal',
        prefixIcon: Icons.work_outline_rounded,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedCategory),
      initialValue: _selectedCategory,
      isExpanded: true,
      dropdownColor: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.primaryBlue,
      ),
      decoration: _fieldDecoration(
        labelText: 'Project Category *',
        hintText: 'Choose category',
        prefixIcon: _getCategoryIcon(_selectedCategory),
      ),
      selectedItemBuilder: (context) {
        return _categories
            .map(
              (cat) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  cat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            )
            .toList();
      },
      items: _categories
          .map(
            (cat) => DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cat == _selectedCategory
                          ? AppColors.lightAqua
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(cat),
                      size: 16,
                      color: cat == _selectedCategory
                          ? AppColors.primaryBlue
                          : AppColors.grayText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: cat == _selectedCategory
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: cat == _selectedCategory
                            ? AppColors.primaryBlue
                            : AppColors.darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null && val != _selectedCategory) {
          final nextCategorySkills = _getSkillsForCategory(val);
          setState(() {
            _selectedCategory = val;
            _selectedSkills.removeWhere(
              (skill) =>
                  !_customSkills.contains(skill) &&
                  !nextCategorySkills.contains(skill),
            );
          });
        }
      },
    );
  }

  Widget _buildProjectTypeSelector() {
    IconData modeIcon(String type) {
      switch (type) {
        case 'Remote':
          return Icons.laptop_mac_rounded;
        case 'On-site':
          return Icons.apartment_rounded;
        default:
          return Icons.sync_alt_rounded;
      }
    }

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
        const SizedBox(height: 10),
        Row(
          children: _projectTypes.asMap().entries.map((entry) {
            final idx = entry.key;
            final type = entry.value;
            final isSelected = _selectedProjectType == type;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: idx == 0 ? 0 : 4,
                  right: idx == _projectTypes.length - 1 ? 0 : 4,
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedProjectType = type),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.brandGradient : null,
                      color: isSelected ? null : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.lightGray,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          modeIcon(type),
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.grayText,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
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
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.deepNavy,
      ),
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
      decoration: _fieldDecoration(
        labelText: 'Number of Student Openings *',
        hintText: 'e.g. 2',
        prefixIcon: Icons.people_outline_rounded,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Project description is required';
        }
        if (val.trim().length < 25) {
          return 'Please provide a descriptive scope (min 25 characters)';
        }
        return null;
      },
      decoration: _fieldDecoration(
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
      style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Project prerequisites are required';
        }
        return null;
      },
      decoration: _fieldDecoration(
        labelText: 'Student Prerequisites & Requirements *',
        hintText:
            'e.g. Final-year CS/SE student familiar with Git workflow and REST APIs...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSkillsSelector() {
    final categorySkills = _getSkillsForCategory(_selectedCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(_selectedCategory),
                      size: 15,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedSkills.isNotEmpty
                    ? AppColors.successBg
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedSkills.length} selected',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _selectedSkills.isNotEmpty
                      ? AppColors.statusOpen
                      : AppColors.grayText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categorySkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return InkWell(
              onTap: () => _toggleSkill(skill),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.lightAqua
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.lightGray,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      skill,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.darkText,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextFormField(
                  controller: _customSkillController,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add custom skill (e.g. GraphQL)',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lightGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _addCustomSkill(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _addCustomSkill,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Tech Stack (${_selectedSkills.length})',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedSkills.map((s) {
                    return Container(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 6,
                        top: 5,
                        bottom: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s,
                            style: GoogleFonts.inter(
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _toggleSkill(s),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: AppColors.grayText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeliverablesField() {
    return TextFormField(
      controller: _deliverablesController,
      maxLines: 3,
      style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Expected deliverables are required';
        }
        return null;
      },
      decoration: _fieldDecoration(
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

    final int? daysLeft = _selectedDeadline != null
        ? _selectedDeadline!.difference(DateTime.now()).inDays + 1
        : null;

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
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.lightAqua,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primaryBlue,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateString,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      if (daysLeft != null && daysLeft > 0)
                        Text(
                          '$daysLeft days remaining from today',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.grayText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Text(
                    'Change Date',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
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
      style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
      decoration: _fieldDecoration(
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
            flex: 2,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.deepNavy,
                  side: const BorderSide(color: AppColors.lightGray, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    _isSavingDraft || _isPublishing ? null : _handleSaveDraft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSavingDraft)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.bookmark_border_rounded, size: 17),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Save Draft',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 3,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: _isPublishing || _isSavingDraft
                  ? null
                  : AppColors.brandGradient,
              color: _isPublishing || _isSavingDraft
                  ? AppColors.grayText.withValues(alpha: 0.4)
                  : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isPublishing || _isSavingDraft
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isPublishing || _isSavingDraft
                    ? null
                    : _confirmAndPublish,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isPublishing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isPublishing
                              ? 'Saving...'
                              : (_isEditMode ? 'Update Project' : 'Publish Project'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
