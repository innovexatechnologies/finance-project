import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';

class CompanyProjectService {
  static final CompanyProjectService _instance =
      CompanyProjectService._internal();

  factory CompanyProjectService() => _instance;

  CompanyProjectService._internal() {
    final company = CompanyProfileService().currentProfile;

    // Structured projects pool for the logged-in company covering all 6 required statuses
    projectsNotifier = ValueNotifier<List<ProjectModel>>([
      ProjectModel(
        id: 'proj_01',
        title: 'Flutter E-Commerce Mobile App',
        category: 'Mobile App Development',
        description:
            'Design a modular UI/UX experience and integrate scalable catalog browsing and checkout pathways.',
        requirements:
            'Solid knowledge of Flutter state management (Bloc/Provider), REST API consumption, and clean architecture.',
        skillsRequired: ['Flutter', 'Dart', 'REST API', 'Figma'],
        deliverables:
            'Complete GitHub repository, production APK build, modular component documentation.',
        deadline: '2026-12-15',
        projectType: 'Remote',
        openings: 2,
        additionalInstructions:
            'Weekly sprint progress check-in on Zoom every Friday.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'In Progress',
        duration: '4 weeks',
        applicantsCount: 5,
        assignedStudent: 'Ali Khan (Fast-NUCES)',
        progress: 0.65,
        createdAt: '3 days ago',
      ),
      ProjectModel(
        id: 'proj_02',
        title: 'Barcode & QR Scanner Mobile Utility',
        category: 'Mobile App Development',
        description:
            'Develop a high-speed camera scanning utility with local scan history and export capabilities.',
        requirements:
            'Experience with camera plugins, local caching (SQLite/SharedPreferences), and clean UI widgets.',
        skillsRequired: ['Dart', 'Flutter', 'SQLite', 'Camera API'],
        deliverables:
            'Clean source code, unit test coverage, and runnable demo APK.',
        deadline: '2026-12-01',
        projectType: 'Hybrid',
        openings: 1,
        additionalInstructions: 'Must follow Material 3 clean guidelines.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'Open',
        duration: '2 weeks',
        applicantsCount: 3,
        progress: 0.15,
        createdAt: '5 days ago',
      ),
      ProjectModel(
        id: 'proj_03',
        title: 'Corporate Sentiment Analysis Pipeline',
        category: 'AI / Machine Learning & Data',
        description:
            'Build an automated NLP sentiment pipeline to classify student project feedback datasets.',
        requirements:
            'Strong Python background, HuggingFace transformers, and FastAPI backend development.',
        skillsRequired: ['Python', 'NLP', 'FastAPI', 'Pandas'],
        deliverables:
            'Jupyter evaluation notebook, containerized FastAPI service, model metrics report.',
        deadline: '2026-12-30',
        projectType: 'Remote',
        openings: 2,
        additionalInstructions: 'Datasets will be provided upon orientation.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'In Progress',
        duration: '4 weeks',
        applicantsCount: 4,
        assignedStudent: 'Ayesha Ahmed (NUST)',
        progress: 0.40,
        createdAt: '1 week ago',
      ),
      ProjectModel(
        id: 'proj_04',
        title: 'Campus Ambassador Portal Dashboard',
        category: 'Web Development',
        description:
            'Frontend dashboard for student community engagement and campus event management.',
        requirements: 'React 18, TypeScript, TailwindCSS, REST API.',
        skillsRequired: ['React', 'TypeScript', 'Tailwind', 'Git'],
        deliverables:
            'Production web deployment link, clean source code repository.',
        deadline: '2026-11-05',
        projectType: 'Remote',
        openings: 3,
        additionalInstructions: 'Completed successfully by student team.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'Completed',
        duration: '3 weeks',
        applicantsCount: 6,
        assignedStudent: 'Hamza Tariq (LUMS)',
        progress: 1.0,
        createdAt: '2 weeks ago',
      ),
      ProjectModel(
        id: 'proj_05',
        title: 'Smart IoT Campus Attendance Hardware Hook',
        category: 'IoT & Embedded Systems',
        description:
            'Firmware interface between RFID attendance hardware and cloud endpoints.',
        requirements: 'C++, ESP32, MQTT protocols.',
        skillsRequired: ['C++', 'IoT', 'MQTT', 'Embedded Systems'],
        deliverables: 'Arduino/ESP32 sketch, circuit wiring schematic.',
        deadline: '2026-12-20',
        projectType: 'On-site',
        openings: 1,
        additionalInstructions: 'Lab access provided on campus.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'Draft',
        duration: '2 weeks',
        applicantsCount: 0,
        progress: 0.0,
        createdAt: 'Yesterday',
      ),
      ProjectModel(
        id: 'proj_06',
        title: 'Legacy Database Migration to Cloud SQL',
        category: 'Cloud & DevOps Engineering',
        description:
            'Migration scripts to transfer legacy MySQL tables to PostgreSQL with zero data loss.',
        requirements: 'PostgreSQL, Docker, Database indexing.',
        skillsRequired: ['SQL', 'PostgreSQL', 'Docker', 'Python'],
        deliverables: 'Migration script suite, validation sanity check report.',
        deadline: '2026-10-30',
        projectType: 'Remote',
        openings: 1,
        additionalInstructions: 'Project concluded after initial sprint.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'Closed',
        duration: '3 weeks',
        applicantsCount: 4,
        progress: 0.90,
        createdAt: '3 weeks ago',
      ),
      ProjectModel(
        id: 'proj_07',
        title: 'Crypto Payment Gateway Bridge Prototype',
        category: 'Blockchain & Distributed Systems',
        description:
            'Proof-of-concept multi-chain signature verification utility.',
        requirements: 'Solidity, Web3.js, Smart contract auditing.',
        skillsRequired: ['Solidity', 'Web3', 'TypeScript'],
        deliverables: 'Smart contract test suite on testnet.',
        deadline: '2026-11-01',
        projectType: 'Remote',
        openings: 1,
        additionalInstructions: 'Cancelled due to corporate scope change.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'Cancelled',
        duration: '2 weeks',
        applicantsCount: 2,
        progress: 0.10,
        createdAt: '1 month ago',
      ),
    ]);
  }

