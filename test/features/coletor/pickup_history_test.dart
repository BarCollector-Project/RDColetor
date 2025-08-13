import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdcoletor/features/coletor/view/pickup_history_screen.dart';

void main() {
  group('PickupHistoryScreen', () {
    testWidgets('deve renderizar a tela e carregar o histórico de coletas', (WidgetTester tester) async {
      // Constrói a tela. Como _updateRegisters é chamado no initState e
      // contém um setState, precisamos usar pumpWidget e depois pumpAndSettle()
      // para garantir que a UI seja reconstruída com os dados.
      await tester.pumpWidget(const MaterialApp(home: PickupHistoryScreen()));

      // Aguarda a conclusão do Future em _updateRegisters e a reconstrução do widget.
      await tester.pumpAndSettle();

      // Verifica se o título do AppBar está presente
      expect(find.text('Histórico de Coletas'), findsOneWidget);

      // Verifica se o texto introdutório está presente
      expect(find.text('Ultimos registros de coleta.'), findsOneWidget);

      // Verifica se a ListView está presente
      expect(find.byType(ListView), findsOneWidget);

      // Verifica se o item da coleta (carregado do _updateRegisters) foi renderizado
      expect(find.text('Produto 1'), findsOneWidget);
      expect(find.textContaining('Código: 123456789'), findsOneWidget);
      expect(find.textContaining('Quantidade: 10'), findsOneWidget);
    });
  });
}
