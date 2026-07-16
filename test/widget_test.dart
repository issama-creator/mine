import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Mine Rush boots', (tester) async {
    await tester.pumpWidget(const MineRushApp());
    expect(find.byType(MineGameScreen), findsOneWidget);
  });
}