  late final ValueNotifier<List<ProjectModel>> projectsNotifier;

  List<ProjectModel> get allProjects => projectsNotifier.value;
  List<ProjectModel> get projects => projectsNotifier.value;

  // Filter projects strictly belonging to the authenticated company
  List<ProjectModel> getProjectsForCompany(String companyId) {
    return projectsNotifier.value
        .where((p) => p.companyId == companyId)
        .toList();
  }

  // Publish a new project (Status: Open)
  Future<void> publishProject(ProjectModel project) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final updatedList = List<ProjectModel>.from(projectsNotifier.value);
    updatedList.insert(0, project);
    projectsNotifier.value = updatedList;
  }

  // Save project as a draft (Status: Draft)
  Future<void> saveDraft(ProjectModel project) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final updatedList = List<ProjectModel>.from(projectsNotifier.value);
    updatedList.insert(0, project);
    projectsNotifier.value = updatedList;
  }

  // Update existing project status (e.g. Open -> Closed or Cancelled)
  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final updatedList = projectsNotifier.value.map((p) {
      if (p.id == projectId) {
        return p.copyWith(status: newStatus);
      }
      return p;
    }).toList();
    projectsNotifier.value = updatedList;
  }

  // Delete / Remove draft
  Future<void> deleteProject(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final updatedList =
        projectsNotifier.value.where((p) => p.id != projectId).toList();
    projectsNotifier.value = updatedList;
  }

  // Open projects available for students
  List<ProjectModel> getOpenProjectsForStudents() {
    return projectsNotifier.value.where((p) => p.status == 'Open').toList();
  }
}
