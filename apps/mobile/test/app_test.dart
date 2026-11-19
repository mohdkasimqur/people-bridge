import 'package:app_core/app_core.dart';
import 'package:app_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts and shows the working name', (tester) async {
    await tester.pumpWidget(
      App(localeController: LocaleController(InMemoryLocaleStore())),
    );
    expect(find.text('People Bridge'), findsOneWidget);
  });
}
