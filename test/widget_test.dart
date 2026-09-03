import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:galacticgame/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GalacticMergeApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: GalacticMergeApp(),
      ),
    );

    expect(find.byType(GalacticMergeApp), findsOneWidget);

    // Advance splash screen loading timer
    await tester.pump(const Duration(seconds: 3));
  });
}

