import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../../data/models/usuario.dart';
import '../../providers/auth_provider.dart';

class AlunosTab extends StatefulWidget {
  const AlunosTab({super.key});

  @override
  State<AlunosTab> createState() => _AlunosTabState();
}

class _AlunosTabState extends State<AlunosTab> {
  List<Usuario> _alunos = [];
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
      final alunos = await ApiService.listarAlunos(token);
      if (mounted) setState(() => _alunos = alunos);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro de conexão');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletar(Usuario aluno) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deletar Aluno'),
        content: Text(
            'Deseja deletar "${aluno.nome}"?\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Deletar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirma != true || !mounted) return;

    try {
      final token = context.read<AuthProvider>().token!;
      await ApiService.deletarAluno(aluno.id, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Aluno deletado!'),
            backgroundColor: Colors.green));
        _carregar();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    }
  }

  void _abrirModalCriarAluno() {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Novo Aluno',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final nome = nomeCtrl.text.trim();
                  final email = emailCtrl.text.trim();
                  if (nome.isEmpty || email.isEmpty) return;

                  try {
                    final token = context.read<AuthProvider>().token!;
                    await ApiService.criarAluno(nome, email, token);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('✅ Aluno criado!'),
                          backgroundColor: Colors.green));
                      _carregar();
                    }
                  } on ApiException catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(e.message),
                          backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Criar Aluno'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_erro!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente')),
                  ]),
                )
              : _alunos.isEmpty
                  ? const Center(
                      child: Text('Nenhum aluno cadastrado.',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _alunos.length,
                        itemBuilder: (_, i) {
                          final a = _alunos[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF667EEA),
                                child: Text(a.nome[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(a.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(a.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text('⭐ ${a.xp} XP',
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: const Color(0xFFEEF0FF),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _deletar(a),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalCriarAluno,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Aluno'),
      ),
    );
  }
}
