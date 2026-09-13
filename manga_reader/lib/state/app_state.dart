import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  String? _username;
  bool _loading = true;

  String? get username => _username;
  bool get isLoggedIn => _username != null;
  bool get isLoading => _loading;

  /// Verifica se já existe uma sessão salva (chamado uma vez, ao abrir o app).
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    _username = username;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    _username = null;
    notifyListeners();
  }
}
