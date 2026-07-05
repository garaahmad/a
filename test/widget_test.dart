import 'package:flutter_test/flutter_test.dart';

import 'package:palestine_real_estate/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RealEstateApp());
  });
}
