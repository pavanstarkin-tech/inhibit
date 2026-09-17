import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/services/app_state.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('Inhibit app boots and renders initial UI', (WidgetTester tester) async {
    final appState = AppState();
    // Test initial shell rendering
    await tester.pumpWidget(InhibitApp(appState: appState));
    expect(find.byType(InhibitApp), findsOneWidget);
  });
}
