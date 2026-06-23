import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../../data/models/trilha.dart';
import '../../providers/auth_provider.dart';
import 'criar_trilha_screen.dart';

class TrilhasTabProf extends StatefulWidget {
  const TrilhasTabProf({super.key});

  @override
  State<TrilhasTabProf> createState() => _TrilhasTabProfState();
}

class _TrilhasTabProfState extends State<TrilhasTabProf> {
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

  Future<void> _deletar(Trilha t) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deletar Trilha'),
        content: Text('Deseja deletar "${t.nome}"?\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deletar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirma != true || !mounted) return;

    try {
      final token = context.read<AuthProvider>().token!;
      await ApiService.deletarTrilha(t.id, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Trilha deletada!'),
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
              : _trilhas.isEmpty
                  ? const Center(
                      child: Text('Nenhuma trilha criada ainda.',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
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
                                child:
                                    Icon(Icons.school, color: Colors.white),
                              ),
                              title: Text(t.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text('ID: ${t.id}',
                                  style: const TextStyle(color: Colors.grey)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deletar(t),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CriarTrilhaScreen()));
          _carregar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Trilha'),
      ),
    );
  }
}
