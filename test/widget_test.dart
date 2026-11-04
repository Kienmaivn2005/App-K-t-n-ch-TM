import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/main.dart';

void main() {
  testWidgets('UniPlan AI smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const UniPlanApp());
    await tester.pump();

    // Verify app starts cleanly
    expect(find.byType(UniPlanApp), findsOneWidget);
  });
}
