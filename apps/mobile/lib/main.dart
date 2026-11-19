import 'package:app_core/app_core.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(App(localeController: LocaleController(InMemoryLocaleStore())));
}

class App extends StatelessWidget {
  const App({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) => MaterialApp(
        title: 'People Bridge',
        locale: locale,
        home: const Scaffold(body: Center(child: Text('People Bridge'))),
      ),
    );
  }
}
