enum UserRole {
  patient('Patient', 'Normal user who can answer questionnaires'),
  doctor('Doctor', 'Healthcare professional who can review assessments'),
  psychiatrist('Psychiatrist', 'Mental health specialist who can review assessments'),
  admin('Admin', 'Administrator who can manage questions and system settings');

  final String displayName;
  final String description;

  const UserRole(this.displayName, this.description);

  bool get canReviewAssessments => this == doctor || this == psychiatrist || this == admin;
  bool get canManageQuestions => this == admin;
  bool get canAnswerQuestionnaires => this == patient || this == admin;
  bool get isHealthcareProfessional => this == doctor || this == psychiatrist || this == admin;
}

