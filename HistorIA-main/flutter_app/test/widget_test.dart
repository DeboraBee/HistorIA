import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:historia_app/main.dart';
import 'package:historia_app/providers/auth_provider.dart';

void main() {
  testWidgets('Exibe tela de login quando não há sessão ativa',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const HistorIAApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('📚 HistorIA'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
