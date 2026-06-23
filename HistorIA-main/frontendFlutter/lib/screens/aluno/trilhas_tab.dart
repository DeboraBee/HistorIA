import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../../data/models/trilha.dart';
import '../../providers/auth_provider.dart';
import 'exercicio_screen.dart';

class TrilhasTab extends StatefulWidget {
  const TrilhasTab({super.key});

  @override
  State<TrilhasTab> createState() => _TrilhasTabState();
}

class _TrilhasTabState extends State<TrilhasTab> {
  List<Trilha> _trilhas = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final token = context.read<AuthProvider>().token!;
      final trilhas = await ApiService.listarTrilhas(token);
      if (mounted) setState(() => _trilhas = trilhas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro de conexão');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarTrilha(Trilha trilha) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;
    final alunoId = auth.usuario!.id;

    // Tenta iniciar; "já está" é esperado e ignorado
    try {
      await ApiService.iniciarTrilha(alunoId, trilha.id, token);
    } catch (_) {}

    Map<String, dynamic> progresso;
    try {
      progresso = await ApiService.obterProgresso(alunoId, trilha.id, token);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
      return;
    }

    List<Fase> fases;
    try {
      fases = await ApiService.listarFases(trilha.id, token);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
      return;
    }

    if (fases.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Esta trilha ainda não tem fases'),
            backgroundColor: Colors.orange));
      }
      return;
    }

    if (!mounted) return;

    final faseAtualId =
        (progresso['data'] as Map<String, dynamic>)['fase_atual'] as int?;
    final faseObj =
        fases.firstWhere((f) => f.id == faseAtualId, orElse: () => fases.first);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExercicioScreen(
          trilha: trilha,
          fases: fases,
          faseInicial: faseObj,
        ),
      ),
    );

    // Atualiza XP ao voltar
    if (mounted) {
      context.read<AuthProvider>().atualizarXP();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ]),
      );
    }
    if (_trilhas.isEmpty) {
      return const Center(
          child: Text('Nenhuma trilha disponível no momento.',
              style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _trilhas.length,
        itemBuilder: (_, i) {
          final t = _trilhas[i];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF667EEA),
                child: Icon(Icons.school, color: Colors.white),
              ),
              title: Text(t.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Aprenda ${t.nome}',
                  style: const TextStyle(color: Colors.grey)),
              trailing: ElevatedButton(
                onPressed: () => _entrarTrilha(t),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: const Text('Entrar'),
              ),
            ),
          );
        },
      ),
    );
  }
}
