import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

class CompanyApplicantService {
  static final CompanyApplicantService _instance =
      CompanyApplicantService._internal();

  factory CompanyApplicantService() => _instance;

  CompanyApplicantService._internal() {
    // Seeded with realistic university students across company projects
    applicantsNotifier = ValueNotifier<List<ApplicantModel>>([
      ApplicantModel(
        id: 'app_01',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Ali Khan',
        email: 'ali.khan@nu.edu.pk',
        university: 'FAST-NUCES Islamabad',
        degree: 'BS Computer Science (Final Year)',
        cgpa: 3.82,
        skills: ['Flutter', 'Dart', 'Bloc', 'REST API', 'Git'],
        appliedDate: '2026-11-06',
        proposalSummary:
            'I have built 2 production Flutter apps with clean architecture and Bloc. I can implement the catalog and checkout flow within 3 weeks with 100% test coverage.',
        status: 'Accepted',
        avatarInitial: 'AK',
        portfolioUrl: 'https://github.com/alikhan-flutter',
        rating: 4.9,
      ),
      ApplicantModel(
        id: 'app_02',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Ayesha Ahmed',
        email: 'ayesha.ahmed@seecs.edu.pk',
        university: 'NUST SEECS',
        degree: 'BS Software Engineering (3rd Year)',
        cgpa: 3.91,
        skills: ['Flutter', 'Figma', 'Firebase', 'State Management'],
        appliedDate: '2026-11-07',
        proposalSummary:
            'Specialized in crafting pixel-perfect, responsive Flutter UIs based on Figma designs with micro-animations.',
        status: 'Shortlisted',
        avatarInitial: 'AA',
        portfolioUrl: 'https://behance.net/ayesha-ui',
        rating: 4.8,
      ),
      ApplicantModel(
        id: 'app_03',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Hamza Tariq',
        email: 'hamza.tariq@lums.edu.pk',
        university: 'LUMS Lahore',
        degree: 'BS Computer Science',
        cgpa: 3.65,
        skills: ['Flutter', 'Node.js', 'PostgreSQL', 'Docker'],
        appliedDate: '2026-11-08',
        proposalSummary:
            'Full-stack mobile engineer with backend experience. Interested in optimizing cart checkout and caching layers.',
        status: 'Pending',
        avatarInitial: 'HT',
        portfolioUrl: 'https://github.com/hamzatariq-lums',
        rating: 4.6,
      ),
      ApplicantModel(
        id: 'app_04',
        projectId: 'proj_02',
        projectTitle: 'Barcode & QR Scanner Mobile Utility',
        name: 'Bilal Shah',
        email: 'bilal.shah@giki.edu.pk',
        university: 'GIKI Swabi',
        degree: 'BS Computer Engineering',
        cgpa: 3.75,
        skills: ['Dart', 'Camera API', 'SQLite', 'C++'],
        appliedDate: '2026-11-08',
        proposalSummary:
            'Experienced in high-performance hardware camera hooks and barcode extraction pipelines in Dart.',
        status: 'Under Review',
        avatarInitial: 'BS',
        portfolioUrl: 'https://github.com/bilalshah-giki',
        rating: 4.7,
      ),
      ApplicantModel(
        id: 'app_05',
        projectId: 'proj_02',
        projectTitle: 'Barcode & QR Scanner Mobile Utility',
        name: 'Zainab Bibi',
        email: 'zainab.bibi@uettaxila.edu.pk',
        university: 'UET Taxila',
        degree: 'BS Computer Science',
        cgpa: 3.55,
        skills: ['Flutter', 'Mobile Utilities', 'Local Storage'],
        appliedDate: '2026-11-05',
        proposalSummary:
            'Passionate mobile developer ready to build clean scanning interface and history export.',
        status: 'Pending',
        avatarInitial: 'ZB',
        portfolioUrl: 'https://github.com/zainab-uet',
        rating: 4.5,
      ),
      ApplicantModel(
        id: 'app_06',
        projectId: 'proj_03',
        projectTitle: 'Corporate Sentiment Analysis Pipeline',
        name: 'Mustafa Hassan',
        email: 'mustafa.hassan@pucit.edu.pk',
        university: 'PUCIT Lahore',
        degree: 'MS Data Science',
        cgpa: 3.88,
        skills: ['Python', 'NLP', 'FastAPI', 'PyTorch', 'Transformers'],
        appliedDate: '2026-11-04',
        proposalSummary:
            'Published research on aspect-based sentiment classification. Can deliver a quantized FastAPI microservice in 3 weeks.',
        status: 'Accepted',
        avatarInitial: 'MH',
        portfolioUrl: 'https://huggingface.co/mustafahassan',
        rating: 5.0,
      ),
      ApplicantModel(
        id: 'app_07',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Danish Khan',
        email: 'danish.khan@cust.edu.pk',
        university: 'CUST Islamabad',
        degree: 'BS Software Engineering',
        cgpa: 3.10,
        skills: ['HTML', 'CSS', 'Beginner Flutter'],
        appliedDate: '2026-11-02',
        proposalSummary:
            'Looking for an internship opportunity to gain experience in commercial mobile apps.',
        status: 'Rejected',
        avatarInitial: 'DK',
        portfolioUrl: '',
        rating: 4.0,
      ),
    ]);
  }

  late final ValueNotifier<List<ApplicantModel>> applicantsNotifier;

  List<ApplicantModel> get allApplicants => applicantsNotifier.value;

  // Filter applicants by project ID
  List<ApplicantModel> getApplicantsForProject(String projectId) {
    return applicantsNotifier.value
        .where((a) => a.projectId == projectId)
        .toList();
  }

  // Count how many students have already been accepted for a project
  int getAcceptedCount(String projectId) {
    return applicantsNotifier.value
        .where((a) => a.projectId == projectId && a.status == 'Accepted')
        .length;
  }

  // Update applicant status (Shortlist, Accept, Reject, Under Review)
  Future<bool> updateApplicantStatus({
    required String applicantId,
    required String newStatus,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final currentList = applicantsNotifier.value;
    final targetIndex = currentList.indexWhere((a) => a.id == applicantId);

    if (targetIndex == -1) return false;

    final targetApplicant = currentList[targetIndex];

    // Check project opening constraints if accepting
    if (newStatus == 'Accepted') {
      final projectService = CompanyProjectService();
      final project = projectService.allProjects.firstWhere(
        (p) => p.id == targetApplicant.projectId,
        orElse: () => projectService.allProjects.first,
      );

      final acceptedCount = getAcceptedCount(targetApplicant.projectId);
      if (acceptedCount >= project.openings) {
        // Exceeds available openings!
        return false;
      }

      // Automatically assign student to the project and transition to 'In Progress'
      projectService.updateProjectStatus(project.id, 'In Progress');
    }

    final updatedApplicant = targetApplicant.copyWith(status: newStatus);
    final updatedList = List<ApplicantModel>.from(currentList);
    updatedList[targetIndex] = updatedApplicant;

    applicantsNotifier.value = updatedList;
    return true;
  }
}

