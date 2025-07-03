import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const _accessKeyIdKey = 'access_key_id';
  static const _accessKeySecretKey = 'access_key_secret';

  static String? _accessKeyId;
  static String? _accessKeySecret;

  static String? get accessKeyId => _accessKeyId;
  static String? get accessKeySecret => _accessKeySecret;

  /// Load existing configuration from persistent storage. Must be called once at app startup.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessKeyId = prefs.getString(_accessKeyIdKey);
    _accessKeySecret = prefs.getString(_accessKeySecretKey);
  }

  /// Save new credentials to persistent storage.
  static Future<void> setAccessKey({required String accessKeyId, required String accessKeySecret}) async {
    _accessKeyId = accessKeyId;
    _accessKeySecret = accessKeySecret;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKeyIdKey, accessKeyId);
    await prefs.setString(_accessKeySecretKey, accessKeySecret);
  }
}