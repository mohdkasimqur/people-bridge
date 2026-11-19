import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'People Bridge Admin',
      home: Scaffold(body: Center(child: Text('People Bridge Admin'))),
    );
  }
}
