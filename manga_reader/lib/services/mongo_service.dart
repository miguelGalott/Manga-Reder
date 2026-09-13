import 'package:mongo_dart/mongo_dart.dart';

/// Configuração de conexão com o MongoDB.
///
/// IMPORTANTE: como esse IP (10.112.4.57) é um endereço privado, o app só
/// consegue se conectar quando o celular/emulador estiver na mesma rede local
/// (ex: wifi do laboratório da faculdade). Fora dessa rede, toda operação que
/// depende do banco (login, favoritos, histórico, comentários) vai falhar com
/// erro de conexão — isso é esperado, não é bug de código.
class MongoService {
  static const String _host = '10.112.4.57';
  static const int _port = 27017;
  static const String _dbName = 'aluno';
  static const String _username = 'aluno';
  static const String _password = 'aluno';

  static Db? _db;
  static Future<Db>? _connecting;

  static Future<Db> get _instance {
    final current = _db;
    if (current != null) return Future.value(current);
    return _connecting ??= _connect();
  }

  static Future<Db> _connect() async {
    // Se a autenticação falhar com "auth failed", tente adicionar
    // "?authSource=admin" no fim da uri abaixo — é comum o usuário do
    // MongoDB ter sido criado no banco "admin" em vez do banco de dados
    // da aplicação.
    final uri = 'mongodb://$_username:$_password@$_host:$_port/$_dbName';
    final db = Db(uri);
    await db.open();
    _db = db;
    return db;
  }

  static Future<DbCollection> collection(String name) async {
    final db = await _instance;
    return db.collection(name);
  }
}
