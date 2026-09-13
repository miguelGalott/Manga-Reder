import 'package:mongo_dart/mongo_dart.dart';


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
