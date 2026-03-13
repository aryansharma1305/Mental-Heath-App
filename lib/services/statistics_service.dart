import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assessment.dart';
import 'database_service.dart';
import 'supabase_service.dart';

class StatisticsService {
  final DatabaseService _databaseService = DatabaseService();
  final SupabaseService _supabaseService = SupabaseService();

  /// Get DSM-5 assessments from SharedPreferences (local storage)
  Future<List<Map<String, dynamic>>> _getDsm5Assessments() async {
    final prefs = await SharedPreferences.getInstance();
    final dsm5Data = prefs.getString('dsm5_assessments');
    if (dsm5Data == null) return [];
    
    try {
      final List<dynamic> assessments = jsonDecode(dsm5Data);
      return assessments.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Get MHCA assessments from SharedPreferences
  Future<List<Map<String, dynamic>>> _getMhcaAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('mhca_assessments') ?? [];
    try {
      return jsonList
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    // 1. Get local SQLite assessments (primary source)
    List<Assessment> localAssessments = [];
    try {
      localAssessments = await _databaseService.getAllAssessments();
    } catch (e) {
      // Ignore DB errors
    }

    // 2. Get DSM-5 local assessments from SharedPreferences
    final dsm5Assessments = await _getDsm5Assessments();

    // 3. Get MHCA assessments from SharedPreferences
    final mhcaAssessments = await _getMhcaAssessments();

    // 4. Get Supabase assessments if available
    List<Assessment> supabaseAssessments = [];
    if (SupabaseService.isAvailable) {
      try {
        supabaseAssessments = await _supabaseService.getAllAssessments();
      } catch (e) {
        // Ignore Supabase errors
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);

    // ---- Count local SQLite assessments ----
    int todayLocal = 0;
    int weekLocal = 0;
    int monthLocal = 0;
    final localByDate = <DateTime, int>{};
    final capacityStats = <String, int>{};

    for (final a in localAssessments) {
      final dateOnly = DateTime(a.assessmentDate.year, a.assessmentDate.month, a.assessmentDate.day);
      if (dateOnly.isAtSameMomentAs(today)) todayLocal++;
      if (a.assessmentDate.isAfter(thisWeek) || a.assessmentDate.isAtSameMomentAs(thisWeek)) weekLocal++;
      if (a.assessmentDate.isAfter(thisMonth) || a.assessmentDate.isAtSameMomentAs(thisMonth)) monthLocal++;
      localByDate[dateOnly] = (localByDate[dateOnly] ?? 0) + 1;

      // Capacity distribution
      final capacity = a.overallCapacity;
      if (capacity.isNotEmpty) {
        capacityStats[capacity] = (capacityStats[capacity] ?? 0) + 1;
      }
    }

    // ---- Count DSM-5 assessments ----
    int todayDsm5 = 0;
    int weekDsm5 = 0;
    int monthDsm5 = 0;
    
    for (final assessment in dsm5Assessments) {
      final dateStr = assessment['assessment_date'] ?? assessment['created_at'] ?? '';
      final assessmentDate = DateTime.tryParse(dateStr) ?? now;
      final dateOnly = DateTime(assessmentDate.year, assessmentDate.month, assessmentDate.day);
      
      if (dateOnly.isAtSameMomentAs(today)) todayDsm5++;
      if (assessmentDate.isAfter(thisWeek) || assessmentDate.isAtSameMomentAs(thisWeek)) weekDsm5++;
      if (assessmentDate.isAfter(thisMonth) || assessmentDate.isAtSameMomentAs(thisMonth)) monthDsm5++;
      
      localByDate[dateOnly] = (localByDate[dateOnly] ?? 0) + 1;
      
      final severity = (assessment['severity'] ?? 'Unknown') as String;
      capacityStats['DSM-5: $severity'] = (capacityStats['DSM-5: $severity'] ?? 0) + 1;
    }

    // ---- Count MHCA SharedPreferences assessments ----
    int todayMhca = 0;
    int weekMhca = 0;
    int monthMhca = 0;

    for (final assessment in mhcaAssessments) {
      final dateStr = assessment['created_at'] ?? assessment['assessment_date'] ?? '';
      final assessmentDate = DateTime.tryParse(dateStr) ?? now;
      final dateOnly = DateTime(assessmentDate.year, assessmentDate.month, assessmentDate.day);
      
      if (dateOnly.isAtSameMomentAs(today)) todayMhca++;
      if (assessmentDate.isAfter(thisWeek) || assessmentDate.isAtSameMomentAs(thisWeek)) weekMhca++;
      if (assessmentDate.isAfter(thisMonth) || assessmentDate.isAtSameMomentAs(thisMonth)) monthMhca++;
      
      localByDate[dateOnly] = (localByDate[dateOnly] ?? 0) + 1;

      final determination = (assessment['determination'] ?? 'Unknown') as String;
      if (determination.isNotEmpty) {
        capacityStats['MHCA: $determination'] = (capacityStats['MHCA: $determination'] ?? 0) + 1;
      }
    }

    // ---- Count Supabase assessments (avoid double-counting) ----
    // We only add Supabase assessments that are NOT already in localAssessments
    int todaySupabase = 0;
    int weekSupabase = 0;
    int monthSupabase = 0;
    final localIds = localAssessments.map((a) => a.patientId).toSet();
    
    for (final a in supabaseAssessments) {
      // Skip if already counted in local
      if (localIds.contains(a.patientId)) continue;

      final dateOnly = DateTime(a.assessmentDate.year, a.assessmentDate.month, a.assessmentDate.day);
      if (dateOnly.isAtSameMomentAs(today)) todaySupabase++;
      if (a.assessmentDate.isAfter(thisWeek) || a.assessmentDate.isAtSameMomentAs(thisWeek)) weekSupabase++;
      if (a.assessmentDate.isAfter(thisMonth) || a.assessmentDate.isAtSameMomentAs(thisMonth)) monthSupabase++;
      localByDate[dateOnly] = (localByDate[dateOnly] ?? 0) + 1;
      capacityStats[a.overallCapacity] = (capacityStats[a.overallCapacity] ?? 0) + 1;
    }
    
    // ---- Combine counts ----
    final totalAssessments = localAssessments.length + dsm5Assessments.length + mhcaAssessments.length + 
        supabaseAssessments.where((a) => !localIds.contains(a.patientId)).length;
    final todayAssessments = todayLocal + todayDsm5 + todayMhca + todaySupabase;
    final weekAssessments = weekLocal + weekDsm5 + weekMhca + weekSupabase;
    final monthAssessments = monthLocal + monthDsm5 + monthMhca + monthSupabase;
    
    // Recent activity (last 7 days)
    final recentActivity = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      recentActivity[date] = localByDate[date] ?? 0;
    }
    
    // Top assessors (from local DB + Supabase)
    final assessorStats = <String, int>{};
    for (final a in localAssessments) {
      if (a.assessorName.isNotEmpty) {
        assessorStats[a.assessorName] = (assessorStats[a.assessorName] ?? 0) + 1;
      }
    }
    for (final a in supabaseAssessments) {
      if (!localIds.contains(a.patientId)) {
        assessorStats[a.assessorName] = (assessorStats[a.assessorName] ?? 0) + 1;
      }
    }
    // Add MHCA assessors
    for (final a in mhcaAssessments) {
      final name = (a['assessor_name'] ?? a['doctor_name'] ?? '') as String;
      if (name.isNotEmpty) {
        assessorStats[name] = (assessorStats[name] ?? 0) + 1;
      }
    }
    
    final topAssessors = assessorStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'totalAssessments': totalAssessments,
      'todayAssessments': todayAssessments,
      'weekAssessments': weekAssessments,
      'monthAssessments': monthAssessments,
      'capacityDistribution': capacityStats,
      'recentActivity': recentActivity,
      'topAssessors': topAssessors.take(5).toList(),
      'averagePerDay': totalAssessments > 0 ? (totalAssessments / 7).toStringAsFixed(1) : '0',
    };
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrends() async {
    // Use local SQLite data as primary source (works offline)
    List<Assessment> allAssessments = [];
    try {
      allAssessments = await _databaseService.getAllAssessments();
    } catch (e) {
      // Ignore
    }

    // Also add Supabase if available
    if (SupabaseService.isAvailable) {
      try {
        final supabaseAssessments = await _supabaseService.getAllAssessments();
        final localIds = allAssessments.map((a) => a.patientId).toSet();
        allAssessments.addAll(
          supabaseAssessments.where((a) => !localIds.contains(a.patientId))
        );
      } catch (e) {
        // Ignore
      }
    }

    // Also include MHCA assessments from SharedPreferences
    final mhcaAssessments = await _getMhcaAssessments();

    final monthlyData = <String, Map<String, int>>{};

    // Process local DB assessments
    for (final assessment in allAssessments) {
      final monthKey = '${assessment.assessmentDate.year}-${assessment.assessmentDate.month.toString().padLeft(2, '0')}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'total': 0,
          'hasCapacity': 0,
          'lacksCapacity': 0,
          'other': 0,
        };
      }
      
      monthlyData[monthKey]!['total'] = monthlyData[monthKey]!['total']! + 1;
      
      final capacity = assessment.overallCapacity.toLowerCase();
      if (capacity.contains('has capacity')) {
        monthlyData[monthKey]!['hasCapacity'] = monthlyData[monthKey]!['hasCapacity']! + 1;
      } else if (capacity.contains('lacks capacity') || capacity.contains('needs 100%')) {
        monthlyData[monthKey]!['lacksCapacity'] = monthlyData[monthKey]!['lacksCapacity']! + 1;
      } else {
        monthlyData[monthKey]!['other'] = monthlyData[monthKey]!['other']! + 1;
      }
    }

    // Process MHCA SharedPreferences assessments
    for (final assessment in mhcaAssessments) {
      final dateStr = assessment['created_at'] ?? assessment['assessment_date'] ?? '';
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'total': 0,
          'hasCapacity': 0,
          'lacksCapacity': 0,
          'other': 0,
        };
      }

