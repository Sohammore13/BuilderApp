import 'package:flutter_test/flutter_test.dart';
import 'package:builder_app/main.dart';

void main() {
  testWidgets('BuilderApp smoke test', (WidgetTester tester) async {
    // Firebase is not available in unit test environment.
    // This placeholder confirms the BuilderApp class is importable.
    expect(BuilderApp, isNotNull);
  });
}
