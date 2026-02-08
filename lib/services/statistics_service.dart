import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assessment.dart';
import 'supabase_service.dart';

class StatisticsService {
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

  Future<Map<String, dynamic>> getDashboardStats() async {
    // Get DSM-5 local assessments first
    final dsm5Assessments = await _getDsm5Assessments();
    
    // Also get Supabase assessments if available
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
    
    // Count DSM-5 assessments
    int totalDsm5 = dsm5Assessments.length;
    int todayDsm5 = 0;
    int weekDsm5 = 0;
    int monthDsm5 = 0;
    final dsm5ByDate = <DateTime, int>{};
    final dsm5Severity = <String, int>{};
    
    for (final assessment in dsm5Assessments) {
      final dateStr = assessment['assessment_date'] ?? '';
      final assessmentDate = DateTime.tryParse(dateStr) ?? now;
      final dateOnly = DateTime(assessmentDate.year, assessmentDate.month, assessmentDate.day);
      
      if (dateOnly.isAtSameMomentAs(today)) todayDsm5++;
      if (assessmentDate.isAfter(thisWeek) || assessmentDate.isAtSameMomentAs(thisWeek)) weekDsm5++;
      if (assessmentDate.isAfter(thisMonth) || assessmentDate.isAtSameMomentAs(thisMonth)) monthDsm5++;
      
      dsm5ByDate[dateOnly] = (dsm5ByDate[dateOnly] ?? 0) + 1;
      
      final severity = (assessment['severity'] ?? 'Unknown') as String;
      dsm5Severity[severity] = (dsm5Severity[severity] ?? 0) + 1;
    }
    
    // Count Supabase assessments
    int totalSupabase = supabaseAssessments.length;
    int todaySupabase = 0;
    int weekSupabase = 0;
    int monthSupabase = 0;
    
    for (final a in supabaseAssessments) {
      final dateOnly = DateTime(a.assessmentDate.year, a.assessmentDate.month, a.assessmentDate.day);
      if (dateOnly.isAtSameMomentAs(today)) todaySupabase++;
      if (a.assessmentDate.isAfter(thisWeek) || a.assessmentDate.isAtSameMomentAs(thisWeek)) weekSupabase++;
      if (a.assessmentDate.isAfter(thisMonth) || a.assessmentDate.isAtSameMomentAs(thisMonth)) monthSupabase++;
    }
    
    // Combine counts
    final totalAssessments = totalDsm5 + totalSupabase;
    final todayAssessments = todayDsm5 + todaySupabase;
    final weekAssessments = weekDsm5 + weekSupabase;
    final monthAssessments = monthDsm5 + monthSupabase;
    
    // Capacity distribution (combine DSM-5 severity with Supabase capacity)
    final capacityStats = <String, int>{};
    for (final entry in dsm5Severity.entries) {
      capacityStats['DSM-5: ${entry.key}'] = entry.value;
    }
    for (final assessment in supabaseAssessments) {
      capacityStats[assessment.overallCapacity] = (capacityStats[assessment.overallCapacity] ?? 0) + 1;
    }
    
    // Recent activity (last 7 days) - combine both sources
    final recentActivity = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      int count = dsm5ByDate[date] ?? 0;
      
      // Add Supabase counts for this date
      count += supabaseAssessments.where((a) {
        final assessmentDate = DateTime(a.assessmentDate.year, a.assessmentDate.month, a.assessmentDate.day);
        return assessmentDate.isAtSameMomentAs(date);
      }).length;
      
      recentActivity[date] = count;
    }
    
    // Top assessors (from Supabase only, DSM-5 doesn't track assessor)
    final assessorStats = <String, int>{};
    for (final assessment in supabaseAssessments) {
      assessorStats[assessment.assessorName] = (assessorStats[assessment.assessorName] ?? 0) + 1;
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
    if (!SupabaseService.isAvailable) return [];
    
    final assessments = await _supabaseService.getAllAssessments();
    final monthlyData = <String, Map<String, int>>{};
    
    for (final assessment in assessments) {
      final monthKey = '${assessment.assessmentDate.year}-${assessment.assessmentDate.month.toString().padLeft(2, '0')}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'total': 0,
          'hasCapacity': 0,
          'lacksCapacity': 0,
          'fluctuating': 0,
          'undetermined': 0,
        };
      }
      
      monthlyData[monthKey]!['total'] = monthlyData[monthKey]!['total']! + 1;
      
      switch (assessment.overallCapacity.toLowerCase()) {
        case 'has capacity for this decision':
          monthlyData[monthKey]!['hasCapacity'] = monthlyData[monthKey]!['hasCapacity']! + 1;
          break;
        case 'lacks capacity for this decision':
          monthlyData[monthKey]!['lacksCapacity'] = monthlyData[monthKey]!['lacksCapacity']! + 1;
          break;
        case 'fluctuating capacity - reassessment needed':
          monthlyData[monthKey]!['fluctuating'] = monthlyData[monthKey]!['fluctuating']! + 1;
          break;
        default:
          monthlyData[monthKey]!['undetermined'] = monthlyData[monthKey]!['undetermined']! + 1;
      }
    }
    
    final result = monthlyData.entries.map((entry) => {
      'month': entry.key,
      ...entry.value,
    }).toList();
    result.sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
    return result;
  }

  Future<Map<String, dynamic>> getAssessorPerformance(String assessorName) async {
    if (!SupabaseService.isAvailable) {
      return {
        'totalAssessments': 0,
        'averagePerWeek': 0.0,
        'capacityDistribution': <String, int>{},
        'recentAssessments': <Assessment>[],
      };
    }
    
    final assessments = await _supabaseService.getAllAssessments();
    final userAssessments = assessments.where((a) => a.assessorName == assessorName).toList();
    
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