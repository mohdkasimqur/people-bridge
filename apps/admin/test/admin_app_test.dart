import 'package:app_admin/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin app starts and shows its title', (tester) async {
    await tester.pumpWidget(const AdminApp());
    expect(find.text('People Bridge Admin'), findsOneWidget);
  });
}
