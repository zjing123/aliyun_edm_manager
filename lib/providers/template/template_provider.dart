import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/models/template/template_request_response.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

/// 模板管理Provider
/// 提供模板的增删改查功能
class TemplateProvider extends ChangeNotifier {
  // 服务管理器
  late final AliyunServiceManager _serviceManager;
  
  // 全局配置Provider
  GlobalConfigProvider? _globalConfigProvider;
  
  // 模板列表数据
  List<TemplateModel> _templates = [];
  
  // 加载状态
  bool _isLoading = false;
  
  // 错误信息
  String? _error;
  
  // 分页信息
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 0;
  
  // 搜索参数
  String? _keyWord;
  int? _status;
  int? _fromType;
  
  // 构造函数
  TemplateProvider(AliyunServiceManager serviceManager) {
    _serviceManager = serviceManager;
  }
  
  // Getters
  List<TemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  String? get keyWord => _keyWord;
  int? get status => _status;
  int? get fromType => _fromType;
  
  // 设置全局配置Provider
  void setGlobalConfigProvider(GlobalConfigProvider provider) {
    _globalConfigProvider = provider;
    _serviceManager.initialize(provider);
  }
  
  // 设置搜索参数
  void setSearchParams({
    String? keyWord,
    int? status,
    int? fromType,
  }) {
    _keyWord = keyWord;
    _status = status;
    _fromType = fromType;
    _currentPage = 1; // 重置到第一页
  }
  
  // 加载模板列表
  Future<void> loadTemplates({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = QueryTemplateByParamRequest(
        pageNo: _currentPage,
        pageSize: _pageSize,
        keyWord: _keyWord,
        status: _status,
        fromType: _fromType,
      );
      
      final response = await _serviceManager.templateService.queryTemplateByParamWithRequest(request);
      
      setState(() {
        _templates = response.templates;
        _totalCount = response.totalCount;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
      
      print('模板列表加载成功，共${_templates.length}条记录');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('加载模板列表失败: $e');
    }
  }
  
  // 刷新模板列表
  Future<void> refresh() async {
    await loadTemplates(forceRefresh: true);
  }
  
  // 下一页
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await loadTemplates();
    }
  }
  
  // 上一页
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadTemplates();
    }
  }
  
  // 跳转到指定页
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      await loadTemplates();
    }
  }
  
  // 创建模板
  Future<bool> createTemplate({
    required int templateType,
    required String templateName,
    String? templateSubject,
    String? templateNickName,
    String? templateText,
    int? fromType,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = CreateTemplateRequest(
        templateType: templateType,
        templateName: templateName,
        templateSubject: templateSubject,
        templateNickName: templateNickName,
        templateText: templateText,
        fromType: fromType,
      );
      
      final response = await _serviceManager.templateService.createTemplate(request);
      
      print('模板创建成功，TemplateId: ${response.templateId}');
      
      // 刷新列表
      await refresh();
      
      return true;
    } catch (e) {
      print('创建模板失败: $e');
      return false;
    }
  }
  
  // 修改模板
  Future<bool> modifyTemplate({
    required int templateId,
    required String templateName,
    String? templateSubject,
    String? templateNickName,
    String? templateText,
    int? fromType,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = ModifyTemplateRequest(
        templateId: templateId,
        templateName: templateName,
        templateSubject: templateSubject,
        templateNickName: templateNickName,
        templateText: templateText,
        fromType: fromType,
      );
      
      final response = await _serviceManager.templateService.modifyTemplate(request);
      
      print('模板修改成功，RequestId: ${response.requestId}');
      
      // 刷新列表
      await refresh();
      
      return true;
    } catch (e) {
      print('修改模板失败: $e');
      return false;
    }
  }
  
  // 删除模板
  Future<bool> deleteTemplate({
    required int templateId,
    int? fromType,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = DeleteTemplateRequest(
        templateId: templateId,
        fromType: fromType,
      );
      
      final response = await _serviceManager.templateService.deleteTemplate(request);
      
      print('模板删除成功，RequestId: ${response.requestId}');
      
      // 刷新列表
      await refresh();
      
      return true;
    } catch (e) {
      print('删除模板失败: $e');
      return false;
    }
  }
  
  // 获取模板详情
  Future<DescTemplateResponse?> getTemplateDetail({
    required int templateId,
    int? fromType,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = DescTemplateRequest(
        templateId: templateId,
        fromType: fromType,
      );
      
      final response = await _serviceManager.templateService.descTemplate(request);
      
      print('获取模板详情成功，TemplateName: ${response.templateName}');
      
      return response;
    } catch (e) {
      print('获取模板详情失败: $e');
      return null;
    }
  }
  
  // 设置状态
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
  
  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 