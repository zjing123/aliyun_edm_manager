import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:aliyun_edm_manager/models/task/scheduled_email_task_model.dart';
import 'package:aliyun_edm_manager/models/sender/sender_name_model.dart';

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
      version: 7,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 创建定时发送邮件表（更新后的结构）
    await db.execute('''
      CREATE TABLE scheduled_email_tasks (
        task_id TEXT PRIMARY KEY,                    -- 任务id
        task_name TEXT NOT NULL,                     -- 任务名称
        template_id TEXT NOT NULL,                   -- 模板id
        template_name TEXT NOT NULL,                 -- 模板名称
        status TEXT NOT NULL DEFAULT 'pending',      -- 任务状态
        created_at TEXT NOT NULL,                    -- 创建时间
        started_at TEXT,                             -- 任务开始时间
        completed_at TEXT,                           -- 任务完成时间
        send_interval_minutes INTEGER,               -- 任务间隔分钟数
        error_message TEXT,                          -- 错误信息
        receivers_id TEXT NOT NULL,                  -- 收件人列表id
        receivers_name TEXT NOT NULL,                -- 收件人列表名称
        mail_address_id TEXT NOT NULL,               -- 发信地址 ID
        mail_address TEXT NOT NULL,                  -- 发信地址
        mail_address_type TEXT NOT NULL,             -- 发信地址类型
        email_tag_id TEXT NOT NULL,                  -- 邮件标签id
        email_tag_name TEXT NOT NULL,                -- 邮件标签名称
        click_track INTEGER NOT NULL DEFAULT 0,      -- 是否启用跟踪
        scheduled_time TEXT                          -- 任务执行时间
      )
    ''');

    // 创建发送人名称表
    await db.execute('''
      CREATE TABLE sender_names (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('CREATE INDEX idx_task_status ON scheduled_email_tasks(status)');
    await db.execute('CREATE INDEX idx_task_receivers_id ON scheduled_email_tasks(receivers_id)');
    await db.execute('CREATE INDEX idx_task_template_id ON scheduled_email_tasks(template_id)');
    await db.execute('CREATE INDEX idx_task_mail_address_id ON scheduled_email_tasks(mail_address_id)');
    await db.execute('CREATE INDEX idx_task_email_tag_id ON scheduled_email_tasks(email_tag_id)');
    await db.execute('CREATE INDEX idx_sender_name ON sender_names(name)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
    if (oldVersion < 2) {
      // 从版本1升级到版本2：添加sender_names表
      try {
        // 检查sender_names表是否已存在
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sender_names'"
        );
        
        if (result.isEmpty) {
          // 创建发送人名称表
          await db.execute('''
            CREATE TABLE sender_names (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_default INTEGER NOT NULL DEFAULT 0
            )
          ''');
          
          // 创建索引
          await db.execute('CREATE INDEX idx_sender_name ON sender_names(name)');
          
          print('数据库升级：已创建 sender_names 表');
        }
      } catch (e) {
        print('数据库升级错误：$e');
      }
    }

    if (oldVersion < 3) {
      // v3: sender_names表添加is_default字段
      try {
        final columns = await db.rawQuery("PRAGMA table_info(sender_names)");
        final hasIsDefault = columns.any((col) => col['name'] == 'is_default');
        if (!hasIsDefault) {
          await db.execute('ALTER TABLE sender_names ADD COLUMN is_default INTEGER NOT NULL DEFAULT 0');
          print('数据库升级：sender_names表已添加 is_default 字段');
        }
      } catch (e) {
        print('数据库升级错误（is_default）：$e');
      }
    }

    if (oldVersion < 4) {
      // v4: 跳过创建scheduled_email_task_details表，因为v5会合并字段
      print('数据库升级：跳过v4的scheduled_email_task_details表创建，将在v5中合并字段');
    }

    if (oldVersion < 5) {
      // v5: 将scheduled_email_task_details表的字段合并到scheduled_email_tasks表中
      try {
        // 检查新字段是否已存在
        final columns = await db.rawQuery("PRAGMA table_info(scheduled_email_tasks)");
        final hasReceiversId = columns.any((col) => col['name'] == 'receivers_id');
        
        if (!hasReceiversId) {
          // 添加新字段
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN receivers_id TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN receivers_name TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN mail_address_id TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN mail_address_name TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN mail_address_type TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN email_tag TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN email_tag_name TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN click_track INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE scheduled_email_tasks ADD COLUMN scheduled_time TEXT');
          
          // 创建新索引
          await db.execute('CREATE INDEX idx_task_receivers_id ON scheduled_email_tasks(receivers_id)');
          await db.execute('CREATE INDEX idx_task_template_id ON scheduled_email_tasks(template_id)');
          await db.execute('CREATE INDEX idx_task_mail_address_id ON scheduled_email_tasks(mail_address_id)');
          await db.execute('CREATE INDEX idx_task_email_tag ON scheduled_email_tasks(email_tag)');
          
          print('数据库升级：已为 scheduled_email_tasks 表添加新字段');
        }
        
        // 检查scheduled_email_task_details表是否存在，如果存在则删除
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='scheduled_email_task_details'"
        );
        
        if (result.isNotEmpty) {
          // 删除旧表
          await db.execute('DROP TABLE scheduled_email_task_details');
          print('数据库升级：已删除 scheduled_email_task_details 表');
        }
      } catch (e) {
        print('数据库升级错误（合并字段）：$e');
      }
    }

    if (oldVersion < 6) {
      // v6: 移除部分字段，保留历史数据
      try {
        // 1. 创建新表（去除指定字段）
        await db.execute('''
          CREATE TABLE scheduled_email_tasks_new (
            task_id TEXT PRIMARY KEY,
            task_name TEXT NOT NULL,
            template_id TEXT NOT NULL,
            template_name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            started_at TEXT,
            completed_at TEXT,
            scheduled_start_time TEXT,
            send_interval_minutes INTEGER,
            error_message TEXT,
            receivers_id TEXT NOT NULL,
            receivers_name TEXT NOT NULL,
            mail_address_id TEXT NOT NULL,
            mail_address_name TEXT NOT NULL,
            mail_address_type TEXT NOT NULL,
            email_tag TEXT NOT NULL,
            email_tag_name TEXT NOT NULL,
            click_track INTEGER NOT NULL DEFAULT 0,
            scheduled_time TEXT
          )
        ''');
        // 2. 迁移数据（只迁移保留字段）
        await db.execute('''
          INSERT INTO scheduled_email_tasks_new (
            task_id, task_name, template_id, template_name, status, created_at, started_at, completed_at, scheduled_start_time, send_interval_minutes, error_message, receivers_id, receivers_name, mail_address_id, mail_address_name, mail_address_type, email_tag, email_tag_name, click_track, scheduled_time
          )
          SELECT
            task_id, task_name, template_id, template_name, status, created_at, started_at, completed_at, scheduled_start_time, send_interval_minutes, error_message, receivers_id, receivers_name, mail_address_id, mail_address_name, mail_address_type, email_tag, email_tag_name, click_track, scheduled_time
          FROM scheduled_email_tasks
        ''');
        // 3. 删除旧表
        await db.execute('DROP TABLE scheduled_email_tasks');
        // 4. 重命名新表
        await db.execute('ALTER TABLE scheduled_email_tasks_new RENAME TO scheduled_email_tasks');
        // 5. 重新创建索引
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_status ON scheduled_email_tasks(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scheduled_time ON scheduled_email_tasks(scheduled_start_time)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_receivers_id ON scheduled_email_tasks(receivers_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_template_id ON scheduled_email_tasks(template_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_mail_address_id ON scheduled_email_tasks(mail_address_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_email_tag ON scheduled_email_tasks(email_tag)');
        print('数据库升级：v6已迁移scheduled_email_tasks表，去除多余字段');
      } catch (e) {
        print('数据库升级错误（v6字段迁移）：$e');
      }
    }

    if (oldVersion < 7) {
      // v7: 进一步移除字段，重命名字段，添加注释
      try {
        // 1. 创建新表（移除更多字段，重命名字段）
        await db.execute('''
          CREATE TABLE scheduled_email_tasks_new (
            task_id TEXT PRIMARY KEY,                    -- 任务id
            task_name TEXT NOT NULL,                     -- 任务名称
            template_id TEXT NOT NULL,                   -- 模板id
            template_name TEXT NOT NULL,                 -- 模板名称
            status TEXT NOT NULL DEFAULT 'pending',      -- 任务状态
            created_at TEXT NOT NULL,                    -- 创建时间
            started_at TEXT,                             -- 任务开始时间
            completed_at TEXT,                           -- 任务完成时间
            send_interval_minutes INTEGER,               -- 任务间隔分钟数
            error_message TEXT,                          -- 错误信息
            receivers_id TEXT NOT NULL,                  -- 收件人列表id
            receivers_name TEXT NOT NULL,                -- 收件人列表名称
            mail_address_id TEXT NOT NULL,               -- 发信地址 ID
            mail_address TEXT NOT NULL,                  -- 发信地址
            mail_address_type TEXT NOT NULL,             -- 发信地址类型
            email_tag_id TEXT NOT NULL,                  -- 邮件标签id
            email_tag_name TEXT NOT NULL,                -- 邮件标签名称
            click_track INTEGER NOT NULL DEFAULT 0,      -- 是否启用跟踪
            scheduled_time TEXT                          -- 任务执行时间
          )
        ''');
        // 2. 迁移数据（只迁移保留字段，重命名字段）
        await db.execute('''
          INSERT INTO scheduled_email_tasks_new (
            task_id, task_name, template_id, template_name, status, created_at, started_at, completed_at, send_interval_minutes, error_message, receivers_id, receivers_name, mail_address_id, mail_address, mail_address_type, email_tag_id, email_tag_name, click_track, scheduled_time
          )
          SELECT
            task_id, task_name, template_id, template_name, status, created_at, started_at, completed_at, send_interval_minutes, error_message, receivers_id, receivers_name, mail_address_id, mail_address_name, mail_address_type, email_tag, email_tag_name, click_track, scheduled_time
          FROM scheduled_email_tasks
        ''');
        // 3. 删除旧表
        await db.execute('DROP TABLE scheduled_email_tasks');
        // 4. 重命名新表
        await db.execute('ALTER TABLE scheduled_email_tasks_new RENAME TO scheduled_email_tasks');
        // 5. 重新创建索引
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_status ON scheduled_email_tasks(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_receivers_id ON scheduled_email_tasks(receivers_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_template_id ON scheduled_email_tasks(template_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_mail_address_id ON scheduled_email_tasks(mail_address_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_email_tag_id ON scheduled_email_tasks(email_tag_id)');
        print('数据库升级：v7已迁移scheduled_email_tasks表，移除多余字段并重命名字段');
      } catch (e) {
        print('数据库升级错误（v7字段迁移）：$e');
      }
    }
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
      where: 'task_name LIKE ? OR template_name LIKE ? OR receivers_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'started_at ASC',
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
      'status': task.status,
      'created_at': task.createdAt.toIso8601String(),
      'started_at': task.startedAt?.toIso8601String(),
      'completed_at': task.completedAt?.toIso8601String(),
      'send_interval_minutes': task.sendIntervalMinutes,
      'error_message': task.errorMessage,
      'receivers_id': task.receiversId,
      'receivers_name': task.receiversName,
      'mail_address_id': task.mailAddressId,
      'mail_address': task.mailAddress,
      'mail_address_type': task.mailAddressType,
      'email_tag_id': task.emailTagId,
      'email_tag_name': task.emailTagName,
      'click_track': task.clickTrack ? 1 : 0,
      'scheduled_time': task.scheduledTime?.toIso8601String(),
    };
  }

  // 将Map转换为ScheduledEmailTaskModel
  ScheduledEmailTaskModel _mapToTask(Map<String, dynamic> map) {
    return ScheduledEmailTaskModel(
      taskId: map['task_id'] as String,
      taskName: map['task_name'] as String,
      templateId: map['template_id'] as String,
      templateName: map['template_name'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      sendIntervalMinutes: map['send_interval_minutes'] as int?,
      errorMessage: map['error_message'] as String?,
      receiversId: map['receivers_id'] as String,
      receiversName: map['receivers_name'] as String,
      mailAddressId: map['mail_address_id'] as String,
      mailAddress: map['mail_address'] as String,
      mailAddressType: map['mail_address_type'] as String,
      emailTagId: map['email_tag_id'] as String,
      emailTagName: map['email_tag_name'] as String,
      clickTrack: (map['click_track'] as int) == 1,
      scheduledTime: map['scheduled_time'] != null ? DateTime.parse(map['scheduled_time'] as String) : null,
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



  // ==================== 发送人名称相关操作 ====================

  // 插入发送人名称
  Future<int> insertSenderName(SenderNameModel senderName) async {
    final db = await database;
    final senderNameMap = _senderNameToMap(senderName);
    return await db.insert('sender_names', senderNameMap);
  }

  // 更新发送人名称
  Future<int> updateSenderName(SenderNameModel senderName) async {
    final db = await database;
    final senderNameMap = _senderNameToMap(senderName);
    return await db.update(
      'sender_names',
      senderNameMap,
      where: 'id = ?',
      whereArgs: [senderName.id],
    );
  }

  // 删除发送人名称
  Future<int> deleteSenderName(String id) async {
    final db = await database;
    return await db.delete(
      'sender_names',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 批量删除发送人名称
  Future<int> deleteSenderNames(List<String> ids) async {
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'sender_names',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // 根据ID获取发送人名称
  Future<SenderNameModel?> getSenderName(String id) async {
    final db = await database;
    final results = await db.query(
      'sender_names',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return _mapToSenderName(results.first);
    }
    return null;
  }

  // 获取所有发送人名称
  Future<List<SenderNameModel>> getAllSenderNames() async {
    final db = await database;
    final results = await db.query('sender_names', orderBy: 'created_at DESC');
    return results.map((map) => _mapToSenderName(map)).toList();
  }

  // 搜索发送人名称
  Future<List<SenderNameModel>> searchSenderNames(String query) async {
    final db = await database;
    final results = await db.query(
      'sender_names',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => _mapToSenderName(map)).toList();
  }

  // 检查发送人名称是否存在
  Future<bool> isSenderNameExists(String name, {String? excludeId}) async {
    final db = await database;
    String whereClause = 'name = ?';
    List<dynamic> whereArgs = [name];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final results = await db.query(
      'sender_names',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return results.isNotEmpty;
  }

  // 获取发送人名称统计信息
  Future<int> getSenderNameCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sender_names');
    return result.first['count'] as int;
  }

  // 将SenderNameModel转换为Map
  Map<String, dynamic> _senderNameToMap(SenderNameModel senderName) {
    return {
      'id': senderName.id,
      'name': senderName.name,
      'created_at': senderName.createdAt,
      'updated_at': senderName.updatedAt,
      'is_default': senderName.isDefault ?? 0,
    };
  }

  // 将Map转换为SenderNameModel
  SenderNameModel _mapToSenderName(Map<String, dynamic> map) {
    return SenderNameModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isDefault: (map['is_default'] is int)
        ? map['is_default'] as int
        : int.tryParse(map['is_default']?.toString() ?? '0') ?? 0,
    );
  }
} 