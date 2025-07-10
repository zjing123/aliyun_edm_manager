import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/services/aliyun/sender_statistics/sender_statistics_service.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_statistics_model.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_detail_model.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/models/tag/email_tag_model.dart';
import 'package:aliyun_edm_manager/models/sender/sender_address_model.dart';
import 'package:aliyun_edm_manager/services/aliyun/email_tag/email_tag_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/sender_address/sender_address_service.dart';

class SenderStatisticsProvider extends ChangeNotifier {
  final SenderStatisticsService _service;
  final GlobalConfigProvider _globalConfigProvider;
  final EmailTagService _tagService;
  final SenderAddressService _addressService;

  SendingStatisticsModel? _statistics;
  List<SendingDetailModel> _details = [];
  List<SendingStatisticsModel> _trend = [];
  List<EmailTagModel> _tags = [];
  List<SenderAddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  // 过滤参数
  String? _selectedTagName;
  String? _selectedAccountName;
  DateTime? _startTime;
  DateTime? _endTime;

  SenderStatisticsProvider(this._globalConfigProvider)
      : _service = SenderStatisticsService(),
        _tagService = EmailTagService(),
        _addressService = SenderAddressService() {
    _service.setGlobalConfigProvider(_globalConfigProvider);
    _tagService.setGlobalConfigProvider(_globalConfigProvider);
    _addressService.setGlobalConfigProvider(_globalConfigProvider);
  }

  // Getters
  SendingStatisticsModel? get statistics => _statistics;
  List<SendingDetailModel> get details => _details;
  List<SendingStatisticsModel> get trend => _trend;
  List<EmailTagModel> get tags => _tags;
  List<SenderAddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 过滤参数getters
  String? get selectedTagName => _selectedTagName;
  String? get selectedAccountName => _selectedAccountName;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;

  /// 设置过滤参数
  void setFilterParams({
    String? tagName,
    String? accountName,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    _selectedTagName = tagName;
    _selectedAccountName = accountName;
    _startTime = startTime;
    _endTime = endTime;
    notifyListeners();
  }

  /// 重置过滤参数
  void resetFilterParams() {
    _selectedTagName = null;
    _selectedAccountName = null;
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }

  /// 加载邮件标签列表
  Future<void> loadTags() async {
    if (!_tagService.isConfigured()) {
      _error = '阿里云配置未完成，请先配置AccessKey';
      notifyListeners();
      return;
    }

    try {
      final response = await _tagService.queryTagByParam(
        pageNo: 1,
        pageSize: 10, // 获取足够多的标签
      );
      _tags = response.tags;
      _error = null;
    } catch (e) {
      _error = '加载邮件标签失败: $e';
    } finally {
      notifyListeners();
    }
  }

  /// 加载发信地址列表
  Future<void> loadAddresses() async {
    if (!_addressService.isConfigured()) {
      _error = '阿里云配置未完成，请先配置AccessKey';
      notifyListeners();
      return;
    }

    try {
      final response = await _addressService.queryMailAddressByParam(
        pageNo: 1,
        pageSize: 10, // 获取足够多的地址
      );
      _addresses = response.addresses;
      _error = null;
    } catch (e) {
      _error = '加载发信地址失败: $e';
    } finally {
      notifyListeners();
    }
  }

  /// 应用过滤条件并重新加载数据
  Future<void> applyFilters() async {
    if (_startTime == null || _endTime == null) {
      _error = '请选择起始时间和结束时间';
      notifyListeners();
      return;
    }

    await loadStatistics(
      accountName: _selectedAccountName,
      startTime: _startTime!,
      endTime: _endTime!,
      tagName: _selectedTagName,
    );
  }

  /// 加载发送统计数据
  Future<void> loadStatistics({
    String? accountName,
    required DateTime startTime,
    required DateTime endTime,
    String? tagName,
    String? dedicatedIpPoolId,
    String? dedicatedIp,
    String? esp,
  }) async {
    if (!_service.isConfigured()) {
      _error = '阿里云配置未完成，请先配置AccessKey';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _statistics = await _service.getSendingStatistics(
        accountName: accountName,
        startTime: startTime,
        endTime: endTime,
        tagName: tagName,
        dedicatedIpPoolId: dedicatedIpPoolId,
        dedicatedIp: dedicatedIp,
        esp: esp,
      );
      _error = null;
    } catch (e) {
      _error = '加载统计数据失败: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 加载发送详情列表
  Future<void> loadDetails({
    String? recipient,
    SendingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!_service.isConfigured()) {
      _error = '阿里云配置未完成，请先配置AccessKey';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _details = await _service.getSendingDetails(
        recipient: recipient,
        status: status,
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      );
      _error = null;
    } catch (e) {
      _error = '加载详情数据失败: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 加载发送趋势数据
  Future<void> loadTrend({
    required int days,
    String? accountName,
    String? tagName,
  }) async {
    if (!_service.isConfigured()) {
      _error = '阿里云配置未完成，请先配置AccessKey';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _trend = await _service.getSendingTrend(
        days: days,
        accountName: accountName,
        tagName: tagName,
      );
      _error = null;
    } catch (e) {
      _error = '加载趋势数据失败: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新所有数据
  Future<void> refresh() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    await Future.wait([
      loadStatistics(
        startTime: sevenDaysAgo,
        endTime: now,
      ),
      loadDetails(),
      loadTrend(days: 7),
    ]);
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 获取汇总统计信息
  Map<String, dynamic> getSummaryStatistics() {
    if (_statistics == null || _statistics!.records.isEmpty) {
      return {
        'totalSent': 0,
        'successSent': 0,
        'failedSent': 0,
        'successRate': 0.0,
      };
    }

    int totalSent = 0;
    int successSent = 0;
    int failedSent = 0;

    for (final record in _statistics!.records) {
      totalSent += record.requestCountInt;
      successSent += record.successCountInt;
      failedSent += record.faildCountInt;
    }

    final successRate = totalSent > 0 ? (successSent / totalSent) * 100 : 0.0;

    return {
      'totalSent': totalSent,
      'successSent': successSent,
      'failedSent': failedSent,
      'successRate': successRate,
    };
  }
} 