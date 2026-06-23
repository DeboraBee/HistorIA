import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../../data/models/questao.dart';
import '../../data/models/trilha.dart';
import '../../providers/auth_provider.dart';

class ExercicioScreen extends StatefulWidget {
  final Trilha trilha;
  final List<Fase> fases;
  final Fase faseInicial;

  const ExercicioScreen({
    super.key,
    required this.trilha,
    required this.fases,
    required this.faseInicial,
  });

  @override
  State<ExercicioScreen> createState() => _ExercicioScreenState();
}

class _ExercicioScreenState extends State<ExercicioScreen> {
  static const int _questoesPorFase = 3;

  late Fase _faseAtual;
  int _questaoAtual = 1;
  bool _carregando = true;
  Questao? _questao;
  int? _respostaSelecionada;
  bool? _acertou;
  bool _respondida = false;

  @override
  void initState() {
    super.initState();
    _faseAtual = widget.faseInicial;
    _carregarQuestao();
  }

  Future<void> _carregarQuestao() async {
    setState(() {
      _carregando = true;
      _questao = null;
      _respostaSelecionada = null;
      _acertou = null;
      _respondida = false;
    });
    try {
      final token = context.read<AuthProvider>().token!;
      final tema = _faseAtual.nome.isNotEmpty ? _faseAtual.nome : widget.trilha.nome;
      final questoes = await ApiService.gerarQuestoes(tema, 1, token);
      if (mounted) setState(() => _questao = questoes.first);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _responder(int idx) async {
    if (_respondida || _questao == null) return;
    final auth = context.read<AuthProvider>();

    setState(() {
      _respostaSelecionada = idx;
      _acertou = idx == _questao!.respostaCorreta;
      _respondida = true;
    });

    try {
      await ApiService.jogar(
        alunoId: auth.usuario!.id,
        pergunta: _questao!.pergunta,
        respostaUsuario: idx,
        respostaCorreta: _questao!.respostaCorreta,
        opcoes: _questao!.opcoes,
        trilhaId: widget.trilha.id,
        token: auth.token!,
      );
      await auth.atualizarXP();
    } catch (_) {}
  }

  void _proxima() {
    final ultimaQuestao = _questaoAtual >= _questoesPorFase;
    final indiceFase = widget.fases.indexOf(_faseAtual);
    final ultimaFase = indiceFase >= widget.fases.length - 1;

    if (ultimaQuestao && ultimaFase) {
      _concluir();
      return;
    }

    if (ultimaQuestao) {
      setState(() {
        _faseAtual = widget.fases[indiceFase + 1];
        _questaoAtual = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fase ${indiceFase + 2} iniciada'),
        backgroundColor: Colors.blue,
      ));
    } else {
      setState(() => _questaoAtual++);
    }

    _carregarQuestao();
  }

  void _concluir() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.emoji_events_outlined,
            size: 48, color: Color(0xFF667EEA)),
        title: const Text('Parabéns!'),
        content: const Text('Você completou toda a trilha!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Voltar às Trilhas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faseIdx = widget.fases.indexOf(_faseAtual) + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trilha.nome),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Fase $faseIdx/${widget.fases.length}  ·  Questão $_questaoAtual/$_questoesPorFase',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _questao == null
              ? const Center(child: Text('Não foi possível carregar a questão.'))
              : _buildQuestao(),
    );
  }

  Widget _buildQuestao() {
    final q = _questao!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFFF7F7FF),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(q.pergunta,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(q.opcoes.length, (i) => _buildOpcao(i, q)),
          if (_respondida) ...[
            const SizedBox(height: 16),
            _buildFeedback(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _proxima,
                icon: Icon(
                  _questaoAtual >= _questoesPorFase &&
                          widget.fases.indexOf(_faseAtual) >=
                              widget.fases.length - 1
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward,
                ),
                label: Text(
                  _questaoAtual >= _questoesPorFase &&
                          widget.fases.indexOf(_faseAtual) >=
                              widget.fases.length - 1
                      ? 'Concluir Trilha'
                      : 'Próxima Questão',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpcao(int idx, Questao q) {
    Color borderColor = const Color(0xFFE0E0E0);
    Color bgColor = Colors.white;

    if (_respondida) {
      if (idx == q.respostaCorreta) {
        borderColor = Colors.green;
        bgColor = Colors.green.shade50;
      } else if (idx == _respostaSelecionada) {
        borderColor = Colors.red;
        bgColor = Colors.red.shade50;
      }
    } else if (idx == _respostaSelecionada) {
      borderColor = const Color(0xFF667EEA);
      bgColor = const Color(0xFFEEF0FF);
    }

    return GestureDetector(
      onTap: _respondida ? null : () => _responder(idx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: borderColor,
              child: Text(String.fromCharCode(65 + idx),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(q.opcoes[idx], style: const TextStyle(fontSize: 15))),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _acertou! ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
            color: _acertou! ? Colors.green : Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _acertou! ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: _acertou! ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _acertou!
                  ? 'Resposta correta! +10 XP'
                  : 'Resposta incorreta. Certa: ${_questao!.opcoes[_questao!.respostaCorreta]}',
              style: TextStyle(
                  color: _acertou! ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
