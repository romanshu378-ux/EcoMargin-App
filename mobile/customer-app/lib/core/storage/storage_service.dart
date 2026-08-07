import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _tokenKey = 'jwt_token';
  static const String _userBox = 'user_box';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_userBox);
  }

  // Secure Token Storage
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // General App Data Storage
  Future<void> saveData(String key, dynamic value) async {
    await _box.put(key, value);
  }

  dynamic getData(String key) {
    return _box.get(key);
  }
}
