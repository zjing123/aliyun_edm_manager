import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/services/aliyun/sender_name/sender_name_service.dart';
import 'package:aliyun_edm_manager/models/sender/sender_name_model.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';

class SenderNameProvider extends ChangeNotifier {
  final SenderNameService _senderNameService = SenderNameService();

  List<SenderNameModel> _senderNames = [];
  List<SenderNameModel> _filteredSenderNames = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;
  Set<String> _selectedIds = {};

  // 分页相关属性
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  int _pageSize = PaginationConstants.senderAddressDefaultPageSize;

  // Getters
  List<SenderNameModel> get senderNames => _senderNames;
  List<SenderNameModel> get filteredSenderNames => _filteredSenderNames;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  Set<String> get selectedIds => _selectedIds;
  bool get hasSelectedItems => _selectedIds.isNotEmpty;
  
  // 分页相关getters
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  int get pageSize => _pageSize;
  
  // 选择相关getters
  bool get hasSelection => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool get isAllSelected => _senderNames.isNotEmpty && _selectedIds.length == _senderNames.length;

  /// 加载所有发送人名称
  Future<void> loadSenderNames() async {
    _setLoading(true);
    _clearError();
    
    try {
      _senderNames = await _senderNameService.getAllSenderNames();
      _applySearchFilter();
      _updatePagination();
      notifyListeners();
    } catch (e) {
      _setError('加载发送人名称失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadSenderNames();
  }

  /// 刷新并清除缓存
  Future<void> refreshAndClearCache() async {
    _selectedIds.clear();
    await loadSenderNames();
  }

  /// 搜索发送人名称
  Future<void> searchSenderNames(String query) async {
    _searchQuery = query;
    _setLoading(true);
    _clearError();
    
    try {
      if (query.trim().isEmpty) {
        _senderNames = await _senderNameService.getAllSenderNames();
      } else {
        _senderNames = await _senderNameService.searchSenderNames(query);
      }
      _applySearchFilter();
      _updatePagination();
      notifyListeners();
    } catch (e) {
      _setError('搜索发送人名称失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建发送人名称
  Future<bool> createSenderName(String name, {int isDefault = 0}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _senderNameService.createSenderName(name, isDefault: isDefault);
      if (success) {
        await loadSenderNames();
        return true;
      }
      return false;
    } catch (e) {
      _setError('创建发送人名称失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新发送人名称
  Future<bool> updateSenderName(String id, String name, {int isDefault = 0}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _senderNameService.updateSenderName(id, name, isDefault: isDefault);
      if (success) {
        await loadSenderNames();
        return true;
      }
      return false;
    } catch (e) {
      _setError('更新发送人名称失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除发送人名称
  Future<bool> deleteSenderName(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _senderNameService.deleteSenderName(id);
      if (success) {
        await loadSenderNames();
        _removeSelectedId(id);
        return true;
      }
      return false;
    } catch (e) {
      _setError('删除发送人名称失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量删除发送人名称
  Future<bool> deleteSenderNames(List<String> ids) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _senderNameService.deleteSenderNames(ids);
      if (success) {
        await loadSenderNames();
        _clearSelectedIds();
        return true;
      }
      return false;
    } catch (e) {
      _setError('批量删除发送人名称失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除选中的发送人名称
  Future<bool> deleteSelectedSenderNames() async {
    if (_selectedIds.isEmpty) return false;
    return await deleteSenderNames(_selectedIds.toList());
  }

  /// 选择发送人名称
  void selectSenderName(String id) {
    _selectedIds.add(id);
    notifyListeners();
  }

  /// 取消选择发送人名称
  void unselectSenderName(String id) {
    _selectedIds.remove(id);
    notifyListeners();
  }

  /// 切换选择状态
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  /// 切换发送人名称选择状态
  void toggleSenderNameSelection(String id) {
    toggleSelection(id);
  }

  /// 检查发送人名称是否被选中
  bool isSenderNameSelected(String id) {
    return _selectedIds.contains(id);
  }

  /// 全选
  void selectAll() {
    _selectedIds = _filteredSenderNames.map((e) => e.id).toSet();
    notifyListeners();
  }

  /// 取消全选
  void unselectAll() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// 切换全选状态
  void toggleSelectAll() {
    if (isAllSelected) {
      unselectAll();
    } else {
      selectAll();
    }
  }

  /// 获取选中的发送人名称列表
  List<SenderNameModel> get selectedSenderNames {
    return _filteredSenderNames.where((e) => _selectedIds.contains(e.id)).toList();
  }

  /// 检查是否部分选择
  bool get isPartiallySelected {
    return _selectedIds.isNotEmpty && !isAllSelected;
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
  }

  /// 清除搜索
  void clearSearch() {
    _searchQuery = '';
    _applySearchFilter();
    notifyListeners();
  }

  // 分页相关方法
  void firstPage() {
    if (_currentPage > 1) {
      _currentPage = 1;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void lastPage() {
    if (_currentPage < _totalPages) {
      _currentPage = _totalPages;
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _applySearchFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredSenderNames = List.from(_senderNames);
    } else {
      _filteredSenderNames = _senderNames
          .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _updatePagination() {
    _totalCount = _filteredSenderNames.length;
    _totalPages = (_totalCount / _pageSize).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
  }

  void _removeSelectedId(String id) {
    _selectedIds.remove(id);
  }

  void _clearSelectedIds() {
    _selectedIds.clear();
  }

  /// 设为默认发送人名称（唯一）
  Future<bool> setDefaultSenderName(String id) async {
    _setLoading(true);
    _clearError();
    try {
      final success = await _senderNameService.setDefaultSenderName(id);
      if (success) {
        await loadSenderNames();
        return true;
      }
      return false;
    } catch (e) {
      _setError('设为默认发送人名称失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 取消默认发送人名称
  Future<bool> unsetDefaultSenderName([String? id]) async {
    _setLoading(true);
    _clearError();
    try {
      final success = await _senderNameService.unsetDefaultSenderName(id);
      if (success) {
        await loadSenderNames();
        return true;
      }
      return false;
    } catch (e) {
      _setError('取消默认发送人名称失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
} 