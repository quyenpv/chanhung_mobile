import 'package:chanhung/core/utils/app_design.dart';
import 'package:chanhung/core/utils/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chanhung/view/components/animation/template_entrance.dart';

void main() {
  group('Fitness design system', () {
    test('uses shared spacing, radius, and background tokens', () {
      expect(AppDesign.pagePadding, 16);
      expect(AppDesign.radiusMedium, inInclusiveRange(12, 16));
      expect(light.scaffoldBackgroundColor, AppDesign.canvas);
    });

    testWidgets('buttons are pill shaped with accessible touch targets',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: light,
          home: Scaffold(
            body: Row(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Primary')),
                OutlinedButton(onPressed: () {}, child: const Text('Filter')),
              ],
            ),
          ),
        ),
      );

      expect(light.elevatedButtonTheme.style?.shape?.resolve({}),
          isA<StadiumBorder>());
      expect(light.outlinedButtonTheme.style?.shape?.resolve({}),
          isA<StadiumBorder>());
      expect(tester.getSize(find.byType(ElevatedButton)).height,
          greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byType(OutlinedButton)).height,
          greaterThanOrEqualTo(48));
    });

    testWidgets('entrance motion respects reduced-motion preference',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: TemplateEntrance(child: Text('Ready')),
          ),
        ),
      );

      final entrance = find.byType(TemplateEntrance);
      final fade = tester.widget<FadeTransition>(
        find.descendant(of: entrance, matching: find.byType(FadeTransition)),
      );
      final slide = tester.widget<SlideTransition>(
        find.descendant(of: entrance, matching: find.byType(SlideTransition)),
      );
      expect(fade.opacity.value, 1);
      expect(slide.position.value, Offset.zero);
      expect(find.text('Ready'), findsOneWidget);
    });
  });
}
