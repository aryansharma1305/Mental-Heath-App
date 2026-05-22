import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/assessment.dart';
import '../models/risk_level.dart';

// ---------------------------------------------------------------------------
// Risk-based reminder intervals
// ---------------------------------------------------------------------------
class ReminderInterval {
  static Duration forRisk(RiskLevel level) => switch (level) {
        RiskLevel.critical => const Duration(days: 7),
        RiskLevel.high => const Duration(days: 14),
        RiskLevel.moderate => const Duration(days: 30),
        RiskLevel.low => const Duration(days: 90),
      };

  static String labelForRisk(RiskLevel level) => switch (level) {
        RiskLevel.critical => '7 days',
        RiskLevel.high => '14 days',
        RiskLevel.moderate => '30 days',
        RiskLevel.low => '90 days',
      };
}

// ---------------------------------------------------------------------------
// ReminderService — singleton
// ---------------------------------------------------------------------------
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _enabledKey = 'reminders_enabled';
  bool _initialised = false;

  // -------------------------------------------------------------------------
  // Initialisation — call once from main() after WidgetsFlutterBinding
  // -------------------------------------------------------------------------
  Future<void> init() async {
    if (_initialised) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      // Do NOT request permission here — ask at the right clinical moment.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialised = true;
    debugPrint('✅ ReminderService initialised');
  }

  // -------------------------------------------------------------------------
  // Schedule a follow-up reminder after saving an assessment.
  // Refusals also get a reminder — patient may be willing later.
  // -------------------------------------------------------------------------
  Future<void> scheduleFollowUp({
    required Assessment assessment,
    required String patientName,
  }) async {
    if (!await _isEnabled()) return;

    final needsReminder = assessment.isRefused ||
        assessment.structuredRecommendations.followUpRecommended;
    if (!needsReminder) return;

    // Request iOS permission at the first clinical moment.
    if (Platform.isIOS) {
      final granted = await _requestIosPermission();
      if (!granted) {
        debugPrint('⚠️ ReminderService: iOS permission denied — '
            'in-app overdue banners only.');
        return;
      }
    }

    final due = dueDate(assessment);
    // Don't schedule if due date is already in the past (e.g. imported record).
    if (due.isBefore(DateTime.now())) return;

    final id = _notificationId(assessment.patientId);
    final tzDue = tz.TZDateTime.from(due, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'follow_up_reminders',
      'Follow-Up Reminders',
      channelDescription:
          'Clinical follow-up reminders for mental capacity assessments',
      importance: Importance.high,
      priority: Priority.high,
      color: assessment.riskLevel.color,
      enableLights: true,
      ledColor: assessment.riskLevel.color,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'follow_up',
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final title = _titleForRisk(assessment.riskLevel);
    final body =
        '$patientName — ${ReminderInterval.labelForRisk(assessment.riskLevel)} '
        'follow-up assessment is due today.';

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDue,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: _buildPayload(assessment),
    );

    debugPrint('📅 Reminder scheduled: patient=${assessment.patientId} '
        'due=${due.toIso8601String()} risk=${assessment.riskLevel.name}');
  }

  // -------------------------------------------------------------------------
  // Cancel reminder when a follow-up assessment is saved for this patient.
  // -------------------------------------------------------------------------
  Future<void> cancelFollowUp(String patientId) async {
    await _plugin.cancel(_notificationId(patientId));
    debugPrint('🗑️ Reminder cancelled for patient=$patientId');
  }

  // -------------------------------------------------------------------------
  // Pure helpers — used by OverdueBanner and list indicators.
  // -------------------------------------------------------------------------

  /// The datetime when a follow-up is due, based on risk level + createdAt.
  DateTime dueDate(Assessment assessment) =>
      assessment.createdAt.add(ReminderInterval.forRisk(assessment.riskLevel));

  /// True when now is past the due date and a follow-up was recommended.
  bool overdueFor(Assessment assessment) {
    final needsReminder = assessment.isRefused ||
        assessment.structuredRecommendations.followUpRecommended;
    if (!needsReminder) return false;
    return DateTime.now().isAfter(dueDate(assessment));
  }

  /// Days overdue (0 if not overdue or not past due).
  int daysOverdue(Assessment assessment) {
    if (!overdueFor(assessment)) return 0;
    return DateTime.now().difference(dueDate(assessment)).inDays;
  }

  // -------------------------------------------------------------------------
  // Settings helpers
  // -------------------------------------------------------------------------
  Future<bool> remindersEnabled() async => _isEnabled();

  Future<void> setRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) {
      await _plugin.cancelAll();
      debugPrint('🔕 All reminders cancelled (globally disabled)');
    }
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------
  Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<bool> _requestIosPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return false;
    final granted = await ios.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  /// Stable int ID from patientId — same patient always maps to same slot,
  /// so rescheduling replaces rather than stacks.
  int _notificationId(String patientId) =>
      patientId.hashCode.abs() % 2147483647;

  String _titleForRisk(RiskLevel level) => switch (level) {
        RiskLevel.critical => '🔴 Critical: Follow-Up Due',
        RiskLevel.high => '🟠 High Risk: Follow-Up Due',
        RiskLevel.moderate => '🟡 Follow-Up Assessment Due',
        RiskLevel.low => '🟢 Follow-Up Reminder',
      };

  String _buildPayload(Assessment a) =>
      'patientId=${a.patientId}&assessmentType=mhca&action=follow_up';

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: payload=${response.payload}');
    // Deep-link routing wired via GlobalKey<NavigatorState> in main.dart.
  }
}
