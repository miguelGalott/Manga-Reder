import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'mongo_service.dart';

class AuthService {
  static String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  /// Cria um novo usuário. Lança uma [Exception] se o usuário já existir.
  /// A senha nunca é salva em texto puro — apenas o hash (SHA-256 + salt).
  static Future<void> register(String username, String password) async {
    final users = await MongoService.collection('users');
    final existing = await users.findOne(where.eq('username', username));
    if (existing != null) {
      throw Exception('Esse nome de usuário já existe.');
    }
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    await users.insertOne({
      'username': username,
      'salt': salt,
      'passwordHash': hash,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Retorna o documento do usuário se usuário/senha estiverem corretos,
  /// ou null caso contrário.
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    final users = await MongoService.collection('users');
    final user = await users.findOne(where.eq('username', username));
    if (user == null) return null;

    final expectedHash = user['passwordHash'] as String?;
    final salt = user['salt'] as String?;
    if (expectedHash == null || salt == null) return null;

    final hash = _hashPassword(password, salt);
    return hash == expectedHash ? user : null;
  }
}
