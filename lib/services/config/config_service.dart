import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _accessKeyIdKey = 'aliyun_access_key_id';
  static const String _accessKeySecretKey = 'aliyun_access_key_secret';
  static const String _filterEmailsKey = 'default_filter_emails';
  
  static ConfigService? _instance;
  SharedPreferences? _prefs;
  
  ConfigService._();
  
  static Future<ConfigService> getInstance() async {
    if (_instance == null) {
      _instance = ConfigService._();
      await _instance!._init();
    }
    return _instance!;
  }
  
  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print('ConfigService初始化成功');
    } catch (e) {
      print('ConfigService初始化失败: $e');
      // 在桌面端，如果SharedPreferences失败，使用内存存储
      _prefs = null;
    }
  }
  
  // 获取Access Key ID
  String? getAccessKeyId() {
    final id = _prefs?.getString(_accessKeyIdKey);
    print('ConfigService.getAccessKeyId: $id');
    return id;
  }
  
  // 获取Access Key Secret
  String? getAccessKeySecret() {
    final secret = _prefs?.getString(_accessKeySecretKey);
    print('ConfigService.getAccessKeySecret: ${secret != null ? '已配置' : '未配置'}');
    return secret;
  }
  
  // 保存Access Key ID
  Future<bool> setAccessKeyId(String accessKeyId) async {
    return await _prefs?.setString(_accessKeyIdKey, accessKeyId) ?? false;
  }
  
  // 保存Access Key Secret
  Future<bool> setAccessKeySecret(String accessKeySecret) async {
    return await _prefs?.setString(_accessKeySecretKey, accessKeySecret) ?? false;
  }
  
  // 同时保存两个密钥
  Future<bool> saveConfig(String accessKeyId, String accessKeySecret) async {
    final result1 = await setAccessKeyId(accessKeyId);
    final result2 = await setAccessKeySecret(accessKeySecret);
    return result1 && result2;
  }
  
  // 获取默认过滤邮箱列表
  List<String> getFilterEmails() {
    final emailsStr = _prefs?.getString(_filterEmailsKey);
    if (emailsStr == null || emailsStr.isEmpty) {
      return [];
    }
    return emailsStr.split('\n')
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty)
        .toList();
  }
  
  // 保存默认过滤邮箱列表
  Future<bool> setFilterEmails(List<String> emails) async {
    final emailsStr = emails.join('\n');
    return await _prefs?.setString(_filterEmailsKey, emailsStr) ?? false;
  }
  
  // 添加单个过滤邮箱
  Future<bool> addFilterEmail(String email) async {
    final currentEmails = getFilterEmails();
    if (!currentEmails.contains(email.trim())) {
      currentEmails.add(email.trim());
      return await setFilterEmails(currentEmails);
    }
    return true;
  }
  
  // 删除单个过滤邮箱
  Future<bool> removeFilterEmail(String email) async {
    final currentEmails = getFilterEmails();
    currentEmails.remove(email.trim());
    return await setFilterEmails(currentEmails);
  }
  
  // 清空过滤邮箱列表
  Future<bool> clearFilterEmails() async {
    return await _prefs?.remove(_filterEmailsKey) ?? false;
  }
  
  // 检查配置是否完整
  bool isConfigured() {
    final accessKeyId = getAccessKeyId();
    final accessKeySecret = getAccessKeySecret();
    return accessKeyId != null && 
           accessKeyId.isNotEmpty && 
           accessKeySecret != null && 
           accessKeySecret.isNotEmpty;
  }
  
  // 清除配置
  Future<bool> clearConfig() async {
    final result1 = await _prefs?.remove(_accessKeyIdKey) ?? false;
    final result2 = await _prefs?.remove(_accessKeySecretKey) ?? false;
    return result1 && result2;
  }
  
  // 禁止删除的收件人列表ID相关方法
  static const String _forbiddenDeleteReceiverIdsKey = 'forbidden_delete_receiver_ids';
  
  // 获取禁止删除的收件人列表ID集合
  Future<Set<String>> getForbiddenDeleteReceiverIds() async {
    final ids = _prefs?.getStringList(_forbiddenDeleteReceiverIdsKey) ?? [];
    return ids.toSet();
  }
  
  // 设置禁止删除的收件人列表ID集合
  Future<bool> setForbiddenDeleteReceiverIds(Set<String> ids) async {
    return await _prefs?.setStringList(_forbiddenDeleteReceiverIdsKey, ids.toList()) ?? false;
  }
  
  // 添加一个禁止删除的收件人列表ID
  Future<bool> addForbiddenDeleteReceiverId(String id) async {
    final ids = await getForbiddenDeleteReceiverIds();
    ids.add(id);
    return await setForbiddenDeleteReceiverIds(ids);
  }
  
  // 移除一个禁止删除的收件人列表ID
  Future<bool> removeForbiddenDeleteReceiverId(String id) async {
    final ids = await getForbiddenDeleteReceiverIds();
    ids.remove(id);
    return await setForbiddenDeleteReceiverIds(ids);
  }
  
  // 清理不存在的收件人列表ID（传入当前存在的ID列表）
  Future<bool> cleanNonExistentReceiverIds(List<String> existingIds) async {
    final forbiddenIds = await getForbiddenDeleteReceiverIds();
    final existingIdsSet = existingIds.toSet();
    final cleanedIds = forbiddenIds.where((id) => existingIdsSet.contains(id)).toSet();
    return await setForbiddenDeleteReceiverIds(cleanedIds);
  }
  
  // 清空所有禁止删除的收件人列表ID
  Future<bool> clearForbiddenDeleteReceiverIds() async {
    return await _prefs?.remove(_forbiddenDeleteReceiverIdsKey) ?? false;
  }
}