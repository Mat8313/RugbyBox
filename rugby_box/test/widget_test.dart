import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/app/rugby_box_app.dart';
import 'package:rugby_box/core/config/app_config.dart';

void main() {
  testWidgets("L'app démarre et affiche l'écran d'accueil", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(useMockData: true),
          ),
        ],
        child: const RugbyBoxApp(),
      ),
    );

    expect(find.text('Hello RCT'), findsOneWidget);
    expect(find.text('Données fictives'), findsOneWidget);
  });
}
