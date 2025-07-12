abstract class StorageService {
  Future<void> saveSecretKey({
    required String secretKey,
    required String issuer,
  });
  
  Future<(String,String)> getSecretKey({
    String issuer
  });

  Future<Map<String,String>> getAllSecretKeys();
}