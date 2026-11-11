import 'package:flutter/material.dart';

/// Clears active focus, empties every controller in [controllers], and clears
/// any visible validation errors on [formKey] when switching portal roles.
void resetAuthRoleForm({
  required GlobalKey<FormState> formKey,
  required List<TextEditingController> controllers,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  for (final controller in controllers) {
    controller.clear();
  }
  formKey.currentState?.clearError();
}

