import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/main.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MentalCapacityAssessmentApp());

    // Verify that the splash screen text is present (or whatever initial UI is shown)
    // Note: Since we have a Splash Screen with "MindCare", we check for it.
    // We expect "MindCare" to be present as it's the app title.
    expect(find.text('MindCare'), findsOneWidget);
  });
}
