import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/models/track/track_model.dart';
import 'package:aliyun_edm_manager/models/tag/email_tag_model.dart';
import 'package:aliyun_edm_manager/models/sender/sender_address_model.dart';

/// 跟踪数据状态管理Provider
class TrackProvider extends ChangeNotifier {
  final AliyunServiceManager _serviceManager;
  
  // 数据状态
  List<TrackRecord> _trackList = [];
  List<EmailTagModel> _emailTags = [];
  List<SenderAddressModel> _senderAddresses = [];
  Map<String, dynamic> _statistics = {};
  
  // 加载状态
  bool _isLoading = false;
  String? _error;
  
  // 过滤参数
  String? _selectedTagName;
  String? _selectedAccountName;
  DateTime? _startTime;
  DateTime? _endTime;
  
  // 分页参数
  int _currentPage = 1;
  int _pageSize = 10;
  int _total = 0;

  TrackProvider(this._serviceManager);

  // Getters
  List<TrackRecord> get trackList => _trackList;
  List<EmailTagModel> get emailTags => _emailTags;
  List<SenderAddressModel> get senderAddresses => _senderAddresses;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedTagName => _selectedTagName;
  String? get selectedAccountName => _selectedAccountName;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get total => _total;

  /// 初始化数据
  Future<void> initialize() async {
    await Future.wait([
      loadEmailTags(),
      loadSenderAddresses(),
      loadTrackData(),
    ]);
  }

  /// 加载邮件标签
  Future<void> loadEmailTags() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final tags = await _serviceManager.emailTagService.getAllEmailTags();
      _emailTags = tags;
    } catch (e) {
      _error = '加载邮件标签失败: $e';
      print('加载邮件标签失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载发信地址
  Future<void> loadSenderAddresses() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final addresses = await _serviceManager.senderAddressService.getAllSenderAddresses();
      _senderAddresses = addresses;
    } catch (e) {
      _error = '加载发信地址失败: $e';
      print('加载发信地址失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载跟踪数据
  Future<void> loadTrackData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final startTimeStr = _startTime?.toIso8601String().split('T')[0];
      final endTimeStr = _endTime?.toIso8601String().split('T')[0];

      final response = await _serviceManager.trackService.getTrackListByMailFromAndTagName(
        startTime: startTimeStr ?? _getDefaultStartTime(),
        endTime: endTimeStr ?? _getDefaultEndTime(),
        accountName: _selectedAccountName,
        tagName: _selectedTagName,
        pageNo: _currentPage,
        pageSize: _pageSize,
      );

      _trackList = response.trackList;
      _total = response.total;

      // 加载统计信息
      await loadStatistics();
    } catch (e) {
      _error = '加载跟踪数据失败: $e';
      print('加载跟踪数据失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载统计信息
  Future<void> loadStatistics() async {
    try {
      final startTimeStr = _startTime?.toIso8601String().split('T')[0];
      final endTimeStr = _endTime?.toIso8601String().split('T')[0];

      final stats = await _serviceManager.trackService.getTrackStatistics(
        startTime: startTimeStr,
        endTime: endTimeStr,
        accountName: _selectedAccountName,
        tagName: _selectedTagName,
      );

      _statistics = stats;
    } catch (e) {
      print('加载统计信息失败: $e');
    }
  }

  /// 设置过滤参数
  void setFilters({
    String? tagName,
    String? accountName,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    _selectedTagName = tagName;
    _selectedAccountName = accountName;
    _startTime = startTime;
    _endTime = endTime;
    _currentPage = 1; // 重置页码
    notifyListeners();
  }

  /// 重置过滤参数
  void resetFilters() {
    _selectedTagName = null;
    _selectedAccountName = null;
    _startTime = null;
    _endTime = null;
    _currentPage = 1;
    notifyListeners();
  }

  /// 应用过滤
  Future<void> applyFilters() async {
    await loadTrackData();
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadTrackData();
  }

  /// 加载下一页
  Future<void> loadNextPage() async {
    if (_trackList.length < _total) {
      _currentPage++;
      await loadTrackData();
    }
  }

  /// 获取默认开始时间（30天前）
  String _getDefaultStartTime() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
  }

  /// 获取默认结束时间（今天）
  String _getDefaultEndTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 格式化时间显示（UTC+8）
  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final utc8 = dateTime.add(const Duration(hours: 8));
      return '${utc8.year}-${utc8.month.toString().padLeft(2, '0')}-${utc8.day.toString().padLeft(2, '0')} ${utc8.hour.toString().padLeft(2, '0')}:${utc8.minute.toString().padLeft(2, '0')}:${utc8.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 格式化百分比
  String formatPercentage(String value) {
    try {
      final doubleValue = double.tryParse(value) ?? 0.0;
      return '${doubleValue.toStringAsFixed(2)}%';
    } catch (e) {
      return value;
    }
  }
}