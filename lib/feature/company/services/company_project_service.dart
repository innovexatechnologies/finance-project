import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';

class CompanyProjectService {
  static final CompanyProjectService _instance =
      CompanyProjectService._internal();

  factory CompanyProjectService() => _instance;

  CompanyProjectService._internal() {
    final company = CompanyProfileService().currentProfile;

    // Initial structured projects pool
    projectsNotifier = ValueNotifier<List<ProjectModel>>([
      ProjectModel(
        id: 'proj_01',
        title: 'Flutter E-Commerce Mobile App',
        category: 'Mobile Dev',
        description:
            'Design a modular UI/UX experience and integrate scalable catalog browsing and checkout pathways.',
        requirements:
            'Solid knowledge of Flutter state management (Bloc/Provider), RESTful API consumption, and clean architecture principles.',
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
      ),
      ProjectModel(
        id: 'proj_02',
        title: 'Barcode & QR Scanner Mobile Utility',
        category: 'Mobile Dev',
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
        additionalInstructions:
            'Must follow Material 3 clean guidelines.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'Open',
        duration: '2 weeks',
        applicantsCount: 3,
        progress: 0.15,
      ),
      ProjectModel(
        id: 'proj_03',
        title: 'Corporate Sentiment Analysis Pipeline',
        category: 'AI / Data Science',
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
        additionalInstructions:
            'Datasets will be provided upon orientation.',
        companyName: company.companyName,
        companyId: company.id,
        status: 'In Progress',
        duration: '4 weeks',
        applicantsCount: 4,
        assignedStudent: 'Ayesha Ahmed (NUST)',
        progress: 0.40,
      ),
    ]);
  }

  late final ValueNotifier<List<ProjectModel>> projectsNotifier;

  List<ProjectModel> get allProjects => projectsNotifier.value;

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

  // Open projects available for students
  List<ProjectModel> getOpenProjectsForStudents() {
    return projectsNotifier.value.where((p) => p.status == 'Open').toList();
  }
}

