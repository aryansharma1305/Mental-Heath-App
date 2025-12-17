enum QuestionType {
  yesNo,
  multipleChoice,
  textInput,
  scale,
  date
}

class Question {
  final int? id;
  final String text;
  final QuestionType type;
  final List<String>? options;
  final bool required;
  final String? category;
  final int order;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    this.id,
    required this.text,
    required this.type,
    this.options,
    this.required = true,
    this.category,
    this.order = 0,
    this.isActive = true,
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get questionId => id?.toString() ?? 'temp_${text.hashCode}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': text,
      'question_type': type.name,
      'options': options != null ? options!.join('|||') : null,
      'required': required ? 1 : 0,
      'category': category,
      'order_index': order,
      'is_active': isActive ? 1 : 0,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      text: map['question_text'] ?? '',
      type: QuestionType.values.firstWhere(
        (t) => t.name == map['question_type'],
        orElse: () => QuestionType.textInput,
      ),
      options: map['options'] != null
          ? (map['options'] as String).split('|||')
          : null,
      required: map['required'] == 1 || map['required'] == true,
      category: map['category'],
      order: map['order_index'] ?? 0,
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

  Question copyWith({
    int? id,
    String? text,
    QuestionType? type,
    List<String>? options,
    bool? required,
    String? category,
    int? order,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
      required: required ?? this.required,
      category: category ?? this.category,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuestionResponse {
  final String questionId;
  final dynamic answer;
  final String? notes;

  QuestionResponse({
    required this.questionId,
    required this.answer,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'answer': answer,
      'notes': notes,
    };
  }
}