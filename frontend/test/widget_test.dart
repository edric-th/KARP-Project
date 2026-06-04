import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MeroPaloApp());
    expect(find.text('Mero Palo'), findsAny);
  });
}
