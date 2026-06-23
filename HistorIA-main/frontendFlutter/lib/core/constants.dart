import 'package:flutter/foundation.dart';

class Api {
  // Seleciona automaticamente o host certo por plataforma:
  //   • Android emulator → 10.0.2.2 (aponta para localhost da máquina host)
  //   • Windows / Web / Linux / macOS → localhost
  //   • Dispositivo físico Android → defina manualmente abaixo
  static String get _base {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2';
    }
    return 'http://localhost';
  }

  static String get auth => '$_base/auth';
  static String get alunos => '$_base/alunos';
  static String get trilhas => '$_base/trilhas';
  static String get exercicios => '$_base/exercicios';
}
