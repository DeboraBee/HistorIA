import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../../providers/auth_provider.dart';

class CriarTrilhaScreen extends StatefulWidget {
  const CriarTrilhaScreen({super.key});

  @override
  State<CriarTrilhaScreen> createState() => _CriarTrilhaScreenState();
}

class _CriarTrilhaScreenState extends State<CriarTrilhaScreen> {
  final _nomeTrilhaCtrl = TextEditingController();
  final List<TextEditingController> _fasesCtrls = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _adicionarFase();
  }

  @override
  void dispose() {
    _nomeTrilhaCtrl.dispose();
    for (final c in _fasesCtrls) { c.dispose(); }
    super.dispose();
  }

  void _adicionarFase() =>
      setState(() => _fasesCtrls.add(TextEditingController()));

  void _removerFase(int idx) {
    if (_fasesCtrls.length <= 1) return;
    _fasesCtrls[idx].dispose();
    setState(() => _fasesCtrls.removeAt(idx));
  }

  Future<void> _salvar() async {
    final nome = _nomeTrilhaCtrl.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Digite o nome da trilha'),
          backgroundColor: Colors.orange));
      return;
    }

    final fasesValidas = _fasesCtrls
        .asMap()
        .entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .toList();

    setState(() => _loading = true);
    try {
      final auth       = context.read<AuthProvider>();
      final token      = auth.token!;
      final professorId = auth.usuario!.id;

      final trilhaId = await ApiService.criarTrilha(nome, professorId, token);

      for (final entry in fasesValidas) {
        await ApiService.criarFase(
            trilhaId, entry.value.text.trim(), entry.key + 1, token);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trilha criada com sucesso!'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro de conexão'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Trilha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nomeTrilhaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome da trilha',
                hintText: 'Ex: Revolução Francesa',
                prefixIcon: Icon(Icons.route_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fases',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _adicionarFase,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar fase'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_fasesCtrls.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF667EEA),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _fasesCtrls[i],
                        decoration: InputDecoration(
                          hintText: 'Nome da fase ${i + 1}',
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    if (_fasesCtrls.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => _removerFase(i),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Criar Trilha'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
