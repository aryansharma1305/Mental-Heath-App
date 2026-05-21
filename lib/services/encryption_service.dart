import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _keyName = 'mca_db_key';
  final FlutterSecureStorage _secureStorage;

  EncryptionService({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : _secureStorage = secureStorage;

  Future<String> getDatabaseKey() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) return existing;

    final key = generateKey();
    await _secureStorage.write(key: _keyName, value: key);
    return key;
  }

  static String generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
