import 'package:flutter/foundation.dart';
import '../models/batch_send_task_model.dart';
import '../services/aliyun_edm_service.dart';
import 'global_config_provider.dart';

class BatchSendTaskProvider extends ChangeNotifier {
  final AliyunEdmService _edmService = AliyunEdmService();
  
  List<BatchSendTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<BatchSendTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 获取任务列表
  Future<void> fetchTasks() async {
    _setLoading(true);
    try {
      final response = await _edmService.getBatchSendTasks();
      _tasks = response;
      _error = null;
    } catch (e) {
      _error = e.toString();
      // 添加一些模拟数据用于开发测试
      _addMockData();
    } finally {
      _setLoading(false);
    }
  }

  // 添加新任务
  Future<bool> addTask(BatchSendTaskModel task) async {
    _setLoading(true);
    try {
      final success = await _edmService.createBatchSendTask(task);
      if (success) {
        _tasks.add(task);
        notifyListeners();
      }
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除任务
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    try {
      final success = await _edmService.deleteBatchSendTask(taskId);
      if (success) {
        _tasks.removeWhere((task) => task.taskId == taskId);
        notifyListeners();
      }
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新任务状态
  Future<bool> updateTaskStatus(String taskId, String status) async {
    _setLoading(true);
    try {
      final success = await _edmService.updateBatchSendTaskStatus(taskId, status);
      if (success) {
        final index = _tasks.indexWhere((task) => task.taskId == taskId);
        if (index != -1) {
          final task = _tasks[index];
          final updatedTask = task.copyWith(
            status: status,
            startedAt: status == 'running' ? DateTime.now() : task.startedAt,
            completedAt: status == 'completed' || status == 'failed' ? DateTime.now() : task.completedAt,
          );
          _tasks[index] = updatedTask;
          notifyListeners();
        }
      }
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 暂停任务
  Future<bool> pauseTask(String taskId) async {
    return await updateTaskStatus(taskId, 'paused');
  }

  // 恢复任务
  Future<bool> resumeTask(String taskId) async {
    return await updateTaskStatus(taskId, 'running');
  }

  // 停止任务
  Future<bool> stopTask(String taskId) async {
    return await updateTaskStatus(taskId, 'stopped');
  }

  // 获取任务统计信息
  Map<String, int> getTaskStatistics() {
    final stats = {
      'total': _tasks.length,
      'pending': 0,
      'running': 0,
      'completed': 0,
      'failed': 0,
      'paused': 0,
    };

    for (final task in _tasks) {
      stats[task.status] = (stats[task.status] ?? 0) + 1;
    }

    return stats;
  }

  // 根据状态过滤任务
  List<BatchSendTaskModel> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // 搜索任务
  List<BatchSendTaskModel> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    
    return _tasks.where((task) {
      return task.taskName.toLowerCase().contains(query.toLowerCase()) ||
             task.templateName.toLowerCase().contains(query.toLowerCase()) ||
             task.senderName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 设置全局配置Provider
  void setGlobalConfigProvider(GlobalConfigProvider provider) {
    _edmService.setGlobalConfigProvider(provider);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 添加模拟数据用于开发测试
  void _addMockData() {
    _tasks = [
      BatchSendTaskModel(
        taskId: 'task-001',
        taskName: '欢迎邮件批量发送',
        templateId: 'template-001',
        templateName: '欢迎邮件模板',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver-001',
            receiverName: '新用户列表',
            intervalMinutes: 5,
            emailCount: 100,
          ),
          ReceiverListConfig(
            receiverId: 'receiver-002',
            receiverName: 'VIP用户列表',
            intervalMinutes: 10,
            emailCount: 50,
          ),
        ],
        senderAddress: 'sender@example.com',
        senderName: '系统通知',
        tag: 'welcome',
        enableTracking: true,
        status: 'running',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        totalEmails: 150,
        sentEmails: 75,
        failedEmails: 2,
      ),
      BatchSendTaskModel(
        taskId: 'task-002',
        taskName: '密码重置邮件',
        templateId: 'template-002',
        templateName: '密码重置模板',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver-003',
            receiverName: '密码重置用户',
            intervalMinutes: 3,
            emailCount: 30,
          ),
        ],
        senderAddress: 'noreply@example.com',
        senderName: '安全中心',
        tag: 'security',
        enableTracking: false,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        startedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(hours: 23)),
        totalEmails: 30,
        sentEmails: 30,
        failedEmails: 0,
      ),
      BatchSendTaskModel(
        taskId: 'task-003',
        taskName: '订单确认邮件',
        templateId: 'template-003',
        templateName: '订单确认模板',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver-004',
            receiverName: '新订单用户',
            intervalMinutes: 2,
            emailCount: 200,
          ),
        ],
        senderAddress: 'orders@example.com',
        senderName: '订单系统',
        tag: 'order',
        enableTracking: true,
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        totalEmails: 200,
        sentEmails: 0,
        failedEmails: 0,
      ),
    ];
  }
} 