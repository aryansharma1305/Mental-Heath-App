import '../models/assessment.dart';
import 'supabase_service.dart';

class StatisticsService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    if (!SupabaseService.isAvailable) {
      return {
        'totalAssessments': 0,
        'todayAssessments': 0,
        'weekAssessments': 0,
        'monthAssessments': 0,
        'capacityDistribution': <String, int>{},
        'recentActivity': <DateTime, int>{},
        'topAssessors': <MapEntry<String, int>>[],
        'averagePerDay': '0',
      };
    }
    
    final assessments = await _supabaseService.getAllAssessments();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);
    
    // Total assessments
    final totalAssessments = assessments.length;
    
    // Today's assessments
    final todayAssessments = assessments.where((a) {
      final assessmentDate = DateTime(
        a.assessmentDate.year,
        a.assessmentDate.month,
        a.assessmentDate.day,
      );
      return assessmentDate.isAtSameMomentAs(today);
    }).length;
    
    // This week's assessments
    final weekAssessments = assessments.where((a) {
      return a.assessmentDate.isAfter(thisWeek) || 
             a.assessmentDate.isAtSameMomentAs(thisWeek);
    }).length;
    
    // This month's assessments
    final monthAssessments = assessments.where((a) {
      return a.assessmentDate.isAfter(thisMonth) || 
             a.assessmentDate.isAtSameMomentAs(thisMonth);
    }).length;
    
    // Capacity distribution
    final capacityStats = <String, int>{};
    for (final assessment in assessments) {
      capacityStats[assessment.overallCapacity] = 
          (capacityStats[assessment.overallCapacity] ?? 0) + 1;
    }
    
    // Recent activity (last 7 days)
    final recentActivity = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final count = assessments.where((a) {
        final assessmentDate = DateTime(
          a.assessmentDate.year,
          a.assessmentDate.month,
          a.assessmentDate.day,
        );
        return assessmentDate.isAtSameMomentAs(date);
      }).length;
      recentActivity[date] = count;
    }
    
    // Top assessors
    final assessorStats = <String, int>{};
    for (final assessment in assessments) {
      assessorStats[assessment.assessorName] = 
          (assessorStats[assessment.assessorName] ?? 0) + 1;
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
      'averagePerDay': totalAssessments > 0 
          ? (totalAssessments / (assessments.isNotEmpty 
              ? DateTime.now().difference(assessments.last.createdAt).inDays + 1 
              : 1)).toStringAsFixed(1)
          : '0',
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