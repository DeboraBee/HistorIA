class Questao {
  final String pergunta;
  final List<String> opcoes;
  final int respostaCorreta;

  const Questao({
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorreta,
  });

  factory Questao.fromJson(Map<String, dynamic> j) => Questao(
        pergunta: j['pergunta'] as String,
        opcoes: List<String>.from(j['opcoes'] as List),
        respostaCorreta: j['resposta_correta'] as int,
      );
}

class HistoricoItem {
  final String pergunta;
  final bool acertou;

  const HistoricoItem({required this.pergunta, required this.acertou});

  factory HistoricoItem.fromJson(Map<String, dynamic> j) => HistoricoItem(
        pergunta: j['pergunta'] as String,
        acertou: j['acertou'] as bool,
      );
}
