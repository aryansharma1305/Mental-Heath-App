import '../models/assessment.dart';
import '../models/risk_level.dart';
import 'reminder_service.dart';

class ReviewQueueItem {
  final Assessment assessment;
  final DateTime dueAt;
  final int daysOverdue;
  final String reason;

  const ReviewQueueItem({
    required this.assessment,
    required this.dueAt,
    required this.daysOverdue,
    required this.reason,
  });

  bool get isOverdue => daysOverdue > 0;

  int get priority {
    final overdueBoost = isOverdue ? 1000 + daysOverdue : 0;
    return overdueBoost + (assessment.riskLevel.priority * 100);
  }
}

class ReviewQueueSummary {
  final int total;
  final int overdue;
  final int critical;
  final int high;
  final int refusals;

  const ReviewQueueSummary({
    required this.total,
    required this.overdue,
    required this.critical,
    required this.high,
    required this.refusals,
  });

  factory ReviewQueueSummary.fromItems(List<ReviewQueueItem> items) {
    return ReviewQueueSummary(
      total: items.length,
      overdue: items.where((item) => item.isOverdue).length,
      critical: items
          .where((item) => item.assessment.riskLevel == RiskLevel.critical)
          .length,
      high: items
          .where((item) => item.assessment.riskLevel == RiskLevel.high)
          .length,
      refusals: items.where((item) => item.assessment.isRefused).length,
    );
  }
}

class ReviewQueueService {
  ReviewQueueService({ReminderService? reminderService})
    : _reminderService = reminderService ?? ReminderService.instance;

  final ReminderService _reminderService;

  List<ReviewQueueItem> buildQueue(List<Assessment> assessments) {
    final latestByPatientAndType = <String, Assessment>{};
    for (final assessment in assessments) {
      final key = _queueKey(assessment);
      final existing = latestByPatientAndType[key];
      if (existing == null ||
          assessment.assessmentDate.isAfter(existing.assessmentDate)) {
        latestByPatientAndType[key] = assessment;
      }
    }

    final items =
        latestByPatientAndType.values
            .where(_reminderService.needsFollowUp)
            .map(_toItem)
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

    return items;
  }

  ReviewQueueSummary summary(List<Assessment> assessments) {
    return ReviewQueueSummary.fromItems(buildQueue(assessments));
  }

  ReviewQueueItem _toItem(Assessment assessment) {
    final dueAt = _reminderService.dueDate(assessment);
    final daysOverdue = _reminderService.daysOverdue(assessment);
    return ReviewQueueItem(
      assessment: assessment,
      dueAt: dueAt,
      daysOverdue: daysOverdue,
      reason: _reason(assessment),
    );
  }

  String _reason(Assessment assessment) {
    if (assessment.isRefused) return 'Consent refusal needs re-attempt';
    if (assessment.riskLevel == RiskLevel.critical) {
      return 'Critical risk follow-up required';
    }
    if (assessment.riskLevel == RiskLevel.high) {
      return 'High risk follow-up required';
    }
    return 'Clinician recommended follow-up';
  }

  String _queueKey(Assessment assessment) =>
      '${assessment.patientId.trim()}::${assessment.decisionContext.trim()}';
}
