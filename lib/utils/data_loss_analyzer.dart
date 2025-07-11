import 'package:flutter/foundation.dart';

/// 数据丢失分析器
class DataLossAnalyzer {
  /// 分析数据丢失情况
  static Map<String, dynamic> analyzeDataLoss({
    required int originalCount,
    required int finalCount,
    required List<Map<String, dynamic>> errorLogs,
    required List<Map<String, dynamic>> filterLogs,
  }) {
    final lostCount = originalCount - finalCount;
    final lossRate = (lostCount / originalCount) * 100;
    
    // 分析错误类型
    final errorAnalysis = _analyzeErrors(errorLogs);
    
    // 分析过滤情况
    final filterAnalysis = _analyzeFilters(filterLogs);
    
    return {
      'summary': {
        'originalCount': originalCount,
        'finalCount': finalCount,
        'lostCount': lostCount,
        'lossRate': lossRate,
        'successRate': 100 - lossRate,
      },
      'errorAnalysis': errorAnalysis,
      'filterAnalysis': filterAnalysis,
      'recommendations': _generateRecommendations(errorAnalysis, filterAnalysis),
    };
  }
  
  /// 分析错误类型
  static Map<String, dynamic> _analyzeErrors(List<Map<String, dynamic>> errorLogs) {
    final errorCounts = <String, int>{};
    final errorDetails = <String, List<String>>{};
    
    for (final error in errorLogs) {
      final errorType = error['type'] ?? 'Unknown';
      final errorMessage = error['message'] ?? '';
      
      errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
      errorDetails[errorType] = [...(errorDetails[errorType] ?? []), errorMessage];
    }
    
    return {
      'totalErrors': errorLogs.length,
      'errorCounts': errorCounts,
      'errorDetails': errorDetails,
      'mostCommonError': errorCounts.isNotEmpty 
          ? errorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : null,
    };
  }
  
  /// 分析过滤情况
  static Map<String, dynamic> _analyzeFilters(List<Map<String, dynamic>> filterLogs) {
    int totalFiltered = 0;
    final filterBreakdown = <String, int>{};
    
    for (final filter in filterLogs) {
      final filterType = filter['type'] ?? 'Unknown';
      final count = filter['count'] ?? 0;
      
      totalFiltered += count;
      filterBreakdown[filterType] = (filterBreakdown[filterType] ?? 0) + count;
    }
    
    return {
      'totalFiltered': totalFiltered,
      'filterBreakdown': filterBreakdown,
      'filterTypes': filterBreakdown.keys.toList(),
    };
  }
  
  /// 生成建议
  static List<String> _generateRecommendations(
    Map<String, dynamic> errorAnalysis,
    Map<String, dynamic> filterAnalysis,
  ) {
    final recommendations = <String>[];
    
    // 基于错误分析的建议
    final errorCounts = errorAnalysis['errorCounts'] as Map<String, int>;
    
    if (errorCounts['InvalidReceiverId.Malformed'] != null) {
      recommendations.add('检查收件人列表ID的有效性，确保列表存在且未被删除');
      recommendations.add('在保存收件人详情前验证收件人列表状态');
    }
    
    if (errorCounts['InvalidReceiverDetailMax.Malformed'] != null) {
      recommendations.add('减少单次请求的收件人数量，建议不超过200个');
      recommendations.add('实现动态批次大小调整机制');
    }
    
    if (errorCounts['Throttling'] != null || errorCounts['RequestLimitExceeded'] != null) {
      recommendations.add('增加请求间隔时间，避免触发API限流');
      recommendations.add('实现指数退避重试机制');
    }
    
    // 基于过滤分析的建议
    final filterBreakdown = filterAnalysis['filterBreakdown'] as Map<String, int>;
    
    if (filterBreakdown['invalid'] != null && filterBreakdown['invalid']! > 0) {
      recommendations.add('检查邮箱格式验证逻辑，确保有效邮箱不被误过滤');
    }
    
    if (filterBreakdown['duplicate'] != null && filterBreakdown['duplicate']! > 0) {
      recommendations.add('优化去重逻辑，确保相同邮箱只保留一个');
    }
    
    if (filterBreakdown['custom'] != null && filterBreakdown['custom']! > 0) {
      recommendations.add('检查自定义过滤规则，确保必要的邮箱不被误过滤');
    }
    
    return recommendations;
  }
  
  /// 生成详细报告
  static String generateReport(Map<String, dynamic> analysis) {
    final summary = analysis['summary'] as Map<String, dynamic>;
    final errorAnalysis = analysis['errorAnalysis'] as Map<String, dynamic>;
    final filterAnalysis = analysis['filterAnalysis'] as Map<String, dynamic>;
    final recommendations = analysis['recommendations'] as List<String>;
    
    final report = StringBuffer();
    
    // 摘要
    report.writeln('📊 数据丢失分析报告');
    report.writeln('=' * 50);
    report.writeln('原始数据: ${summary['originalCount']} 个');
    report.writeln('最终数据: ${summary['finalCount']} 个');
    report.writeln('丢失数据: ${summary['lostCount']} 个');
    report.writeln('丢失率: ${summary['lossRate'].toStringAsFixed(2)}%');
    report.writeln('成功率: ${summary['successRate'].toStringAsFixed(2)}%');
    report.writeln();
    
    // 错误分析
    report.writeln('🚨 错误分析');
    report.writeln('-' * 30);
    final errorCounts = errorAnalysis['errorCounts'] as Map<String, int>;
    if (errorCounts.isNotEmpty) {
      errorCounts.forEach((errorType, count) {
        report.writeln('$errorType: $count 次');
      });
    } else {
      report.writeln('无错误记录');
    }
    report.writeln();
    
    // 过滤分析
    report.writeln('🔍 过滤分析');
    report.writeln('-' * 30);
    final filterBreakdown = filterAnalysis['filterBreakdown'] as Map<String, int>;
    if (filterBreakdown.isNotEmpty) {
      filterBreakdown.forEach((filterType, count) {
        report.writeln('$filterType: $count 个');
      });
    } else {
      report.writeln('无过滤记录');
    }
    report.writeln();
    
    // 建议
    report.writeln('💡 改进建议');
    report.writeln('-' * 30);
    for (int i = 0; i < recommendations.length; i++) {
      report.writeln('${i + 1}. ${recommendations[i]}');
    }
    
    return report.toString();
  }
} 