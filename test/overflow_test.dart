import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_vibe/feature/splash/presentation/screens/splash_screen.dart';
import 'package:link_vibe/feature/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/signup_screen.dart';

void main() {
  final testSizes = [
    const Size(320, 568), // iPhone SE 1st gen (small)
    const Size(360, 640), // Standard Android
    const Size(375, 667), // iPhone 8
    const Size(390, 844), // iPhone 12/13/14
    const Size(412, 915), // Pixel 7
    const Size(800, 600), // Small desktop window
    const Size(1280, 800), // Web standard
  ];

  for (final size in testSizes) {
    testWidgets('SplashScreen on ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('OnboardingScreen on ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      final nextButton = find.byType(ElevatedButton);
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('LoginScreen on ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SignupScreen on ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }
}
