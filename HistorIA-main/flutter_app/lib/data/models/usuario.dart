class Usuario {
  final int id;
  final String nome;
  final String email;
  final String tipo; // 'aluno' | 'professor'
  final int xp;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.xp = 0,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] as int,
        nome: j['nome'] as String,
        email: j['email'] as String,
        tipo: j['tipo'] as String? ?? 'aluno',
        xp: j['xp'] as int? ?? 0,
      );

  Usuario copyWith({int? xp}) => Usuario(
        id: id,
        nome: nome,
        email: email,
        tipo: tipo,
        xp: xp ?? this.xp,
      );
}
