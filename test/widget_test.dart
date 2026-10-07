import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mate/app.dart';

void main() {
  testWidgets('POS Mate login screen is displayed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PosMateApp());

    expect(find.text('POS Mate'), findsOneWidget);

    expect(find.text('아이디'), findsOneWidget);

    expect(find.text('비밀번호'), findsOneWidget);

    expect(find.text('로그인'), findsOneWidget);
  });
}
