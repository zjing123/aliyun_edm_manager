import 'package:flutter/foundation.dart';
import '../models/scheduled_email_task_model.dart';
import '../services/aliyun_edm_service.dart';
import '../services/database_service.dart';
import 'global_config_provider.dart';
import 'receiver_list_provider.dart';
import 'dart:async';
import 'dart:math';

class ScheduledEmailTaskProvider extends ChangeNotifier {
  final AliyunEdmService _edmService = AliyunEdmService();
  final DatabaseService _databaseService = DatabaseService();
  final GlobalConfigProvider _configProvider;
  ReceiverListProvider? _receiverListProvider;
  
  List<ScheduledEmailTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  
  // 定时器管理
  final Map<String, Timer> _taskTimers = {};
  final Random _random = Random();

  ScheduledEmailTaskProvider(this._configProvider);

  List<ScheduledEmailTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 初始化方法 - 从数据库恢复任务和定时器
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    try {
      // 从数据库加载所有任务
      _tasks = await _databaseService.getAllTasks();
      
      // 恢复定时任务
      await _restoreScheduledTasks();
      
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('初始化任务失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 恢复定时任务
  Future<void> _restoreScheduledTasks() async {
    try {
      final pendingTasks = await _databaseService.getTasksByStatus('pending');
      for (final task in pendingTasks) {
        if (task.scheduledStartTime != null) {
          final now = DateTime.now();
          if (task.scheduledStartTime!.isAfter(now)) {
            // 任务尚未到达执行时间，重新设置定时器
            _scheduleTask(task);
          } else {
            // 任务已经到达执行时间，立即执行
            await _executeTask(task);
          }
        }
      }
    } catch (e) {
      debugPrint('恢复定时任务失败: $e');
    }
  }

  // 获取任务列表
  Future<void> fetchTasks() async {
    _setLoading(true);
    try {
      _tasks = await _databaseService.getAllTasks();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('获取任务列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 添加新任务
  Future<bool> addTask(ScheduledEmailTaskModel task) async {
    _setLoading(true);
    try {
      // 保存到数据库
      await _databaseService.insertTask(task);
      
      // 添加到内存列表
      _tasks.add(task);
      
      // 如果是定时任务，设置定时器
      if (task.scheduledStartTime != null) {
        _scheduleTask(task);
      }
      
      notifyListeners();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('添加任务失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除任务
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    try {
      // 从数据库删除
      await _databaseService.deleteTask(taskId);
      
      // 从内存列表删除
      _tasks.removeWhere((task) => task.taskId == taskId);
      
      // 取消定时器
      _cancelTimer(taskId);
      
      notifyListeners();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('删除任务失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新任务状态
  Future<bool> updateTaskStatus(String taskId, String status) async {
    _setLoading(true);
    try {
      final taskIndex = _tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex == -1) {
        throw Exception('未找到任务: $taskId');
      }
      
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(
        status: status,
        startedAt: status == 'processing' ? DateTime.now() : task.startedAt,
        completedAt: status == 'completed' || status == 'failed' ? DateTime.now() : task.completedAt,
      );
      
      // 更新数据库
      await _databaseService.updateTask(updatedTask);
      
      // 更新内存列表
      _tasks[taskIndex] = updatedTask;
      
      // 处理定时器
      if (status == 'paused' || status == 'stopped' || status == 'completed' || status == 'failed') {
        _cancelTimer(taskId);
      }
      
      notifyListeners();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('更新任务状态失败: $e');
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
    return await updateTaskStatus(taskId, 'processing');
  }

  // 停止任务
  Future<bool> stopTask(String taskId) async {
    return await updateTaskStatus(taskId, 'stopped');
  }

  // 获取任务统计信息
  Future<Map<String, int>> getTaskStatistics() async {
    try {
      return await _databaseService.getTaskStatistics();
    } catch (e) {
      debugPrint('获取任务统计失败: $e');
      // 返回内存中的统计信息作为后备
      final stats = {
        'total': _tasks.length,
        'pending': 0,
        'processing': 0,
        'completed': 0,
        'failed': 0,
        'paused': 0,
      };

      for (final task in _tasks) {
        stats[task.status] = (stats[task.status] ?? 0) + 1;
      }

      return stats;
    }
  }

  // 根据状态过滤任务
  Future<List<ScheduledEmailTaskModel>> getTasksByStatus(String status) async {
    try {
      return await _databaseService.getTasksByStatus(status);
    } catch (e) {
      debugPrint('根据状态获取任务失败: $e');
      return _tasks.where((task) => task.status == status).toList();
    }
  }

  // 搜索任务
  Future<List<ScheduledEmailTaskModel>> searchTasks(String query) async {
    if (query.isEmpty) return _tasks;
    
    try {
      return await _databaseService.searchTasks(query);
    } catch (e) {
      debugPrint('搜索任务失败: $e');
      return _tasks.where((task) {
        return task.taskName.toLowerCase().contains(query.toLowerCase()) ||
               task.templateName.toLowerCase().contains(query.toLowerCase()) ||
               task.senderName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  // 清理旧任务
  Future<void> cleanupOldTasks() async {
    try {
      await _databaseService.cleanupOldTasks();
      await fetchTasks(); // 重新加载任务列表
    } catch (e) {
      debugPrint('清理旧任务失败: $e');
    }
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

  // 设置收件人列表Provider
  void setReceiverListProvider(ReceiverListProvider provider) {
    _receiverListProvider = provider;
  }

  // 数据验证方法
  String? validateTaskData({
    required String taskName,
    required List<String> selectedReceiverIds,
    required String? selectedTemplateId,
    required String? selectedSenderAddress,
    required String? selectedSenderType,
    required String? selectedEmailTag,
    required bool enableScheduledSend,
    required DateTime? startSendTime,
    required String? sendIntervalText,
  }) {
    // 验证收件人列表
    if (selectedReceiverIds.isEmpty) {
      return '请至少选择一个收件人列表';
    }

    // 验证任务名称
    if (taskName.trim().isEmpty) {
      return '任务名称不能为空';
    }
    if (taskName.trim().length < 2) {
      return '任务名称至少需要2个字符';
    }
    if (taskName.trim().length > 50) {
      return '任务名称最多50个字符';
    }

    // 验证邮件模板
    if (selectedTemplateId == null || selectedTemplateId.isEmpty) {
      return '请选择邮件模板';
    }

    // 验证发信地址
    if (selectedSenderAddress == null || selectedSenderAddress.isEmpty) {
      return '请选择发信地址';
    }

    // 验证发信地址类型
    if (selectedSenderType == null || selectedSenderType.isEmpty) {
      return '请选择发信地址类型';
    }

    // 验证邮件标签
    if (selectedEmailTag == null || selectedEmailTag.isEmpty) {
      return '请选择邮件标签';
    }

    // 验证定时发送
    if (enableScheduledSend) {
      if (startSendTime == null) {
        return '请选择定时发送时间';
      }
      if (startSendTime.isBefore(DateTime.now())) {
        return '定时发送时间不能小于当前时间';
      }
    }

    // 验证发送间隔
    if (sendIntervalText != null && sendIntervalText.isNotEmpty) {
      final interval = int.tryParse(sendIntervalText);
      if (interval == null || interval < 0 || interval > 10000) {
        return '发送间隔必须是0-10000之间的整数';
      }
    }

    return null;
  }

  // 创建定时发送邮件
  Future<bool> createScheduledEmailTask({
    required String taskName,
    required List<String> selectedReceiverIds,
    required String templateId,
    required String templateName,
    required String senderAddress,
    required String senderName,
    required String senderType,
    required String emailTag,
    required bool enableTracking,
    required bool enableScheduledSend,
    required DateTime? startSendTime,
    required int? sendInterval,
  }) async {
    try {
      // 验证数据
      final validationError = validateTaskData(
        taskName: taskName,
        selectedReceiverIds: selectedReceiverIds,
        selectedTemplateId: templateId,
        selectedSenderAddress: senderAddress,
        selectedSenderType: senderType,
        selectedEmailTag: emailTag,
        enableScheduledSend: enableScheduledSend,
        startSendTime: startSendTime,
        sendIntervalText: sendInterval?.toString(),
      );

      if (validationError != null) {
        _error = validationError;
        notifyListeners();
        return false;
      }

      // 获取收件人列表信息
      final receiverLists = <ReceiverListConfig>[];
      for (final id in selectedReceiverIds) {
        if (_receiverListProvider != null) {
          final receiverList = _receiverListProvider!.findReceiverById(id);
          if (receiverList != null) {
            receiverLists.add(ReceiverListConfig(
              receiverId: receiverList.receiverId,
              receiverName: receiverList.receiversName,
              intervalMinutes: 0,
              emailCount: receiverList.count,
              listId: receiverList.receiverId,
              listName: receiverList.receiversName,
              receiverCount: receiverList.count,
            ));
          }
        } else {
          // 如果ReceiverListProvider不可用，使用简单的映射
          receiverLists.add(ReceiverListConfig(
            receiverId: id,
            receiverName: '收件人列表_$id',
            intervalMinutes: 0,
            emailCount: 0,
            listId: id,
            listName: '收件人列表_$id',
            receiverCount: 100, // 默认值
          ));
        }
      }

      if (receiverLists.isEmpty) {
        _error = '未找到有效的收件人列表';
        notifyListeners();
        return false;
      }

      // 创建任务
      if (receiverLists.length == 1) {
        // 单个收件人列表
        final task = ScheduledEmailTaskModel(
          taskId: _generateTaskId(),
          taskName: taskName,
          templateId: templateId,
          templateName: templateName,
          receiverLists: receiverLists,
          senderAddress: senderAddress,
          senderName: senderName,
          senderType: senderType,
          tag: emailTag,
          enableTracking: enableTracking,
          status: 'pending',
          createdAt: DateTime.now(),
          scheduledStartTime: enableScheduledSend ? startSendTime : null,
          sendIntervalMinutes: sendInterval,
          totalEmails: receiverLists.first.receiverCount ?? 0,
        );

        return await addTask(task);
      } else {
        // 多个收件人列表
        bool allSuccess = true;
        DateTime? currentStartTime = enableScheduledSend ? startSendTime : null;
        
        for (int i = 0; i < receiverLists.length; i++) {
          final receiverList = receiverLists[i];
          final task = ScheduledEmailTaskModel(
            taskId: _generateTaskId(),
            taskName: '${taskName}_${i + 1}',
            templateId: templateId,
            templateName: templateName,
            receiverLists: [receiverList],
            senderAddress: senderAddress,
            senderName: senderName,
            senderType: senderType,
            tag: emailTag,
            enableTracking: enableTracking,
            status: 'pending',
            createdAt: DateTime.now(),
            scheduledStartTime: currentStartTime,
            sendIntervalMinutes: sendInterval,
            totalEmails: receiverList.receiverCount ?? 0,
          );

          final success = await addTask(task);
          if (!success) {
            allSuccess = false;
          }

          // 为下一个任务增加间隔时间
          if (sendInterval != null && sendInterval > 0 && currentStartTime != null) {
            currentStartTime = currentStartTime.add(Duration(minutes: sendInterval));
          }
        }

        return allSuccess;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 更新定时发送邮件
  Future<bool> updateScheduledEmailTask({
    required String taskId,
    required String taskName,
    required List<String> selectedReceiverIds,
    required String templateId,
    required String templateName,
    required String senderAddress,
    required String senderName,
    required String senderType,
    required String emailTag,
    required bool enableTracking,
    required bool enableScheduledSend,
    required DateTime? startSendTime,
    required int? sendInterval,
  }) async {
    try {
      // 验证数据
      final validationError = validateTaskData(
        taskName: taskName,
        selectedReceiverIds: selectedReceiverIds,
        selectedTemplateId: templateId,
        selectedSenderAddress: senderAddress,
        selectedSenderType: senderType,
        selectedEmailTag: emailTag,
        enableScheduledSend: enableScheduledSend,
        startSendTime: startSendTime,
        sendIntervalText: sendInterval?.toString(),
      );

      if (validationError != null) {
        _error = validationError;
        notifyListeners();
        return false;
      }

      // 查找要更新的任务
      final taskIndex = _tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex == -1) {
        _error = '未找到要更新的任务';
        notifyListeners();
        return false;
      }

      final existingTask = _tasks[taskIndex];

      // 获取收件人列表信息
      final receiverLists = <ReceiverListConfig>[];
      for (final id in selectedReceiverIds) {
        if (_receiverListProvider != null) {
          final receiverList = _receiverListProvider!.findReceiverById(id);
          if (receiverList != null) {
            receiverLists.add(ReceiverListConfig(
              receiverId: receiverList.receiverId,
              receiverName: receiverList.receiversName,
              intervalMinutes: 0,
              emailCount: receiverList.count,
              listId: receiverList.receiverId,
              listName: receiverList.receiversName,
              receiverCount: receiverList.count,
            ));
          }
        } else {
          // 如果ReceiverListProvider不可用，使用简单的映射
          receiverLists.add(ReceiverListConfig(
            receiverId: id,
            receiverName: '收件人列表_$id',
            intervalMinutes: 0,
            emailCount: 0,
            listId: id,
            listName: '收件人列表_$id',
            receiverCount: 100, // 默认值
          ));
        }
      }

      if (receiverLists.isEmpty) {
        _error = '未找到有效的收件人列表';
        notifyListeners();
        return false;
      }

      // 创建更新后的任务
      final updatedTask = existingTask.copyWith(
        taskName: taskName,
        templateId: templateId,
        templateName: templateName,
        receiverLists: receiverLists,
        senderAddress: senderAddress,
        senderName: senderName,
        senderType: senderType,
        tag: emailTag,
        enableTracking: enableTracking,
        scheduledStartTime: enableScheduledSend ? startSendTime : null,
        sendIntervalMinutes: sendInterval,
        totalEmails: receiverLists.fold<int>(0, (sum, list) => sum + (list.receiverCount ?? 0)),
      );

      // 更新数据库
      await _databaseService.updateTask(updatedTask);
      
      // 更新内存中的任务列表
      _tasks[taskIndex] = updatedTask;
      
      // 清除错误并通知监听器
      _error = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 定时任务相关方法
  void _scheduleTask(ScheduledEmailTaskModel task) {
    if (task.scheduledStartTime == null) return;

    final now = DateTime.now();
    final delay = task.scheduledStartTime!.difference(now);
    
    if (delay.inMilliseconds <= 0) {
      // 立即执行
      _executeTask(task);
    } else {
      // 设置定时器
      _taskTimers[task.taskId] = Timer(delay, () {
        _executeTask(task);
      });
    }
  }

  Future<void> _executeTask(ScheduledEmailTaskModel task) async {
    try {
      // 检查任务状态
      if (task.status != 'pending') return;

      // 更新任务状态为执行中
      await updateTaskStatus(task.taskId, 'processing');

      // 模拟发送邮件
      debugPrint('开始执行任务: ${task.taskName}');
      debugPrint('模板ID: ${task.templateId}');
      debugPrint('发信地址: ${task.senderAddress}');
      debugPrint('收件人列表: ${task.receiverLists.map((e) => e.listName ?? e.receiverName).join(', ')}');
      debugPrint('总邮件数: ${task.totalEmails}');

      // 模拟发送过程
      await Future.delayed(const Duration(seconds: 2));

      // 更新任务状态为完成
      await updateTaskStatus(task.taskId, 'completed');
      
      debugPrint('任务执行完成: ${task.taskName}');
    } catch (e) {
      debugPrint('任务执行失败: ${task.taskName}, 错误: $e');
      
      // 更新任务状态为失败
      final taskIndex = _tasks.indexWhere((t) => t.taskId == task.taskId);
      if (taskIndex != -1) {
        final updatedTask = _tasks[taskIndex].copyWith(
          status: 'failed',
          errorMessage: e.toString(),
        );
        await _databaseService.updateTask(updatedTask);
        _tasks[taskIndex] = updatedTask;
        notifyListeners();
      }
    }
  }

  void _cancelTimer(String taskId) {
    final timer = _taskTimers.remove(taskId);
    timer?.cancel();
  }

  String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    // 取消所有定时器
    for (final timer in _taskTimers.values) {
      timer.cancel();
    }
    _taskTimers.clear();
    
    // 关闭数据库连接
    _databaseService.close();
    
    super.dispose();
  }
}