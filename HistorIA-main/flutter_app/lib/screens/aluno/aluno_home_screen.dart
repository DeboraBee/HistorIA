import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'trilhas_tab.dart';
import 'historico_tab.dart';

class AlunoHomeScreen extends StatefulWidget {
  const AlunoHomeScreen({super.key});

  @override
  State<AlunoHomeScreen> createState() => _AlunoHomeScreenState();
}

class _AlunoHomeScreenState extends State<AlunoHomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Sincroniza XP ao abrir o home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().atualizarXP();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario!;

    return Scaffold(
      appBar: AppBar(
        title: Text('👨‍🎓 ${usuario.nome}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text('⭐ ${usuario.xp} XP',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF764BA2),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              final confirma = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja encerrar a sessão?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sair')),
                  ],
                ),
              );
              if (confirma == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [TrilhasTab(), HistoricoTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school), label: 'Trilhas'),
          NavigationDestination(
              icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }
}
