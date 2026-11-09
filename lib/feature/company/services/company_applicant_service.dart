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
        studentId: 'std_fast_01',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Ali Khan',
        email: 'ali.khan@nu.edu.pk',
        university: 'FAST-NUCES Islamabad',
        isEducationVerified: true,
        degree: 'BS Computer Science (Honors)',
        department: 'Department of Computer Science',
        semester: '8th Semester (Final Year)',
        cgpa: 3.82,
        skills: ['Flutter', 'Dart', 'Bloc', 'REST API', 'Git', 'Clean Architecture'],
        appliedDate: '2026-11-06',
        proposalSummary:
            'I have built 2 production Flutter apps with clean architecture and Bloc state management. I can implement the catalog, cart, and checkout flow within 3 weeks with 100% test coverage and responsive UI across iOS and Android.',
        status: 'Accepted',
        avatarInitial: 'AK',
        portfolioUrl: 'https://github.com/alikhan-flutter',
        rating: 4.9,
        bio:
            'Passionate final-year software engineering student specialized in high-performance Flutter mobile applications, clean code patterns, and automated unit testing.',
        resumeFileName: 'AliKhan_Official_Resume_2026.pdf',
        portfolioProjects: const [
          StudentPortfolioItem(
            id: 'port_01',
            title: 'Campus Food Delivery & Tracking App',
            description:
                'Real-time order tracking mobile app built with Flutter and Firebase with live delivery route updates and order receipt generation.',
            techStack: ['Flutter', 'Firebase', 'Google Maps API', 'Bloc'],
            projectUrl: 'https://github.com/alikhan/campus-food',
            attachmentName: 'CampusFood_Architecture_Report.pdf',
            attachmentType: 'Report',
          ),
          StudentPortfolioItem(
            id: 'port_02',
            title: 'Student Task & Exam Schedule Manager',
            description:
                'Offline-first productivity mobile app with automated university exam timetable parsing and SQLite local caching.',
            techStack: ['Flutter', 'SQLite', 'Provider', 'Local Notifications'],
            projectUrl: 'https://github.com/alikhan/task-flow',
            attachmentName: 'TaskFlow_Release_v1.2.apk',
            attachmentType: 'Demo APK',
          ),
        ],
        previousProjects: const [
          PreviousProjectRecord(
            id: 'prev_01',
            title: 'University Digital Library & Attendance Portal',
            organization: 'FAST-NUCES IT Department',
            role: 'Lead Flutter Mobile Developer',
            completionDate: 'August 2026',
            rating: 4.9,
            clientFeedback:
                'Ali delivered outstanding UI components with zero bugs and met every weekly milestone on time. Truly exceptional work ethic.',
          ),
          PreviousProjectRecord(
            id: 'prev_02',
            title: 'Campus Ambassador Event Check-In Engine',
            organization: 'CampusConnect Capstone Program',
            role: 'Mobile Frontend Engineer',
            completionDate: 'June 2026',
            rating: 5.0,
            clientFeedback:
                'High quality code structure and responsive UI layouts across multiple screen sizes. Highly recommended for commercial projects.',
          ),
        ],
        certificates: const [
          StudentCertificate(
            id: 'cert_01',
            title: 'Associate Android Developer & Flutter Specialist',
            issuer: 'Google Developers Certification',
            issueDate: 'May 2026',
            credentialId: 'GDC-FLUTTER-89241',
            verificationUrl: 'https://credentials.google.com/verify/89241',
          ),
          StudentCertificate(
            id: 'cert_02',
            title: 'Clean Architecture & Microservices in Dart',
            issuer: 'Meta Learning Pathways',
            issueDate: 'July 2026',
            credentialId: 'META-ARCH-4421',
            verificationUrl: 'https://meta.com/certs/4421',
          ),
        ],
      ),
      ApplicantModel(
        id: 'app_02',
        studentId: 'std_nust_02',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Ayesha Ahmed',
        email: 'ayesha.ahmed@seecs.edu.pk',
        university: 'NUST SEECS Islamabad',
        isEducationVerified: true,
        degree: 'BS Software Engineering',
        department: 'School of Electrical Engineering & Computer Science',
        semester: '6th Semester (3rd Year)',
        cgpa: 3.91,
        skills: ['Flutter', 'Figma', 'UI/UX Design', 'Firebase', 'State Management', 'Animations'],
        appliedDate: '2026-11-07',
        proposalSummary:
            'Specialized in crafting pixel-perfect, responsive Flutter UIs based on Figma design systems with micro-animations. I can complete the design implementation and checkout flow within 2 weeks.',
        status: 'Shortlisted',
        avatarInitial: 'AA',
        portfolioUrl: 'https://behance.net/ayesha-ui',
        rating: 4.8,
        bio:
            'UI/UX focused Software Engineering student passionate about human-centered design, design tokens, and smooth Flutter transitions.',
        resumeFileName: 'AyeshaAhmed_CV_2026.pdf',
        portfolioProjects: const [
          StudentPortfolioItem(
            id: 'port_03',
            title: 'HealthVibe Wellness & Habit Tracker',
            description:
                'Minimalist lifestyle companion app featuring dynamic charts and custom animated habit completion rings.',
            techStack: ['Flutter', 'Figma', 'CustomPaint', 'SharedPrefs'],
            projectUrl: 'https://behance.net/ayesha-ui/healthvibe',
            attachmentName: 'HealthVibe_Design_Tokens.pdf',
            attachmentType: 'Design',
          ),
        ],
        previousProjects: const [
          PreviousProjectRecord(
            id: 'prev_03',
            title: 'FinHealth Expense Visualizer UI Suite',
            organization: 'SEECS Software Incubation Lab',
            role: 'UI/UX Lead & Mobile Dev',
            completionDate: 'September 2026',
            rating: 4.8,
            clientFeedback:
                'Ayesha demonstrated high aesthetic maturity and transformed complex user requirements into delightful, clean screens.',
          ),
        ],
        certificates: const [
          StudentCertificate(
            id: 'cert_03',
            title: 'Certified Professional UI/UX Designer',
            issuer: 'Interaction Design Foundation (IxDF)',
            issueDate: 'April 2026',
            credentialId: 'IXDF-UIUX-9011',
            verificationUrl: 'https://ixdf.org/verify/9011',
          ),
        ],
      ),
      ApplicantModel(
        id: 'app_03',
        studentId: 'std_lums_03',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Hamza Tariq',
        email: 'hamza.tariq@lums.edu.pk',
        university: 'LUMS Lahore',
        isEducationVerified: true,
        degree: 'BS Computer Science',
        department: 'Syed Babar Ali School of Science and Engineering',
        semester: '7th Semester',
        cgpa: 3.65,
        skills: ['Flutter', 'Node.js', 'PostgreSQL', 'Docker', 'GraphQL'],
        appliedDate: '2026-11-08',
        proposalSummary:
            'Full-stack mobile engineer with backend microservice experience. Interested in optimizing cart checkout, caching layers, and offline sync for your e-commerce mobile application.',
        status: 'Pending',
        avatarInitial: 'HT',
        portfolioUrl: 'https://github.com/hamzatariq-lums',
        rating: 4.6,
        bio:
            'Full-stack engineer focusing on resilient distributed backends and clean mobile client integrations.',
        resumeFileName: 'HamzaTariq_Resume.pdf',
        portfolioProjects: const [
          StudentPortfolioItem(
            id: 'port_04',
            title: 'Campus RideShare Matcher',
            description:
                'Carpooling mobile application connecting students with daily campus commuters.',
            techStack: ['Flutter', 'Node.js', 'PostgreSQL', 'Socket.io'],
            projectUrl: 'https://github.com/hamzatariq-lums/rideshare',
            attachmentName: 'RideShare_System_Design.pdf',
            attachmentType: 'Code',
          ),
        ],
        previousProjects: const [
          PreviousProjectRecord(
            id: 'prev_04',
            title: 'Course Evaluation Automated Aggregator',
            organization: 'LUMS Student Affairs',
            role: 'Backend & Mobile Developer',
            completionDate: 'July 2026',
            rating: 4.7,
            clientFeedback:
                'Hamza engineered robust API routes and integrated clean caching that handled high peak campus traffic seamlessly.',
          ),
        ],
        certificates: const [
          StudentCertificate(
            id: 'cert_04',
            title: 'AWS Certified Cloud Practitioner',
            issuer: 'Amazon Web Services',
            issueDate: 'January 2026',
            credentialId: 'AWS-CCP-1092',
            verificationUrl: 'https://aws.amazon.com/verification/1092',
          ),
        ],
      ),
      ApplicantModel(
        id: 'app_04',
        studentId: 'std_giki_04',
        projectId: 'proj_02',
        projectTitle: 'Barcode & QR Scanner Mobile Utility',
        name: 'Bilal Shah',
        email: 'bilal.shah@giki.edu.pk',
        university: 'GIKI Swabi',
        isEducationVerified: true,
        degree: 'BS Computer Engineering',
        department: 'Faculty of Computer Science & Engineering',
        semester: '8th Semester',
        cgpa: 3.75,
        skills: ['Dart', 'Camera API', 'SQLite', 'C++', 'Image Processing'],
        appliedDate: '2026-11-08',
        proposalSummary:
            'Experienced in high-performance hardware camera hooks and barcode extraction pipelines in Dart. I have built real-time barcode scanning systems for warehouse inventory management.',
        status: 'Under Review',
        avatarInitial: 'BS',
        portfolioUrl: 'https://github.com/bilalshah-giki',
        rating: 4.7,
        bio:
            'Computer engineer interested in hardware-accelerated mobile apps, camera sensor APIs, and local embedded databases.',
        resumeFileName: 'BilalShah_CV.pdf',
        portfolioProjects: const [
          StudentPortfolioItem(
            id: 'port_05',
            title: 'Warehouse QR Inventory Terminal',
            description:
                'Handheld scanner app with sub-second barcode parsing and offline queue sync.',
            techStack: ['Flutter', 'Camera Plugin', 'ZXing', 'SQLite'],
            projectUrl: 'https://github.com/bilalshah-giki/scanner-tool',
            attachmentName: 'ScannerTool_Specs.pdf',
            attachmentType: 'Report',
          ),
        ],
        previousProjects: const [
          PreviousProjectRecord(
            id: 'prev_05',
            title: 'Robotics Lab Sensor Dashboard',
            organization: 'GIKI Embedded Systems Lab',
            role: 'Firmware & Mobile App Engineer',
            completionDate: 'May 2026',
            rating: 4.9,
            clientFeedback:
                'Bilal is a dependable engineer who bridged low-level camera protocols into a snappy Flutter utility.',
          ),
        ],
        certificates: const [
          StudentCertificate(
            id: 'cert_05',
            title: 'Embedded Systems & Sensor Integration',
            issuer: 'IEEE Robotics & Automation Society',
            issueDate: 'March 2026',
            credentialId: 'IEEE-RAS-6621',
            verificationUrl: 'https://ieee.org/certs/6621',
          ),
        ],
      ),
      ApplicantModel(
        id: 'app_05',
        studentId: 'std_uet_05',
        projectId: 'proj_02',
        projectTitle: 'Barcode & QR Scanner Mobile Utility',
        name: 'Zainab Bibi',
        email: 'zainab.bibi@uettaxila.edu.pk',
        university: 'UET Taxila',
        isEducationVerified: true,
        degree: 'BS Computer Science',
        department: 'Department of Computer Science',
        semester: '7th Semester',
        cgpa: 3.55,
        skills: ['Flutter', 'Mobile Utilities', 'Local Storage', 'Dart'],
        appliedDate: '2026-11-05',
        proposalSummary:
            'Passionate mobile developer ready to build a clean scanning interface, batch scanning mode, and history export to CSV/JSON format.',
        status: 'Pending',
        avatarInitial: 'ZB',
        portfolioUrl: 'https://github.com/zainab-uet',
        rating: 4.5,
        bio:
            'Hardworking computer science student with a penchant for utility tools, clean user interfaces, and structured data handling.',
        resumeFileName: 'ZainabBibi_Resume.pdf',
        portfolioProjects: const [],
        previousProjects: const [],
        certificates: const [],
      ),
      ApplicantModel(
        id: 'app_06',
        studentId: 'std_pucit_06',
        projectId: 'proj_03',
        projectTitle: 'Corporate Sentiment Analysis Pipeline',
        name: 'Mustafa Hassan',
        email: 'mustafa.hassan@pucit.edu.pk',
        university: 'PUCIT Lahore',
        isEducationVerified: true,
        degree: 'MS Data Science',
        department: 'Department of Data Science & AI',
        semester: '3rd Semester (Graduate)',
        cgpa: 3.88,
        skills: ['Python', 'NLP', 'FastAPI', 'PyTorch', 'Transformers', 'Docker'],
        appliedDate: '2026-11-04',
        proposalSummary:
            'Published research on aspect-based sentiment classification. Can deliver a quantized FastAPI microservice with containerized deployment within 3 weeks.',
        status: 'Accepted',
        avatarInitial: 'MH',
        portfolioUrl: 'https://huggingface.co/mustafahassan',
        rating: 5.0,
        bio:
            'Graduate data science researcher specializing in natural language processing, transformer architectures, and latency-optimized API serving.',
        resumeFileName: 'MustafaHassan_MS_CV.pdf',
        portfolioProjects: const [
          StudentPortfolioItem(
            id: 'port_06',
            title: 'Urdu & Roman Urdu Sentiment Classifier',
            description:
                'Fine-tuned RoBERTa model achieving 92.4% accuracy on conversational Roman Urdu customer feedback.',
            techStack: ['Python', 'HuggingFace', 'FastAPI', 'PyTorch'],
            projectUrl: 'https://huggingface.co/mustafahassan/roman-urdu-sentiment',
            attachmentName: 'RomanUrdu_Research_Paper.pdf',
            attachmentType: 'Report',
          ),
        ],
        previousProjects: const [
          PreviousProjectRecord(
            id: 'prev_06',
            title: 'Automated Student Feedback Categorizer',
            organization: 'PUCIT Quality Enhancement Cell',
            role: 'Lead ML Engineer',
            completionDate: 'September 2026',
            rating: 5.0,
            clientFeedback:
                'Mustafa delivered production-grade ML code with comprehensive documentation and unit test coverage.',
          ),
        ],
        certificates: const [
          StudentCertificate(
            id: 'cert_06',
            title: 'TensorFlow Advanced Techniques Specialist',
            issuer: 'DeepLearning.AI',
            issueDate: 'February 2026',
            credentialId: 'DLAI-TF-3391',
            verificationUrl: 'https://coursera.org/verify/3391',
          ),
        ],
      ),
      ApplicantModel(
        id: 'app_07',
        studentId: 'std_cust_07',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        name: 'Danish Khan',
        email: 'danish.khan@cust.edu.pk',
        university: 'CUST Islamabad',
        isEducationVerified: false, // Unverified education to test unverified indicator
        degree: 'BS Software Engineering',
        department: 'Department of Software Engineering',
        semester: '3rd Semester',
        cgpa: 3.10,
        skills: ['HTML', 'CSS', 'Beginner Flutter', 'Git'],
        appliedDate: '2026-11-02',
        proposalSummary:
            'Looking for an internship opportunity to gain hands-on experience in commercial mobile apps under senior guidance.',
        status: 'Rejected',
        avatarInitial: 'DK',
        portfolioUrl: '',
        rating: 4.0,
        bio: 'Enthusiastic beginner developer eager to learn modern software stacks.',
        resumeFileName: 'DanishKhan_Resume.pdf',
        portfolioProjects: const [],
        previousProjects: const [],
        certificates: const [],
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

  // Find applicant by applicantId or studentId
  ApplicantModel? getApplicantById(String id) {
    try {
      return applicantsNotifier.value.firstWhere(
        (a) => a.id == id || a.studentId == id,
      );
    } catch (_) {
      return null;
    }
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
