import 'package:totpfy/core/storage/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService implements StorageService {

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static SecureStorageService? _instance;

  SecureStorageService._();

  factory SecureStorageService() {
    return _instance ??= SecureStorageService._();
  }

  @override
  Future<void> saveSecretKey({required String secretKey, required String issuer}) async {
    try {
      await _secureStorage.write(key: issuer, value: secretKey);
    } catch (e) {
      throw Exception('Failed to save secret key: $e');
    }
  }
  
  @override
  Future<(String, String)> getSecretKey({String? issuer}) async {
    try {
      final secretKey = await _secureStorage.read(key: issuer ?? '');
      return (secretKey ?? '', issuer ?? '');
    } catch (e) {
      throw Exception('Failed to get secret key: $e');
    }
  }

  @override
  Future<Map<String, String>> getAllSecretKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      return allKeys;
    } catch (e) {
      throw Exception('Failed to get all secret keys: $e');
    }
  }

  @override
  Future<void> deleteSecretKey({required String issuer}) async {
    try {
      await _secureStorage.delete(key: issuer);
    } catch (e) {
      throw Exception('Failed to delete secret key: $e');
    }
  }
}