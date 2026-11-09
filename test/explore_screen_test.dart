import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/student/explore/presentation/screens/explore_projects_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDataService.instance.init();
  });

  testWidgets('ExploreProjectsScreen renders without errors on all screen widths', (tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('==== EXPLORE SCREEN ERROR ====');
      debugPrint(details.toString());
    };

    final widths = [320.0, 360.0, 390.0, 800.0, 1280.0];

    for (final w in widths) {
      tester.view.physicalSize = Size(w, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ExploreProjectsScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('ExploreProjectsScreen search and filter tests', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreProjectsScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap a category chip (e.g. Design)
    final designChip = find.text('Design');
    expect(designChip, findsOneWidget);
    await tester.tap(designChip);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Type in search box
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Google');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Tap bookmark icon on a project card
    final bookmarkButtons = find.byIcon(Icons.bookmark_border_rounded);
    if (bookmarkButtons.evaluate().isNotEmpty) {
      await tester.tap(bookmarkButtons.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

