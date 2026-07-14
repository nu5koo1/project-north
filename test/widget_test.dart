import 'package:flutter_test/flutter_test.dart';
import 'package:project_north/app/app.dart';

void main() {
  testWidgets('Project North title is displayed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProjectNorthApp());

    expect(find.text('Project North'), findsOneWidget);
  });
}