      monthlyData[monthKey]!['total'] = monthlyData[monthKey]!['total']! + 1;

      final determination = (assessment['determination'] ?? '').toString().toLowerCase();
      if (determination.contains('has capacity')) {
        monthlyData[monthKey]!['hasCapacity'] = monthlyData[monthKey]!['hasCapacity']! + 1;
      } else if (determination.contains('needs 100%')) {
        monthlyData[monthKey]!['lacksCapacity'] = monthlyData[monthKey]!['lacksCapacity']! + 1;
      } else {
        monthlyData[monthKey]!['other'] = monthlyData[monthKey]!['other']! + 1;
      }
    }
    
    // If no data yet, return empty
    if (monthlyData.isEmpty) return [];

    final result = monthlyData.entries.map((entry) => {
      'month': entry.key,
      ...entry.value,
    }).toList();
    result.sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
    return result;
  }

  Future<Map<String, dynamic>> getAssessorPerformance(String assessorName) async {
    // Use local DB as primary source
    List<Assessment> allAssessments = [];
    try {
      allAssessments = await _databaseService.getAllAssessments();
    } catch (e) {
      // Ignore
    }

    if (SupabaseService.isAvailable) {
      try {
        final supabaseAssessments = await _supabaseService.getAllAssessments();
        final localIds = allAssessments.map((a) => a.patientId).toSet();
        allAssessments.addAll(
          supabaseAssessments.where((a) => !localIds.contains(a.patientId))
        );
      } catch (e) {
        // Ignore
      }
    }
    
    final userAssessments = allAssessments.where((a) => a.assessorName == assessorName).toList();
    
    if (userAssessments.isEmpty) {
      return {
        'totalAssessments': 0,
        'averagePerWeek': 0.0,
        'capacityDistribution': <String, int>{},
        'recentAssessments': <Assessment>[],
      };
    }
    
    final capacityDistribution = <String, int>{};
    for (final assessment in userAssessments) {
      capacityDistribution[assessment.overallCapacity] = 
          (capacityDistribution[assessment.overallCapacity] ?? 0) + 1;
    }
    
    final firstAssessment = userAssessments.last.createdAt;
    final daysSinceFirst = DateTime.now().difference(firstAssessment).inDays + 1;
    final averagePerWeek = (userAssessments.length / daysSinceFirst * 7).toStringAsFixed(1);
    
    return {
      'totalAssessments': userAssessments.length,
      'averagePerWeek': double.parse(averagePerWeek),
      'capacityDistribution': capacityDistribution,
      'recentAssessments': userAssessments.take(5).toList(),
    };
  }
}