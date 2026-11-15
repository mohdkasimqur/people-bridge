import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jober_india/main.dart';

void main() {
  // Importing main.dart makes the test compile every screen the app reaches,
  // so this fails if any of them stops compiling. It does not start the app.
  test('the whole app compiles and MyApp can be constructed', () {
    const app = MyApp(
      hasSeenWelcome: false,
      isLoggedIn: false,
      languageCode: 'en',
    );

    expect(app, isA<Widget>());
    expect(app.languageCode, 'en');
  });
}
