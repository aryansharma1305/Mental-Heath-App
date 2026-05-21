import 'dart:convert';

class AssessmentRecommendations {
  final bool followUpRecommended;
  final bool referToSpecialist;
  final bool noFurtherAction;
  final String? freeText;

  const AssessmentRecommendations({
    this.followUpRecommended = false,
    this.referToSpecialist = false,
    this.noFurtherAction = false,
    this.freeText,
  });

  bool get hasAnySelection =>
      followUpRecommended ||
      referToSpecialist ||
      noFurtherAction ||
      (freeText?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
    'follow_up': followUpRecommended,
    'refer': referToSpecialist,
    'no_action': noFurtherAction,
    'notes': freeText,
  };

  String toStorageJson() => jsonEncode(toJson());

  factory AssessmentRecommendations.fromJson(Map<String, dynamic> json) {
    return AssessmentRecommendations(
      followUpRecommended: json['follow_up'] == true,
      referToSpecialist: json['refer'] == true,
      noFurtherAction: json['no_action'] == true,
      freeText: json['notes']?.toString(),
    );
  }

  factory AssessmentRecommendations.fromStorage(dynamic value) {
    if (value == null) return const AssessmentRecommendations();
    if (value is AssessmentRecommendations) return value;
    if (value is Map) {
      return AssessmentRecommendations.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return AssessmentRecommendations.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        return AssessmentRecommendations(freeText: value);
      }
    }
    return const AssessmentRecommendations();
  }

  String toLegacySummary() {
    final parts = <String>[];
    if (followUpRecommended) {
      parts.add('Follow-up assessment recommended');
    }
    if (referToSpecialist) {
      parts.add('Refer to specialist');
    }
    if (noFurtherAction) {
      parts.add('No further action at this time');
    }
    final notes = freeText?.trim();
    if (notes != null && notes.isNotEmpty) {
      parts.add(notes);
    }
    return parts.join(' | ');
  }
}
