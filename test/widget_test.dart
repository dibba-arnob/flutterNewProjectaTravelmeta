import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:travelmeta_v1/main.dart';
import 'package:travelmeta_v1/screens/splash_screen.dart';

void main() {
  setUpAll(() {
    // Prevent google_fonts from making network requests during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('TravelMetaApp starts on SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const TravelMetaApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance past the 3.2 s navigation timer so no pending timers remain.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen shows app name and tagline', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();
    // Let the content fade-in animation progress.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('TravelMeta'), findsOneWidget);
    expect(find.text('Beyond Boundaries'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen shows loading text after 600 ms delay', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();
    // Loading section fades in after 600 ms — advance just past that.
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('INITIALIZING EXPERIENCE'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
