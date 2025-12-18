import 'question.dart';

class AssessmentTemplate {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Question>? questions; // Questions in this template

  AssessmentTemplate({
    this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.questions,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AssessmentTemplate.fromMap(Map<String, dynamic> map) {
    return AssessmentTemplate(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdBy: map['created_by'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  AssessmentTemplate copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Question>? questions,
  }) {
    return AssessmentTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
    );
  }
}

