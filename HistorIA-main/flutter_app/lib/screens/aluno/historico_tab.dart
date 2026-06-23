import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../../data/models/questao.dart';
import '../../providers/auth_provider.dart';

class HistoricoTab extends StatefulWidget {
  const HistoricoTab({super.key});

  @override
  State<HistoricoTab> createState() => _HistoricoTabState();
}

class _HistoricoTabState extends State<HistoricoTab> {
  List<HistoricoItem> _itens = [];
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
      final auth = context.read<AuthProvider>();
      final itens =
          await ApiService.obterHistorico(auth.usuario!.id, auth.token!);
      if (mounted) setState(() => _itens = itens);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro de conexão');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_erro != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ]),
      );
    }

    if (_itens.isEmpty) {
      return const Center(
          child: Text('Nenhuma resposta registrada ainda.',
              style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _itens.length,
        itemBuilder: (_, i) {
          final item = _itens[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    item.acertou ? Colors.green[100] : Colors.red[100],
                child: Text(item.acertou ? '✅' : '❌',
                    style: const TextStyle(fontSize: 18)),
              ),
              title: Text(
                item.pergunta.length > 60
                    ? '${item.pergunta.substring(0, 60)}…'
                    : item.pergunta,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: Chip(
                label: Text(item.acertou ? '+10 XP' : '0 XP',
                    style: TextStyle(
                        color: item.acertou ? Colors.green[800] : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                backgroundColor:
                    item.acertou ? Colors.green[50] : Colors.grey[100],
              ),
            ),
          );
        },
      ),
    );
  }
}
