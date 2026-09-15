import 'package:erea/ui/onboarding_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la démo du geste boucle sans erreur de dessin',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SizedBox(width: 300, height: 190, child: DemoFrise())),
    ));
    // Un cycle complet et un peu plus : toutes les phases, fondu et
    // redémarrage compris, doivent se peindre sans lever d'exception.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.takeException(), isNull);
    expect(find.byType(DemoFrise), findsOneWidget);
  });
}
