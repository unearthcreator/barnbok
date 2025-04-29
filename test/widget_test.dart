import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barnbok/core/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the initial welcome text appears.
    expect(find.text('Welcome to your Flutter app!'), findsOneWidget);
  });
}