import 'package:cormex_easy/app.dart';
import 'package:cormex_easy/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('abre a home pública sem exigir login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();

    await tester.pumpWidget(const CormexEasyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('O serviço certo, perto de você.'), findsOneWidget);
    expect(find.text('Anunciar meu serviço'), findsWidgets);
  });
}
