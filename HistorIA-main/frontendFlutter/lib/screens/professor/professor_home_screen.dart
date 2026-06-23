import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'alunos_tab.dart';
import 'trilhas_tab_prof.dart';

class ProfessorHomeScreen extends StatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  State<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends State<ProfessorHomeScreen> {
  int _tabIndex = 0;

  final _tabs = const [TrilhasTabProf(), AlunosTab()];

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.cast_for_education_outlined, size: 20),
            const SizedBox(width: 8),
            Text(usuario.nome),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmarSaida(context),
          ),
        ],
      ),
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.route_outlined), label: 'Trilhas'),
          NavigationDestination(
              icon: Icon(Icons.people_outline), label: 'Alunos'),
        ],
      ),
    );
  }

  Future<void> _confirmarSaida(BuildContext context) async {
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
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
