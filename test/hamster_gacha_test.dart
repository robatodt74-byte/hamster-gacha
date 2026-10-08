import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamster/main.dart';
import 'package:hamster/hamster_data.dart';

Future<void> mount(
  WidgetTester tester, {
  double width = 375,
  bool reduced = false,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 1100),
          disableAnimations: reduced,
        ),
        child: HamsterGacha(random: Random(42)),
      ),
    ),
  );
}

Future<void> press(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump();
}

void main() {
  test('rarity probabilities cover exactly 10 UR, 30 SR and 60 R outcomes', () {
    final counts = [0, 0, 0];
    for (var i = 0; i < 100; i++) {
      counts[rollRarity(i)]++;
    }
    expect(counts, [60, 30, 10]);
    expect(() => rollRarity(-1), throwsRangeError);
    expect(() => rollRarity(100), throwsRangeError);
    expect(hamsterPhotos.length, 53);
    expect(hamsterPhotos.toSet().length, 53);
  });
  testWidgets('charge, reach, push, reveal commits once and can replay', (
    tester,
  ) async {
    await mount(tester, width: 1280);
    await press(tester, const Key('spin-button'));
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('spin-button')))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('ほっぺが…ざわついている！'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('PUSH !  もふっと解放'), findsOneWidget);
    await press(tester, const Key('spin-button'));
    expect(find.text('1 回まわしました'), findsOneWidget);
    await press(tester, const Key('skip-button'));
    expect(find.text('もう一回、もふる！'), findsOneWidget);
    expect(find.text('図鑑 1/53 →'), findsOneWidget);
    expect(find.text('1 回まわしました'), findsOneWidget);
    await press(tester, const Key('spin-button'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
  testWidgets('early skip retains preselected draw and opens album', (
    tester,
  ) async {
    await mount(tester, width: 1280, reduced: true);
    final expected = GachaResult.draw(Random(42));
    await press(tester, const Key('spin-button'));
    await press(tester, const Key('skip-button'));
    expect(find.text('${expected.name} がやってきた！'), findsWidgets);
    expect(find.text('1 回まわしました'), findsOneWidget);
    expect(find.byKey(const Key('skip-button')), findsNothing);
    await tester.ensureVisible(find.text('図鑑 1/53 →'));
    await tester.tap(find.text('図鑑 1/53 →'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('もふもふ図鑑  1/53'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [320.0, 375.0, 768.0, 1280.0]) {
    testWidgets('ready and result layout fit width $width', (tester) async {
      await mount(tester, width: width);
      expect(tester.takeException(), isNull);
      await press(tester, const Key('spin-button'));
      await press(tester, const Key('skip-button'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
