import 'package:flutter_test/flutter_test.dart';

import 'package:gastro_costos/main.dart';

void main() {
  testWidgets('Shows main module navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const GastroCostosApp());

    expect(find.text('GastroCostos'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Ingredientes'), findsOneWidget);
    expect(find.text('Recetas'), findsOneWidget);
  });
}
