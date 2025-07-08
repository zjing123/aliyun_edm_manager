import 'package:aliyun_edm_manager/services/database/database_service.dart';
import 'package:aliyun_edm_manager/models/sender/sender_name_model.dart';

class SenderNameService {
  final DatabaseService _databaseService = DatabaseService();

  /// 创建发送人名称
  Future<bool> createSenderName(String name, {int isDefault = 0}) async {
    try {
      // 检查名称是否已存在
      final exists = await _databaseService.isSenderNameExists(name);
      if (exists) {
        throw Exception('发送人名称已存在');
      }

      final now = DateTime.now().toIso8601String();
      final senderName = SenderNameModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        createdAt: now,
        updatedAt: now,
        isDefault: isDefault,
      );

      await _databaseService.insertSenderName(senderName);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新发送人名称
  Future<bool> updateSenderName(String id, String name, {int isDefault = 0}) async {
    try {
      // 检查名称是否已存在（排除当前记录）
      final exists = await _databaseService.isSenderNameExists(name, excludeId: id);
      if (exists) {
        throw Exception('发送人名称已存在');
      }

      final senderName = await _databaseService.getSenderName(id);
      if (senderName == null) {
        throw Exception('发送人名称不存在');
      }

      final updatedSenderName = SenderNameModel(
        id: id,
        name: name.trim(),
        createdAt: senderName.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        isDefault: isDefault,
      );

      await _databaseService.updateSenderName(updatedSenderName);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 删除发送人名称
  Future<bool> deleteSenderName(String id) async {
    try {
      final result = await _databaseService.deleteSenderName(id);
      return result > 0;
    } catch (e) {
      rethrow;
    }
  }

  /// 批量删除发送人名称
  Future<bool> deleteSenderNames(List<String> ids) async {
    try {
      final result = await _databaseService.deleteSenderNames(ids);
      return result > 0;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取所有发送人名称
  Future<List<SenderNameModel>> getAllSenderNames() async {
    try {
      return await _databaseService.getAllSenderNames();
    } catch (e) {
      rethrow;
    }
  }

  /// 搜索发送人名称
  Future<List<SenderNameModel>> searchSenderNames(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllSenderNames();
      }
      return await _databaseService.searchSenderNames(query.trim());
    } catch (e) {
      rethrow;
    }
  }

  /// 根据ID获取发送人名称
  Future<SenderNameModel?> getSenderName(String id) async {
    try {
      return await _databaseService.getSenderName(id);
    } catch (e) {
      rethrow;
    }
  }

  /// 检查发送人名称是否存在
  Future<bool> isSenderNameExists(String name, {String? excludeId}) async {
    try {
      return await _databaseService.isSenderNameExists(name, excludeId: excludeId);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取发送人名称数量
  Future<int> getSenderNameCount() async {
    try {
      return await _databaseService.getSenderNameCount();
    } catch (e) {
      rethrow;
    }
  }

  /// 设为默认发送人名称（唯一）
  Future<bool> setDefaultSenderName(String id) async {
    try {
      // 1. 先将所有发送人名称的 isDefault 设为 0
      final db = _databaseService;
      final allSenderNames = await db.getAllSenderNames();
      for (final sender in allSenderNames) {
        if (sender.isDefault == 1) {
          await db.updateSenderName(sender.copyWith(isDefault: 0));
        }
      }
      // 2. 将目标发送人名称 isDefault 设为 1
      final target = await db.getSenderName(id);
      if (target == null) throw Exception('发送人名称不存在');
      await db.updateSenderName(target.copyWith(isDefault: 1));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 取消默认发送人名称
  Future<bool> unsetDefaultSenderName([String? id]) async {
    try {
      final db = _databaseService;
      if (id != null) {
        final target = await db.getSenderName(id);
        if (target != null && target.isDefault == 1) {
          await db.updateSenderName(target.copyWith(isDefault: 0));
        }
      } else {
        final allSenderNames = await db.getAllSenderNames();
        for (final sender in allSenderNames) {
          if (sender.isDefault == 1) {
            await db.updateSenderName(sender.copyWith(isDefault: 0));
          }
        }
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }
} 