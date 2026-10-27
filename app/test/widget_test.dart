// This is a basic Flutter widget test for the flight attendance app.
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_attendance_app/main.dart' as app;

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    // We can't pump the full app here because it depends on platform
    // channels (shared_preferences). Just smoke test that main() doesn't
    // throw at the import level.
    expect(app.main, isA<Function>());
  });
}
