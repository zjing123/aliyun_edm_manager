import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _accessKeyIdKey = 'aliyun_access_key_id';
  static const String _accessKeySecretKey = 'aliyun_access_key_secret';
  
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
    _prefs = await SharedPreferences.getInstance();
  }
  
  // 获取Access Key ID
  String? getAccessKeyId() {
    return _prefs?.getString(_accessKeyIdKey);
  }
  
  // 获取Access Key Secret
  String? getAccessKeySecret() {
    return _prefs?.getString(_accessKeySecretKey);
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
}