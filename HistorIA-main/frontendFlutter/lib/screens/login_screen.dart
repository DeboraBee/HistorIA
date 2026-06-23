import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/api_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = false;

  final _emailLoginCtrl = TextEditingController();
  final _senhaLoginCtrl = TextEditingController();
  final _nomeCtrl       = TextEditingController();
  final _emailCadCtrl   = TextEditingController();
  final _senhaCadCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  String _tipo = 'aluno';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailLoginCtrl.dispose();
    _senhaLoginCtrl.dispose();
    _nomeCtrl.dispose();
    _emailCadCtrl.dispose();
    _senhaCadCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? Colors.red[700] : Colors.green[700],
    ));
  }

  Future<void> _login() async {
    final email = _emailLoginCtrl.text.trim();
    final senha = _senhaLoginCtrl.text;
    if (email.isEmpty || senha.isEmpty) {
      _snack('Preencha todos os campos', erro: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final tipo = await context.read<AuthProvider>().login(email, senha);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, tipo == 'professor' ? '/professor' : '/aluno');
    } on ApiException catch (e) {
      _snack(e.message, erro: true);
    } catch (_) {
      _snack('Erro de conexão. Verifique o servidor.', erro: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cadastrar() async {
    final nome    = _nomeCtrl.text.trim();
    final email   = _emailCadCtrl.text.trim();
    final senha   = _senhaCadCtrl.text;
    final confirm = _confirmCtrl.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirm.isEmpty) {
      _snack('Preencha todos os campos', erro: true);
      return;
    }
    if (senha.length < 6) {
      _snack('Senha deve ter no mínimo 6 caracteres', erro: true);
      return;
    }
    if (senha != confirm) {
      _snack('As senhas não conferem', erro: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().registrar(nome, email, senha, _tipo);
      if (!mounted) return;
      _snack('Cadastro realizado! Faça login.');
      _tabs.animateTo(0);
    } on ApiException catch (e) {
      _snack(e.message, erro: true);
    } catch (_) {
      _snack('Erro de conexão. Verifique o servidor.', erro: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: purpleGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_edu,
                        size: 48, color: Color(0xFF667EEA)),
                    const SizedBox(height: 8),
                    const Text('HistorIA',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667EEA))),
                    const SizedBox(height: 4),
                    const Text('Plataforma Educacional Gamificada',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    TabBar(
                      controller: _tabs,
                      labelColor: const Color(0xFF667EEA),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF667EEA),
                      tabs: const [Tab(text: 'Entrar'), Tab(text: 'Cadastrar')],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 380,
                      child: TabBarView(
                        controller: _tabs,
                        children: [_buildLogin(), _buildCadastro()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        TextField(
          controller: _emailLoginCtrl,
          decoration: const InputDecoration(
              labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _senhaLoginCtrl,
          decoration: const InputDecoration(
              labelText: 'Senha', prefixIcon: Icon(Icons.lock_outlined)),
          obscureText: true,
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Entrar'),
          ),
        ),
      ],
    );
  }

  Widget _buildCadastro() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              _tipoCard(Icons.school_outlined, 'Aluno', 'aluno'),
              const SizedBox(width: 12),
              _tipoCard(Icons.cast_for_education_outlined, 'Professor', 'professor'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outlined)),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCadCtrl,
            decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _senhaCadCtrl,
            decoration: const InputDecoration(
                labelText: 'Senha', prefixIcon: Icon(Icons.lock_outlined)),
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            decoration: const InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: Icon(Icons.lock_outlined)),
            obscureText: true,
            onSubmitted: (_) => _cadastrar(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _cadastrar,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Cadastrar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoCard(IconData icon, String label, String value) {
    final selected = _tipo == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipo = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF667EEA) : Colors.transparent,
            border: Border.all(
                color: selected ? const Color(0xFF667EEA) : Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 28,
                  color: selected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
