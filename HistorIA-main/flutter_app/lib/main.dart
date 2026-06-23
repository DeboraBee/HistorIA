import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/aluno/aluno_home_screen.dart';
import 'screens/professor/professor_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthProvider();
  await auth.carregarSessao(); // restaura sessão persistida

  runApp(
    ChangeNotifierProvider.value(
      value: auth,
      child: const HistorIAApp(),
    ),
  );
}

class HistorIAApp extends StatelessWidget {
  const HistorIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HistorIA',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const _AuthGate(),
        '/aluno': (_) => const AlunoHomeScreen(),
        '/professor': (_) => const ProfessorHomeScreen(),
      },
    );
  }
}

/// Redireciona para a tela certa se já houver sessão ativa,
/// ou exibe a tela de login caso contrário.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      return auth.usuario!.tipo == 'professor'
          ? const ProfessorHomeScreen()
          : const AlunoHomeScreen();
    }

    return const LoginScreen();
  }
}
