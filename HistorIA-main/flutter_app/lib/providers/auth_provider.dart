import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_service.dart';
import '../data/models/usuario.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  String? _token;

  Usuario? get usuario => _usuario;
  String? get token => _token;
  bool get isLoggedIn => _usuario != null && _token != null;

  // Carrega sessão persistida ao abrir o app
  Future<void> carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final id = prefs.getInt('user_id');
    final nome = prefs.getString('user_nome');
    final email = prefs.getString('user_email');
    final tipo = prefs.getString('user_tipo');
    final xp = prefs.getInt('user_xp') ?? 0;

    if (token != null && id != null && nome != null && email != null && tipo != null) {
      _token = token;
      _usuario = Usuario(id: id, nome: nome, email: email, tipo: tipo, xp: xp);
      notifyListeners();
    }
  }

  Future<String> login(String email, String senha) async {
    final data = await ApiService.login(email, senha);
    final token = data['token'] as String?;
    if (token == null) throw const ApiException('Token não retornado pelo servidor');

    final userJson = data['data'] as Map<String, dynamic>;
    _usuario = Usuario.fromJson(userJson);
    _token = token;
    await _persistir();
    notifyListeners();
    return _usuario!.tipo;
  }

  Future<void> registrar(
      String nome, String email, String senha, String tipo) async {
    await ApiService.registrar(nome, email, senha, tipo);
  }

  Future<void> atualizarXP() async {
    if (_usuario == null || _token == null) return;
    try {
      final atualizado = await ApiService.obterAluno(_usuario!.id, _token!);
      _usuario = _usuario!.copyWith(xp: atualizado.xp);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_xp', atualizado.xp);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    _usuario = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setInt('user_id', _usuario!.id);
    await prefs.setString('user_nome', _usuario!.nome);
    await prefs.setString('user_email', _usuario!.email);
    await prefs.setString('user_tipo', _usuario!.tipo);
    await prefs.setInt('user_xp', _usuario!.xp);
  }
}
