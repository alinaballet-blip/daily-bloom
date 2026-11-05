import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_bloom/main.dart';

void main() {
  testWidgets('Daily Bloom app renders', (WidgetTester tester) async {
    await tester.pumpWidget(DailyBloomApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}