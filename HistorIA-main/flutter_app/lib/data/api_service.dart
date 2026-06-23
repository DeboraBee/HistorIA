import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'models/usuario.dart';
import 'models/trilha.dart';
import 'models/questao.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(body['detail']?.toString() ?? 'Erro ${res.statusCode}');
    }
    return body;
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await http.post(
      Uri.parse('${Api.auth}/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    return _parse(res);
  }

  static Future<void> registrar(
      String nome, String email, String senha, String tipo) async {
    final res = await http.post(
      Uri.parse('${Api.auth}/registrar'),
      headers: _headers(null),
      body: jsonEncode({'nome': nome, 'email': email, 'senha': senha, 'tipo': tipo}),
    );
    _parse(res);
  }

  // ── ALUNOS ────────────────────────────────────────────────────────────────

  static Future<Usuario> obterAluno(int id, String token) async {
    final res = await http.get(
      Uri.parse('${Api.alunos}/$id'),
      headers: _headers(token),
    );
    final body = _parse(res);
    return Usuario.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<List<Usuario>> listarAlunos(String token) async {
    final res = await http.get(
      Uri.parse('${Api.alunos}/'),
      headers: _headers(token),
    );
    final body = _parse(res);
    return (body['data'] as List)
        .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> criarAluno(String nome, String email, String token) async {
    final res = await http.post(
      Uri.parse('${Api.alunos}/'),
      headers: _headers(token),
      body: jsonEncode({'nome': nome, 'email': email}),
    );
    _parse(res);
  }

  static Future<void> deletarAluno(int id, String token) async {
    final res = await http.delete(
      Uri.parse('${Api.alunos}/$id'),
      headers: _headers(token),
    );
    _parse(res);
  }

  // ── TRILHAS ───────────────────────────────────────────────────────────────

  static Future<List<Trilha>> listarTrilhas(String token) async {
    final res = await http.get(
      Uri.parse('${Api.trilhas}/'),
      headers: _headers(token),
    );
    final body = _parse(res);
    return (body['data'] as List)
        .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<int> criarTrilha(String nome, int professorId, String token) async {
    final res = await http.post(
      Uri.parse('${Api.trilhas}/'),
      headers: _headers(token),
      body: jsonEncode({'nome': nome, 'professor_id': professorId}),
    );
    final body = _parse(res);
    return (body['data'] as Map<String, dynamic>)['id'] as int;
  }

  static Future<void> deletarTrilha(int id, String token) async {
    final res = await http.delete(
      Uri.parse('${Api.trilhas}/$id'),
      headers: _headers(token),
    );
    _parse(res);
  }

  static Future<List<Fase>> listarFases(int trilhaId, String token) async {
    final res = await http.get(
      Uri.parse('${Api.trilhas}/$trilhaId/fases'),
      headers: _headers(token),
    );
    final body = _parse(res);
    return (body['data'] as List)
        .map((e) => Fase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> criarFase(
      int trilhaId, String nome, int ordem, String token) async {
    final res = await http.post(
      Uri.parse('${Api.trilhas}/fases'),
      headers: _headers(token),
      body: jsonEncode({'trilha_id': trilhaId, 'nome': nome, 'ordem': ordem}),
    );
    _parse(res);
  }

  static Future<Map<String, dynamic>> iniciarTrilha(
      int alunoId, int trilhaId, String token) async {
    final res = await http.post(
      Uri.parse('${Api.trilhas}/progresso'),
      headers: _headers(token),
      body: jsonEncode({'aluno_id': alunoId, 'trilha_id': trilhaId}),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> obterProgresso(
      int alunoId, int trilhaId, String token) async {
    final res = await http.get(
      Uri.parse('${Api.trilhas}/progresso/$alunoId/$trilhaId'),
      headers: _headers(token),
    );
    return _parse(res);
  }

  // ── EXERCÍCIOS ────────────────────────────────────────────────────────────

  static Future<List<Questao>> gerarQuestoes(
      String tema, int quantidade, String token) async {
    final res = await http.post(
      Uri.parse('${Api.exercicios}/gerar'),
      headers: _headers(token),
      body: jsonEncode({'tema': tema, 'quantidade': quantidade}),
    );
    final body = _parse(res);
    return (body['data'] as List)
        .map((e) => Questao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> jogar({
    required int alunoId,
    required String pergunta,
    required int respostaUsuario,
    required int respostaCorreta,
    required List<String> opcoes,
    required int trilhaId,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('${Api.exercicios}/jogar'),
      headers: _headers(token),
      body: jsonEncode({
        'aluno_id': alunoId,
        'pergunta': pergunta,
        'resposta_usuario': respostaUsuario,
        'resposta_correta': respostaCorreta,
        'opcoes': opcoes,
        'trilha_id': trilhaId,
      }),
    );
    return _parse(res);
  }

  static Future<List<HistoricoItem>> obterHistorico(
      int alunoId, String token) async {
    final res = await http.get(
      Uri.parse('${Api.exercicios}/historico/$alunoId'),
      headers: _headers(token),
    );
    final body = _parse(res);
    return (body['data'] as List)
        .map((e) => HistoricoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
