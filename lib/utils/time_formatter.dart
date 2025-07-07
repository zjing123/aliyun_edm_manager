import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// 统一的时间格式化工具类
/// 支持时区转换和多种格式化选项
class TimeFormatter {
  static bool _initialized = false;

  /// 初始化时区数据（只需调用一次）
  static void initialize() {
    if (!_initialized) {
      tzdata.initializeTimeZones();
      _initialized = true;
    }
  }

  /// 默认时区
  static const String defaultTimeZone = 'Asia/Shanghai';

  /// 格式化时间字符串为本地时间
  /// 
  /// [timeString] - 时间字符串（ISO 8601格式）
  /// [timeZone] - 目标时区，默认为中国时区
  /// [format] - 输出格式，默认为 'yyyy-MM-dd HH:mm:ss'
  /// 
  /// 返回格式化后的时间字符串，如果解析失败则返回原字符串
  static String formatTime({
    required String timeString,
    String timeZone = defaultTimeZone,
    String format = 'yyyy-MM-dd HH:mm:ss',
  }) {
    if (timeString.isEmpty) return '';
    
    try {
      initialize();
      
      // 解析UTC时间
      DateTime utcTime = DateTime.parse(timeString).toUtc();
      
      // 获取目标时区
      final location = tz.getLocation(timeZone);
      final localTime = tz.TZDateTime.from(utcTime, location);
      
      // 格式化
      return DateFormat(format).format(localTime);
    } catch (e) {
      // 如果解析失败，尝试直接格式化原字符串
      try {
        DateTime dateTime = DateTime.parse(timeString);
        return DateFormat(format).format(dateTime);
      } catch (e) {
        return timeString;
      }
    }
  }

  /// 格式化时间为日期格式 (yyyy-MM-dd)
  static String formatDate({
    required String timeString,
    String timeZone = defaultTimeZone,
  }) {
    return formatTime(
      timeString: timeString,
      timeZone: timeZone,
      format: 'yyyy-MM-dd',
    );
  }

  /// 格式化时间为时间格式 (HH:mm:ss)
  static String formatTimeOnly({
    required String timeString,
    String timeZone = defaultTimeZone,
  }) {
    return formatTime(
      timeString: timeString,
      timeZone: timeZone,
      format: 'HH:mm:ss',
    );
  }

  /// 格式化时间为详细格式 (yyyy-MM-dd HH:mm:ss)
  static String formatDateTime({
    required String timeString,
    String timeZone = defaultTimeZone,
  }) {
    return formatTime(
      timeString: timeString,
      timeZone: timeZone,
      format: 'yyyy-MM-dd HH:mm:ss',
    );
  }

  /// 格式化时间为相对时间（如：刚刚、5分钟前、1小时前等）
  static String formatRelativeTime({
    required String timeString,
    String timeZone = defaultTimeZone,
  }) {
    if (timeString.isEmpty) return '';
    
    try {
      initialize();
      
      // 解析UTC时间
      DateTime utcTime = DateTime.parse(timeString).toUtc();
      
      // 获取目标时区
      final location = tz.getLocation(timeZone);
      final localTime = tz.TZDateTime.from(utcTime, location);
      final now = tz.TZDateTime.now(location);
      
      final difference = now.difference(localTime);
      
      if (difference.inSeconds < 60) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}天前';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).round();
        return '${months}个月前';
      } else {
        final years = (difference.inDays / 365).round();
        return '${years}年前';
      }
    } catch (e) {
      return timeString;
    }
  }

  /// 获取当前时区的当前时间
  static DateTime getCurrentTime({String timeZone = defaultTimeZone}) {
    initialize();
    final location = tz.getLocation(timeZone);
    return tz.TZDateTime.now(location);
  }

  /// 将本地时间转换为UTC时间字符串
  static String localToUtc({
    required DateTime localTime,
    String timeZone = defaultTimeZone,
  }) {
    initialize();
    final location = tz.getLocation(timeZone);
    final tzLocalTime = tz.TZDateTime.from(localTime, location);
    return tzLocalTime.toUtc().toIso8601String();
  }

  /// 检查时间字符串是否有效
  static bool isValidTimeString(String timeString) {
    if (timeString.isEmpty) return false;
    try {
      DateTime.parse(timeString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取时区列表
  static List<String> getAvailableTimeZones() {
    initialize();
    return tz.timeZoneDatabase.locations.keys.toList();
  }

  /// 检查时区是否有效
  static bool isValidTimeZone(String timeZone) {
    initialize();
    return tz.timeZoneDatabase.locations.containsKey(timeZone);
  }
} 