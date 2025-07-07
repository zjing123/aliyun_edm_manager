import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/task/scheduled_email_task_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    return _instance ??= DatabaseService._internal();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 在桌面平台上初始化 SQLite FFI
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'edm_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 创建定时发送邮件表
    await db.execute('''
      CREATE TABLE scheduled_email_tasks (
        task_id TEXT PRIMARY KEY,
        task_name TEXT NOT NULL,
        template_id TEXT NOT NULL,
        template_name TEXT NOT NULL,
        receiver_lists TEXT NOT NULL,
        sender_address TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_type TEXT NOT NULL,
        tag TEXT,
        enable_tracking INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        scheduled_start_time TEXT,
        send_interval_minutes INTEGER,
        total_emails INTEGER NOT NULL DEFAULT 0,
        sent_emails INTEGER NOT NULL DEFAULT 0,
        failed_emails INTEGER NOT NULL DEFAULT 0,
        error_message TEXT
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('CREATE INDEX idx_task_status ON scheduled_email_tasks(status)');
    await db.execute('CREATE INDEX idx_scheduled_time ON scheduled_email_tasks(scheduled_start_time)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑，暂时为空
    // 将来如果需要修改表结构，可以在这里添加升级逻辑
  }

  // 插入新任务
  Future<int> insertTask(ScheduledEmailTaskModel task) async {
    final db = await database;
    final taskMap = _taskToMap(task);
    return await db.insert('scheduled_email_tasks', taskMap);
  }

  // 更新任务
  Future<int> updateTask(ScheduledEmailTaskModel task) async {
    final db = await database;
    final taskMap = _taskToMap(task);
    return await db.update(
      'scheduled_email_tasks',
      taskMap,
      where: 'task_id = ?',
      whereArgs: [task.taskId],
    );
  }

  // 删除任务
  Future<int> deleteTask(String taskId) async {
    final db = await database;
    return await db.delete(
      'scheduled_email_tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  // 根据ID获取任务
  Future<ScheduledEmailTaskModel?> getTask(String taskId) async {
    final db = await database;
    final results = await db.query(
      'scheduled_email_tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );

    if (results.isNotEmpty) {
      return _mapToTask(results.first);
    }
    return null;
  }

  // 获取所有任务
  Future<List<ScheduledEmailTaskModel>> getAllTasks() async {
    final db = await database;
    final results = await db.query('scheduled_email_tasks', orderBy: 'created_at DESC');
    return results.map((map) => _mapToTask(map)).toList();
  }

  // 根据状态获取任务
  Future<List<ScheduledEmailTaskModel>> getTasksByStatus(String status) async {
    final db = await database;
    final results = await db.query(
      'scheduled_email_tasks',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => _mapToTask(map)).toList();
  }

  // 获取待执行的定时任务
  Future<List<ScheduledEmailTaskModel>> getPendingScheduledTasks() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final results = await db.query(
      'scheduled_email_tasks',
      where: 'status = ? AND scheduled_start_time IS NOT NULL AND scheduled_start_time <= ?',
      whereArgs: ['pending', now],
      orderBy: 'scheduled_start_time ASC',
    );
    return results.map((map) => _mapToTask(map)).toList();
  }

  // 搜索任务
  Future<List<ScheduledEmailTaskModel>> searchTasks(String query) async {
    final db = await database;
    final results = await db.query(
      'scheduled_email_tasks',
      where: 'task_name LIKE ? OR template_name LIKE ? OR sender_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => _mapToTask(map)).toList();
  }

  // 获取任务统计信息
  Future<Map<String, int>> getTaskStatistics() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM scheduled_email_tasks 
      GROUP BY status
    ''');

    final stats = {
      'total': 0,
      'pending': 0,
      'processing': 0,
      'completed': 0,
      'failed': 0,
      'paused': 0,
    };

    for (final row in results) {
      final status = row['status'] as String;
      final count = row['count'] as int;
      stats[status] = count;
      stats['total'] = (stats['total'] ?? 0) + count;
    }

    return stats;
  }

  // 清理已完成的旧任务（保留最近30天的）
  Future<int> cleanupOldTasks() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    
    return await db.delete(
      'scheduled_email_tasks',
      where: 'status IN (?, ?) AND completed_at < ?',
      whereArgs: ['completed', 'failed', thirtyDaysAgo],
    );
  }

  // 将ScheduledEmailTaskModel转换为Map
  Map<String, dynamic> _taskToMap(ScheduledEmailTaskModel task) {
    return {
      'task_id': task.taskId,
      'task_name': task.taskName,
      'template_id': task.templateId,
      'template_name': task.templateName,
      'receiver_lists': jsonEncode(task.receiverLists.map((e) => e.toMap()).toList()),
      'sender_address': task.senderAddress,
      'sender_name': task.senderName,
      'sender_type': task.senderType,
      'tag': task.tag,
      'enable_tracking': task.enableTracking ? 1 : 0,
      'status': task.status,
      'created_at': task.createdAt.toIso8601String(),
      'started_at': task.startedAt?.toIso8601String(),
      'completed_at': task.completedAt?.toIso8601String(),
      'scheduled_start_time': task.scheduledStartTime?.toIso8601String(),
      'send_interval_minutes': task.sendIntervalMinutes,
      'total_emails': task.totalEmails,
      'sent_emails': task.sentEmails,
      'failed_emails': task.failedEmails,
      'error_message': task.errorMessage,
    };
  }

  // 将Map转换为ScheduledEmailTaskModel
  ScheduledEmailTaskModel _mapToTask(Map<String, dynamic> map) {
    final receiverListsJson = map['receiver_lists'] as String;
    final receiverListsData = jsonDecode(receiverListsJson) as List<dynamic>;
    final receiverLists = receiverListsData
        .map((e) => ReceiverListConfig.fromMap(e as Map<String, dynamic>))
        .toList();

    return ScheduledEmailTaskModel(
      taskId: map['task_id'] as String,
      taskName: map['task_name'] as String,
      templateId: map['template_id'] as String,
      templateName: map['template_name'] as String,
      receiverLists: receiverLists,
      senderAddress: map['sender_address'] as String,
      senderName: map['sender_name'] as String,
      senderType: map['sender_type'] as String,
      tag: map['tag'] as String?,
      enableTracking: (map['enable_tracking'] as int) == 1,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      scheduledStartTime: map['scheduled_start_time'] != null ? DateTime.parse(map['scheduled_start_time'] as String) : null,
      sendIntervalMinutes: map['send_interval_minutes'] as int?,
      totalEmails: map['total_emails'] as int,
      sentEmails: map['sent_emails'] as int,
      failedEmails: map['failed_emails'] as int,
      errorMessage: map['error_message'] as String?,
    );
  }

  // 关闭数据库连接
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
} 