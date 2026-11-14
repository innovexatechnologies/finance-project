import 'package:flutter_test/flutter_test.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final applicantService = CompanyApplicantService();
  final projectService = CompanyProjectService();

  setUp(() {
    applicantService.reset();
    projectService.reset();
  });

  test(
    'only one applicant is accepted and remaining applicants are rejected',
    () async {
      projectService.projectsNotifier.value = [
        ProjectModel(
          id: 'project-1',
          title: 'Project',
          category: 'Development',
          description: '',
          requirements: '',
          skillsRequired: const [],
          deliverables: '',
          deadline: 'Flexible',
          projectType: 'Remote',
          openings: 1,
          additionalInstructions: '',
          companyName: 'Company',
          companyId: 'company-1',
          status: 'Open',
        ),
      ];
      applicantService.applicantsNotifier.value = [
        _applicant('application-1', 'Pending'),
        _applicant('application-2', 'Shortlisted'),
      ];

      final accepted = await applicantService.updateApplicantStatus(
        applicantId: 'application-1',
        newStatus: 'Accepted',
      );

      expect(accepted, isTrue);
      expect(
        applicantService.allApplicants.map((applicant) => applicant.status),
        ['Accepted', 'Rejected'],
      );

      final secondAssignment = await applicantService.updateApplicantStatus(
        applicantId: 'application-2',
        newStatus: 'Accepted',
      );

      expect(secondAssignment, isFalse);
      expect(applicantService.getAcceptedCount('project-1'), 1);
    },
  );
}

ApplicantModel _applicant(String id, String status) {
  return ApplicantModel(
    id: id,
    studentId: 'student-$id',
    projectId: 'project-1',
    name: id,
    email: '$id@example.com',
    university: 'University',
    degree: 'BSCS',
    cgpa: 3.5,
    skills: const [],
    appliedDate: 'Today',
    proposalSummary: 'Application',
    status: status,
  );
}
