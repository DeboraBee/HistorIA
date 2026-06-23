class Trilha {
  final int id;
  final String nome;
  final int professorId;

  const Trilha({required this.id, required this.nome, required this.professorId});

  factory Trilha.fromJson(Map<String, dynamic> j) => Trilha(
        id: j['id'] as int,
        nome: j['nome'] as String,
        professorId: j['professor_id'] as int? ?? 0,
      );
}

class Fase {
  final int id;
  final String nome;
  final int ordem;

  const Fase({required this.id, required this.nome, required this.ordem});

  factory Fase.fromJson(Map<String, dynamic> j) => Fase(
        id: j['id'] as int,
        nome: j['nome'] as String,
        ordem: j['ordem'] as int? ?? 1,
      );
}
