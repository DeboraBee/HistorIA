class Api {
  // No emulador Android, 10.0.2.2 aponta para o localhost da máquina host.
  // Em dispositivo físico na mesma rede, troque pelo IP local (ex: 192.168.0.10).
  static const String _base = 'http://10.0.2.2';

  static const String auth = '$_base/auth';
  static const String alunos = '$_base/alunos';
  static const String trilhas = '$_base/trilhas';
  static const String exercicios = '$_base/exercicios';
}
