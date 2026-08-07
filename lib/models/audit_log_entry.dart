import 'dart:convert';

class AuditLogEntry {
  final int? id;
  final String action;
  final String entityType;
  final String entityId;
  final String? patientId;
  final String? actorName;
  final String? actorUserId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AuditLogEntry({
    this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.patientId,
    this.actorName,
    this.actorUserId,
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'patient_id': patientId,
      'actor_name': actorName,
      'actor_user_id': actorUserId,
      'created_at': createdAt.toIso8601String(),
      'metadata': jsonEncode(metadata),
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] as int?,
      action: map['action']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      patientId: map['patient_id'] as String?,
      actorName: map['actor_name'] as String?,
      actorUserId: map['actor_user_id'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      metadata: _parseMetadata(map['metadata']),
    );
  }

  static Map<String, dynamic> _parseMetadata(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}
