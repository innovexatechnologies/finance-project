import 'package:link_vibe/core/services/supabase_helper.dart';

class CompanyStudentPaymentDetails {
  final String? provider;
  final String? accountNumber;

  const CompanyStudentPaymentDetails({
    this.provider,
    this.accountNumber,
  });
}

class CompanyPaymentDetailsService {
  Future<CompanyStudentPaymentDetails?> loadForAssignment(
    String applicationId,
  ) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      throw StateError('Sign in to load assigned student payment details.');
    }
    if (!SupabaseHelper.isUuid(applicationId)) {
      throw ArgumentError.value(
        applicationId,
        'applicationId',
        'A valid application ID is required.',
      );
    }

    final result = await supabase.rpc(
      'get_assigned_student_payment_details',
      params: {'p_application_id': applicationId},
    );
    if (result is! List) {
      throw const FormatException(
        'Unexpected response while loading payment details.',
      );
    }
    if (result.isEmpty) return null;

    final row = result.first;
    if (row is! Map) {
      throw const FormatException(
        'Unexpected response while loading payment details.',
      );
    }

    return CompanyStudentPaymentDetails(
      provider: row['provider']?.toString(),
      accountNumber: row['account_number']?.toString(),
    );
  }

  Future<void> confirmAssignment(String applicationId) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      throw StateError('Sign in to confirm this project assignment.');
    }
    if (!SupabaseHelper.isUuid(applicationId)) {
      throw ArgumentError.value(
        applicationId,
        'applicationId',
        'A valid application ID is required.',
      );
    }

    await supabase.rpc(
      'assign_applicant_to_project',
      params: {
        'p_application_id': applicationId,
        'p_confirm_existing': true,
      },
    );
  }
}
