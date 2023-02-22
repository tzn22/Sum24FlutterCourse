// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Brightness, DisplayFeature, DisplayFeatureState, DisplayFeatureType, GestureSettings, PlatformDispatcher, ViewConfiguration, ViewPadding;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MediaQueryAspectCase {
  const _MediaQueryAspectCase(this.method, this.data);
  final Function(BuildContext) method;
  final MediaQueryData data;
}

class _MediaQueryAspectVariant extends TestVariant<_MediaQueryAspectCase> {
  _MediaQueryAspectVariant({
    required this.values
  });

  @override
  final List<_MediaQueryAspectCase> values;

  static _MediaQueryAspectCase? aspect;

  @override
  String describeValue(_MediaQueryAspectCase value) {
    return value.method.toString();
  }

  @override
  Future<_MediaQueryAspectCase?> setUp(_MediaQueryAspectCase value) async {
    final _MediaQueryAspectCase? oldAspect = aspect;
    aspect = value;
    return oldAspect;
  }

  @override
  Future<void> tearDown(_MediaQueryAspectCase value, _MediaQueryAspectCase? memento) async {
    aspect = memento;
  }
}

void main() {
  testWidgets('MediaQuery does not have a default', (WidgetTester tester) async {
    bool tested = false;
    // Cannot use tester.pumpWidget here because it wraps the widget in a View,
    // which introduces a MediaQuery ancestor.
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          tested = true;
          MediaQuery.of(context); // should throw
          return Container();
        },
      ),
    );
    expect(tested, isTrue);
    final dynamic exception = tester.takeException();
    expect(exception, isNotNull);
    expect(exception ,isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics.last, isA<ErrorHint>());
    expect(
      error.toStringDeep(),
      startsWith(
        'FlutterError\n'
        '   No MediaQuery widget ancestor found.\n'
        '   Builder widgets require a MediaQuery widget ancestor.\n'
        '   The specific widget that could not find a MediaQuery ancestor\n'
        '   was:\n'
        '     Builder\n'
        '   The ownership chain for the affected widget is: "Builder ←', // Full ownership chain omitted, not relevant for test.
      ),
    );
    expect(
      error.toStringDeep(),
      endsWith(
        '[root]"\n' // End of ownership chain.
        '   No MediaQuery ancestor could be found starting from the context\n'
        '   that was passed to MediaQuery.of(). This can happen because you\n'
        '   have not added a WidgetsApp, CupertinoApp, or MaterialApp widget\n'
        '   (those widgets introduce a MediaQuery), or it can happen if the\n'
        '   context you use comes from a widget above those widgets.\n',
      ),
    );
  });

  testWidgets('MediaQuery.of finds a MediaQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final MediaQueryData data = MediaQuery.of(context);
            expect(data, isNotNull);
            tested = true;
            return Container();
          },
        ),
      ),
    );
    final dynamic exception = tester.takeException();
    expect(exception, isNull);
    expect(tested, isTrue);
  });

  testWidgets('MediaQuery.maybeOf defaults to null', (WidgetTester tester) async {
    bool tested = false;
    // Cannot use tester.pumpWidget here because it wraps the widget in a View,
    // which introduces a MediaQuery ancestor.
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          final MediaQueryData? data = MediaQuery.maybeOf(context);
          expect(data, isNull);
          tested = true;
          return Container();
        },
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('MediaQuery.maybeOf finds a MediaQueryData when there is one', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            final MediaQueryData? data = MediaQuery.maybeOf(context);
            expect(data, isNotNull);
            tested = true;
            return Container();
          },
        ),
      ),
    );
    expect(tested, isTrue);
  });

  testWidgets('MediaQueryData.fromView is sane', (WidgetTester tester) async {
    final MediaQueryData data = MediaQueryData.fromView(tester.binding.window);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, equals(data.copyWith().hashCode));
    expect(data.size, equals(tester.binding.window.physicalSize / tester.binding.window.devicePixelRatio));
    expect(data.accessibleNavigation, false);
    expect(data.invertColors, false);
    expect(data.disableAnimations, false);
    expect(data.boldText, false);
    expect(data.highContrast, false);
    expect(data.platformBrightness, Brightness.light);
    expect(data.gestureSettings.touchSlop, null);
    expect(data.displayFeatures, isEmpty);
  });

  testWidgets('MediaQueryData.fromView uses platformData if provided', (WidgetTester tester) async {
    const MediaQueryData platformData = MediaQueryData(
      textScaleFactor: 1234,
      platformBrightness: Brightness.dark,
      accessibleNavigation: true,
      invertColors: true,
      disableAnimations: true,
      boldText: true,
      highContrast: true,
      alwaysUse24HourFormat: true,
      navigationMode: NavigationMode.directional,
    );

    final TestView view = TestView(
      physicalSize: const Size(300, 600),
      devicePixelRatio: 3.0,
      padding: const TestViewPadding(15),
      viewPadding: const TestViewPadding(75),
      viewInsets: const TestViewPadding(45),
      systemGestureInsets: const TestViewPadding(9),
    );

    final MediaQueryData data = MediaQueryData.fromView(view, platformData: platformData);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, data.copyWith().hashCode);
    expect(data.size, view.physicalSize / view.devicePixelRatio);
    expect(data.devicePixelRatio, view.devicePixelRatio);
    expect(data.textScaleFactor, platformData.textScaleFactor);
    expect(data.platformBrightness, platformData.platformBrightness);
    expect(data.padding, EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio));
    expect(data.viewPadding, EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio));
    expect(data.viewInsets, EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio));
    expect(data.systemGestureInsets, EdgeInsets.fromViewPadding(view.systemGestureInsets, view.devicePixelRatio));
    expect(data.accessibleNavigation, platformData.accessibleNavigation);
    expect(data.invertColors, platformData.invertColors);
    expect(data.disableAnimations, platformData.disableAnimations);
    expect(data.boldText, platformData.boldText);
    expect(data.highContrast, platformData.highContrast);
    expect(data.alwaysUse24HourFormat, platformData.alwaysUse24HourFormat);
    expect(data.navigationMode, platformData.navigationMode);
    expect(data.gestureSettings, DeviceGestureSettings.fromView(view));
    expect(data.displayFeatures, view.displayFeatures);
  });

  testWidgets('MediaQueryData.fromView uses data from platformDispatcher if no platformData is provided', (WidgetTester tester) async {
    final TestPlatformDispatcher platformDispatcher = TestPlatformDispatcher(platformDispatcher: tester.binding.platformDispatcher);
    platformDispatcher
      ..textScaleFactorTestValue = 123
      ..platformBrightnessTestValue = Brightness.dark
      ..accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;
    addTearDown(() => platformDispatcher.clearAllTestValues());

    final TestView view = TestView(
      platformDispatcher: platformDispatcher,
      physicalSize: const Size(300, 600),
      devicePixelRatio: 3.0,
      padding: const TestViewPadding(15),
      viewPadding: const TestViewPadding(75),
      viewInsets: const TestViewPadding(45),
      systemGestureInsets: const TestViewPadding(9),
    );

    final MediaQueryData data = MediaQueryData.fromView(view);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, data.copyWith().hashCode);
    expect(data.size, view.physicalSize / view.devicePixelRatio);
    expect(data.devicePixelRatio, view.devicePixelRatio);
    expect(data.textScaleFactor, platformDispatcher.textScaleFactor);
    expect(data.platformBrightness, platformDispatcher.platformBrightness);
    expect(data.padding, EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio));
    expect(data.viewPadding, EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio));
    expect(data.viewInsets, EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio));
    expect(data.systemGestureInsets, EdgeInsets.fromViewPadding(view.systemGestureInsets, view.devicePixelRatio));
    expect(data.accessibleNavigation, platformDispatcher.accessibilityFeatures.accessibleNavigation);
    expect(data.invertColors, platformDispatcher.accessibilityFeatures.invertColors);
    expect(data.disableAnimations, platformDispatcher.accessibilityFeatures.disableAnimations);
    expect(data.boldText, platformDispatcher.accessibilityFeatures.boldText);
    expect(data.highContrast, platformDispatcher.accessibilityFeatures.highContrast);
    expect(data.alwaysUse24HourFormat, platformDispatcher.alwaysUse24HourFormat);
    expect(data.navigationMode, NavigationMode.traditional);
    expect(data.gestureSettings, DeviceGestureSettings.fromView(view));
    expect(data.displayFeatures, view.displayFeatures);
  });

  testWidgets('MediaQuery.fromView injects a new MediaQuery with data from view, preserving platform-specific data', (WidgetTester tester) async {
    const MediaQueryData platformData = MediaQueryData(
      textScaleFactor: 1234,
      platformBrightness: Brightness.dark,
      accessibleNavigation: true,
      invertColors: true,
      disableAnimations: true,
      boldText: true,
      highContrast: true,
      alwaysUse24HourFormat: true,
      navigationMode: NavigationMode.directional,
    );

    final TestView view = TestView(
      physicalSize: const Size(300, 600),
      devicePixelRatio: 3.0,
      padding: const TestViewPadding(15),
      viewPadding: const TestViewPadding(75),
      viewInsets: const TestViewPadding(45),
      systemGestureInsets: const TestViewPadding(9),
    );

    late MediaQueryData data;
    await tester.pumpWidget(MediaQuery(
      data: platformData,
      child: MediaQuery.fromView(
        view: view,
        child: Builder(
          builder: (BuildContext context) {
            data = MediaQuery.of(context);
            return const Placeholder();
          },
        )
      )
    ));

    expect(data, isNot(platformData));
    expect(data.size, view.physicalSize / view.devicePixelRatio);
    expect(data.devicePixelRatio, view.devicePixelRatio);
    expect(data.textScaleFactor, platformData.textScaleFactor);
    expect(data.platformBrightness, platformData.platformBrightness);
    expect(data.padding, EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio));
    expect(data.viewPadding, EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio));
    expect(data.viewInsets, EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio));
    expect(data.systemGestureInsets, EdgeInsets.fromViewPadding(view.systemGestureInsets, view.devicePixelRatio));
    expect(data.accessibleNavigation, platformData.accessibleNavigation);
    expect(data.invertColors, platformData.invertColors);
    expect(data.disableAnimations, platformData.disableAnimations);
    expect(data.boldText, platformData.boldText);
    expect(data.highContrast, platformData.highContrast);
    expect(data.alwaysUse24HourFormat, platformData.alwaysUse24HourFormat);
    expect(data.navigationMode, platformData.navigationMode);
    expect(data.gestureSettings, DeviceGestureSettings.fromView(view));
    expect(data.displayFeatures, view.displayFeatures);
  });

  testWidgets('MediaQuery.fromView injects a new MediaQuery with data from view when no sourrounding MediaQuery exists', (WidgetTester tester) async {
    final TestPlatformDispatcher platformDispatcher = TestPlatformDispatcher(platformDispatcher: tester.binding.platformDispatcher);
    platformDispatcher
      ..textScaleFactorTestValue = 123
      ..platformBrightnessTestValue = Brightness.dark
      ..accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;
    addTearDown(() => platformDispatcher.clearAllTestValues());

    final TestView view = TestView(
      platformDispatcher: platformDispatcher,
      physicalSize: const Size(300, 600),
      devicePixelRatio: 3.0,
      padding: const TestViewPadding(15),
      viewPadding: const TestViewPadding(75),
      viewInsets: const TestViewPadding(45),
      systemGestureInsets: const TestViewPadding(9),
    );

    late MediaQueryData data;
    MediaQueryData? outerData;
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          outerData = MediaQuery.maybeOf(context);
          return MediaQuery.fromView(
              view: view,
              child: Builder(
                builder: (BuildContext context) {
                  data = MediaQuery.of(context);
                  return const Placeholder();
                },
              )
          );
        },
      ),
    );

    expect(outerData, isNull);
    expect(data.size, view.physicalSize / view.devicePixelRatio);
    expect(data.devicePixelRatio, view.devicePixelRatio);
    expect(data.textScaleFactor, platformDispatcher.textScaleFactor);
    expect(data.platformBrightness, platformDispatcher.platformBrightness);
    expect(data.padding, EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio));
    expect(data.viewPadding, EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio));
    expect(data.viewInsets, EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio));
    expect(data.systemGestureInsets, EdgeInsets.fromViewPadding(view.systemGestureInsets, view.devicePixelRatio));
    expect(data.accessibleNavigation, platformDispatcher.accessibilityFeatures.accessibleNavigation);
    expect(data.invertColors, platformDispatcher.accessibilityFeatures.invertColors);
    expect(data.disableAnimations, platformDispatcher.accessibilityFeatures.disableAnimations);
    expect(data.boldText, platformDispatcher.accessibilityFeatures.boldText);
    expect(data.highContrast, platformDispatcher.accessibilityFeatures.highContrast);
    expect(data.alwaysUse24HourFormat, platformDispatcher.alwaysUse24HourFormat);
    expect(data.navigationMode, NavigationMode.traditional);
    expect(data.gestureSettings, DeviceGestureSettings.fromView(view));
    expect(data.displayFeatures, view.displayFeatures);
  });

  testWidgets('MediaQuery.fromView updates on notifications (no parent data)', (WidgetTester tester) async {
    tester.binding.platformDispatcher
      ..textScaleFactorTestValue = 123
      ..platformBrightnessTestValue = Brightness.dark
      ..accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;
    addTearDown(() => tester.binding.platformDispatcher.clearAllTestValues());
    tester.binding.window.devicePixelRatioTestValue = 44;
    addTearDown(() => tester.binding.window.clearAllTestValues());

    late MediaQueryData data;
    MediaQueryData? outerData;
    int rebuildCount = 0;
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          outerData = MediaQuery.maybeOf(context);
          return MediaQuery.fromView(
              view: tester.binding.window,
              child: Builder(
                builder: (BuildContext context) {
                  rebuildCount++;
                  data = MediaQuery.of(context);
                  return const Placeholder();
                },
              ),
          );
        },
      ),
    );

    expect(outerData, isNull);
    expect(rebuildCount, 1);

    expect(data.textScaleFactor, 123);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 456;
    await tester.pump();
    expect(data.textScaleFactor, 456);
    expect(rebuildCount, 2);

    expect(data.platformBrightness, Brightness.dark);
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(data.platformBrightness, Brightness.light);
    expect(rebuildCount, 3);

    expect(data.accessibleNavigation, true);
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    await tester.pump();
    expect(data.accessibleNavigation, false);
    expect(rebuildCount, 4);

    expect(data.devicePixelRatio, 44);
    tester.binding.window.devicePixelRatioTestValue = 55;
    await tester.pump();
    expect(data.devicePixelRatio, 55);
    expect(rebuildCount, 5);
  });

  testWidgets('MediaQuery.fromView updates on notifications (with parent data)', (WidgetTester tester) async {
    tester.binding.platformDispatcher
      ..textScaleFactorTestValue = 123
      ..platformBrightnessTestValue = Brightness.dark
      ..accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;
    addTearDown(() => tester.binding.platformDispatcher.clearAllTestValues());
    tester.binding.window.devicePixelRatioTestValue = 44;
    addTearDown(() => tester.binding.window.clearAllTestValues());

    late MediaQueryData data;
    int rebuildCount = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaleFactor: 44,
          platformBrightness: Brightness.dark,
          accessibleNavigation: true,
        ),
        child: MediaQuery.fromView(
          view: tester.binding.window,
          child: Builder(
            builder: (BuildContext context) {
              rebuildCount++;
              data = MediaQuery.of(context);
              return const Placeholder();
            },
          ),
        ),
      ),
    );

    expect(rebuildCount, 1);

    expect(data.textScaleFactor, 44);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 456;
    await tester.pump();
    expect(data.textScaleFactor, 44);
    expect(rebuildCount, 1);

    expect(data.platformBrightness, Brightness.dark);
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(data.platformBrightness, Brightness.dark);
    expect(rebuildCount, 1);

    expect(data.accessibleNavigation, true);
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    await tester.pump();
    expect(data.accessibleNavigation, true);
    expect(rebuildCount, 1);

    expect(data.devicePixelRatio, 44);
    tester.binding.window.devicePixelRatioTestValue = 55;
    await tester.pump();
    expect(data.devicePixelRatio, 55);
    expect(rebuildCount, 2);
  });

  testWidgets('MediaQuery.fromView updates when parent data changes', (WidgetTester tester) async {
    late MediaQueryData data;
    int rebuildCount = 0;
    double textScaleFactor = 55;
    late StateSetter stateSetter;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          stateSetter = setState;
          return MediaQuery(
            data: MediaQueryData(textScaleFactor: textScaleFactor),
            child: MediaQuery.fromView(
              view: tester.binding.window,
              child: Builder(
                builder: (BuildContext context) {
                  rebuildCount++;
                  data = MediaQuery.of(context);
                  return const Placeholder();
                },
              ),
            ),
          );
        },
      ),
    );

    expect(rebuildCount, 1);
    expect(data.textScaleFactor, 55);

    stateSetter(() {
      textScaleFactor = 66;
    });
    await tester.pump();
    expect(data.textScaleFactor, 66);
    expect(rebuildCount, 2);
  });

  testWidgets('MediaQueryData.copyWith defaults to source', (WidgetTester tester) async {
    final MediaQueryData data = MediaQueryData.fromView(tester.binding.window);
    final MediaQueryData copied = data.copyWith();
    expect(copied.size, data.size);
    expect(copied.devicePixelRatio, data.devicePixelRatio);
    expect(copied.textScaleFactor, data.textScaleFactor);
    expect(copied.padding, data.padding);
    expect(copied.viewPadding, data.viewPadding);
    expect(copied.viewInsets, data.viewInsets);
    expect(copied.systemGestureInsets, data.systemGestureInsets);
    expect(copied.alwaysUse24HourFormat, data.alwaysUse24HourFormat);
    expect(copied.accessibleNavigation, data.accessibleNavigation);
    expect(copied.invertColors, data.invertColors);
    expect(copied.disableAnimations, data.disableAnimations);
    expect(copied.boldText, data.boldText);
    expect(copied.highContrast, data.highContrast);
    expect(copied.platformBrightness, data.platformBrightness);
    expect(copied.gestureSettings, data.gestureSettings);
    expect(copied.displayFeatures, data.displayFeatures);
  });

  testWidgets('MediaQuery.copyWith copies specified values', (WidgetTester tester) async {
    // Random and unique double values are used to ensure that the correct
    // values are copied over exactly
    const Size customSize = Size(3.14, 2.72);
    const double customDevicePixelRatio = 1.41;
    const double customTextScaleFactor = 1.62;
    const EdgeInsets customPadding = EdgeInsets.all(9.10938);
    const EdgeInsets customViewPadding = EdgeInsets.all(11.24031);
    const EdgeInsets customViewInsets = EdgeInsets.all(1.67262);
    const EdgeInsets customSystemGestureInsets = EdgeInsets.all(1.5556);
    const DeviceGestureSettings gestureSettings = DeviceGestureSettings(touchSlop: 8.0);
    const List<DisplayFeature> customDisplayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    final MediaQueryData data = MediaQueryData.fromView(tester.binding.window);
    final MediaQueryData copied = data.copyWith(
      size: customSize,
      devicePixelRatio: customDevicePixelRatio,
      textScaleFactor: customTextScaleFactor,
      padding: customPadding,
      viewPadding: customViewPadding,
      viewInsets: customViewInsets,
      systemGestureInsets: customSystemGestureInsets,
      alwaysUse24HourFormat: true,
      accessibleNavigation: true,
      invertColors: true,
      disableAnimations: true,
      boldText: true,
      highContrast: true,
      platformBrightness: Brightness.dark,
      navigationMode: NavigationMode.directional,
      gestureSettings: gestureSettings,
      displayFeatures: customDisplayFeatures,
    );
    expect(copied.size, customSize);
    expect(copied.devicePixelRatio, customDevicePixelRatio);
    expect(copied.textScaleFactor, customTextScaleFactor);
    expect(copied.padding, customPadding);
    expect(copied.viewPadding, customViewPadding);
    expect(copied.viewInsets, customViewInsets);
    expect(copied.systemGestureInsets, customSystemGestureInsets);
    expect(copied.alwaysUse24HourFormat, true);
    expect(copied.accessibleNavigation, true);
    expect(copied.invertColors, true);
    expect(copied.disableAnimations, true);
    expect(copied.boldText, true);
    expect(copied.highContrast, true);
    expect(copied.platformBrightness, Brightness.dark);
    expect(copied.navigationMode, NavigationMode.directional);
    expect(copied.gestureSettings, gestureSettings);
    expect(copied.displayFeatures, customDisplayFeatures);
  });

  testWidgets('MediaQuery.removePadding removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, EdgeInsets.zero);
    expect(unpadded.viewPadding, viewInsets);
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removePadding only removes specified padding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding.copyWith(top: 0));
    expect(unpadded.viewPadding, viewPadding.copyWith(top: viewInsets.top));
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewInsets removes specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewInsets(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding);
    expect(unpadded.viewPadding, padding);
    expect(unpadded.viewInsets, EdgeInsets.zero);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewInsets removes only specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding);
    expect(unpadded.viewPadding, viewPadding.copyWith(bottom: 8));
    expect(unpadded.viewInsets, viewInsets.copyWith(bottom: 0));
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewPadding removes specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewPadding(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, EdgeInsets.zero);
    expect(unpadded.viewPadding, EdgeInsets.zero);
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.removeViewPadding removes only specified viewPadding', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.zero,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    late MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          navigationMode: NavigationMode.directional,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewPadding(
              context: context,
              removeLeft: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding.copyWith(left: 0));
    expect(unpadded.viewPadding, viewPadding.copyWith(left: 0));
    expect(unpadded.viewInsets, viewInsets);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
    expect(unpadded.highContrast, true);
    expect(unpadded.navigationMode, NavigationMode.directional);
    expect(unpadded.displayFeatures, displayFeatures);
  });

  testWidgets('MediaQuery.textScaleFactorOf', (WidgetTester tester) async {
    late double outsideTextScaleFactor;
    late double insideTextScaleFactor;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideTextScaleFactor = MediaQuery.textScaleFactorOf(context);
          return MediaQuery(
            data: const MediaQueryData(
              textScaleFactor: 4.0,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideTextScaleFactor = MediaQuery.textScaleFactorOf(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideTextScaleFactor, 1.0);
    expect(insideTextScaleFactor, 4.0);
  });

  testWidgets('MediaQuery.platformBrightnessOf', (WidgetTester tester) async {
    late Brightness outsideBrightness;
    late Brightness insideBrightness;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideBrightness = MediaQuery.platformBrightnessOf(context);
          return MediaQuery(
            data: const MediaQueryData(
              platformBrightness: Brightness.dark,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideBrightness = MediaQuery.platformBrightnessOf(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideBrightness, Brightness.light);
    expect(insideBrightness, Brightness.dark);
  });

  testWidgets('MediaQuery.highContrastOf', (WidgetTester tester) async {
    late bool outsideHighContrast;
    late bool insideHighContrast;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideHighContrast = MediaQuery.highContrastOf(context);
          return MediaQuery(
            data: const MediaQueryData(
              highContrast: true,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideHighContrast = MediaQuery.highContrastOf(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideHighContrast, false);
    expect(insideHighContrast, true);
  });

  testWidgets('MediaQuery.boldTextOf', (WidgetTester tester) async {
    late bool outsideBoldTextOverride;
    late bool insideBoldTextOverride;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideBoldTextOverride = MediaQuery.boldTextOf(context);
          return MediaQuery(
            data: const MediaQueryData(
              boldText: true,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideBoldTextOverride = MediaQuery.boldTextOf(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideBoldTextOverride, false);
    expect(insideBoldTextOverride, true);
  });

  testWidgets('MediaQuery.fromView creates a MediaQuery', (WidgetTester tester) async {
    MediaQuery? mediaQueryOutside;
    MediaQuery? mediaQueryInside;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          mediaQueryOutside = context.findAncestorWidgetOfExactType<MediaQuery>();
          return MediaQuery.fromView(
            view: View.of(context),
            child: Builder(
              builder: (BuildContext context) {
                mediaQueryInside = context.findAncestorWidgetOfExactType<MediaQuery>();
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );

    expect(mediaQueryInside, isNotNull);
    expect(mediaQueryOutside, isNot(mediaQueryInside));
  });

  testWidgets('MediaQueryData.fromWindow is created using window values', (WidgetTester tester) async {
    final MediaQueryData windowData = MediaQueryData.fromWindow(tester.binding.window);
    late MediaQueryData fromWindowData;

    await tester.pumpWidget(
      MediaQuery.fromWindow(
        child: Builder(
          builder: (BuildContext context) {
            fromWindowData = MediaQuery.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(windowData, equals(fromWindowData));
  });

  test('DeviceGestureSettings has reasonable hashCode', () {
    final DeviceGestureSettings settingsA = DeviceGestureSettings(touchSlop: nonconst(16));
    final DeviceGestureSettings settingsB = DeviceGestureSettings(touchSlop: nonconst(8));
    final DeviceGestureSettings settingsC = DeviceGestureSettings(touchSlop: nonconst(16));

    expect(settingsA.hashCode, settingsC.hashCode);
    expect(settingsA.hashCode, isNot(settingsB.hashCode));
  });

  test('DeviceGestureSettings has reasonable equality', () {
    final DeviceGestureSettings settingsA = DeviceGestureSettings(touchSlop: nonconst(16));
    final DeviceGestureSettings settingsB = DeviceGestureSettings(touchSlop: nonconst(8));
    final DeviceGestureSettings settingsC = DeviceGestureSettings(touchSlop: nonconst(16));

    expect(settingsA, equals(settingsC));
    expect(settingsA, isNot(settingsB));
  });

  testWidgets('MediaQuery.removeDisplayFeatures removes specified display features and padding', (WidgetTester tester) async {
    const Size size = Size(82.0, 40.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 10.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.fromLTRB(40, 0, 42, 40),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
      DisplayFeature(
        bounds: Rect.fromLTRB(70, 10, 74, 14),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ];

    // A section of the screen that intersects no display feature or padding area
    const Rect subScreen = Rect.fromLTRB(20, 10, 40, 20);

    late MediaQueryData subScreenMediaQuery;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).removeDisplayFeatures(subScreen),
              child: Builder(
                builder: (BuildContext context) {
                  subScreenMediaQuery = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(subScreenMediaQuery.size, size);
    expect(subScreenMediaQuery.devicePixelRatio, devicePixelRatio);
    expect(subScreenMediaQuery.textScaleFactor, textScaleFactor);
    expect(subScreenMediaQuery.padding, EdgeInsets.zero);
    expect(subScreenMediaQuery.viewPadding, EdgeInsets.zero);
    expect(subScreenMediaQuery.viewInsets, EdgeInsets.zero);
    expect(subScreenMediaQuery.alwaysUse24HourFormat, true);
    expect(subScreenMediaQuery.accessibleNavigation, true);
    expect(subScreenMediaQuery.invertColors, true);
    expect(subScreenMediaQuery.disableAnimations, true);
    expect(subScreenMediaQuery.boldText, true);
    expect(subScreenMediaQuery.highContrast, true);
    expect(subScreenMediaQuery.displayFeatures, isEmpty);
  });

  testWidgets('MediaQuery.removePadding only removes specified display features and padding', (WidgetTester tester) async {
    const Size size = Size(82.0, 40.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
    const EdgeInsets viewPadding = EdgeInsets.only(top: 6.0, right: 8.0, left: 46.0, bottom: 12.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const DisplayFeature cutoutDisplayFeature = DisplayFeature(
      bounds: Rect.fromLTRB(70, 10, 74, 14),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    );
    const List<DisplayFeature> displayFeatures = <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.fromLTRB(40, 0, 42, 40),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
      cutoutDisplayFeature,
    ];

    // A section of the screen that does contain display features and padding
    const Rect subScreen = Rect.fromLTRB(42, 0, 82, 40);

    late MediaQueryData subScreenMediaQuery;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
          highContrast: true,
          displayFeatures: displayFeatures,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).removeDisplayFeatures(subScreen),
              child: Builder(
                builder: (BuildContext context) {
                  subScreenMediaQuery = MediaQuery.of(context);
                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(subScreenMediaQuery.size, size);
    expect(subScreenMediaQuery.devicePixelRatio, devicePixelRatio);
    expect(subScreenMediaQuery.textScaleFactor, textScaleFactor);
    expect(
      subScreenMediaQuery.padding,
      const EdgeInsets.only(top: 1.0, right: 2.0, bottom: 4.0),
    );
    expect(
      subScreenMediaQuery.viewPadding,
      const EdgeInsets.only(top: 6.0, left: 4.0, right: 8.0, bottom: 12.0),
    );
    expect(
      subScreenMediaQuery.viewInsets,
      const EdgeInsets.only(top: 5.0, right: 6.0, bottom: 8.0),
    );
    expect(subScreenMediaQuery.alwaysUse24HourFormat, true);
    expect(subScreenMediaQuery.accessibleNavigation, true);
    expect(subScreenMediaQuery.invertColors, true);
    expect(subScreenMediaQuery.disableAnimations, true);
    expect(subScreenMediaQuery.boldText, true);
    expect(subScreenMediaQuery.highContrast, true);
    expect(subScreenMediaQuery.displayFeatures, <DisplayFeature>[cutoutDisplayFeature]);
  });

  testWidgets('MediaQueryData.gestureSettings is set from window.viewConfiguration', (WidgetTester tester) async {
    tester.binding.window.viewConfigurationTestValue = const ViewConfiguration(
      gestureSettings: GestureSettings(physicalDoubleTapSlop: 100, physicalTouchSlop: 100),
    );

    expect(MediaQueryData.fromView(tester.binding.window).gestureSettings.touchSlop, closeTo(33.33, 0.1)); // Repeating, of course
    tester.binding.window.viewConfigurationTestValue = null;
  });

  testWidgets('MediaQuery can be partially depended-on', (WidgetTester tester) async {
    MediaQueryData data = const MediaQueryData(
      size: Size(800, 600),
      textScaleFactor: 1.1
    );

    int sizeBuildCount = 0;
    int textScaleFactorBuildCount = 0;

    final Widget showSize = Builder(
      builder: (BuildContext context) {
        sizeBuildCount++;
        return Text('size: ${MediaQuery.sizeOf(context)}');
      }
    );

    final Widget showTextScaleFactor = Builder(
      builder: (BuildContext context) {
        textScaleFactorBuildCount++;
        return Text('textScaleFactor: ${MediaQuery.textScaleFactorOf(context).toStringAsFixed(1)}');
      }
    );

    final Widget page = StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return MediaQuery(
          data: data,
          child: Center(
            child: Column(
              children: <Widget>[
                showSize,
                showTextScaleFactor,
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      data = data.copyWith(size: Size(data.size.width + 100, data.size.height));
                    });
                  },
                  child: const Text('Increase width by 100')
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      data = data.copyWith(textScaleFactor: data.textScaleFactor + 0.1);
                    });
                  },
                  child: const Text('Increase textScaleFactor by 0.1')
                )
              ]
            )
          )
        );
      },
    );

    await tester.pumpWidget(MaterialApp(home: page));
    expect(find.text('size: Size(800.0, 600.0)'), findsOneWidget);
    expect(find.text('textScaleFactor: 1.1'), findsOneWidget);
    expect(sizeBuildCount, 1);
    expect(textScaleFactorBuildCount, 1);

    await tester.tap(find.text('Increase width by 100'));
    await tester.pumpAndSettle();
    expect(find.text('size: Size(900.0, 600.0)'), findsOneWidget);
    expect(find.text('textScaleFactor: 1.1'), findsOneWidget);
    expect(sizeBuildCount, 2);
    expect(textScaleFactorBuildCount, 1);

    await tester.tap(find.text('Increase textScaleFactor by 0.1'));
    await tester.pumpAndSettle();
    expect(find.text('size: Size(900.0, 600.0)'), findsOneWidget);
    expect(find.text('textScaleFactor: 1.2'), findsOneWidget);
    expect(sizeBuildCount, 2);
    expect(textScaleFactorBuildCount, 2);
  });

  testWidgets('MediaQuery partial dependencies', (WidgetTester tester) async {
    MediaQueryData data = const MediaQueryData();

    int buildCount = 0;

    final Widget builder = Builder(
      builder: (BuildContext context) {
        _MediaQueryAspectVariant.aspect!.method(context);
        buildCount++;
        return const SizedBox.shrink();
      }
    );

    final Widget page = StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return MediaQuery(
          data: data,
          child: ListView(
            children: <Widget>[
              builder,
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    data = _MediaQueryAspectVariant.aspect!.data;
                  });
                },
                child: const Text('Change data')
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    data = data.copyWith();
                  });
                },
                child: const Text('Copy data')
              )
            ]
          )
        );
      },
    );

    await tester.pumpWidget(MaterialApp(home: page));
    expect(buildCount, 1);

    await tester.tap(find.text('Copy data'));
    await tester.pumpAndSettle();
    expect(buildCount, 1);

    await tester.tap(find.text('Change data'));
    await tester.pumpAndSettle();
    expect(buildCount, 2);

    await tester.tap(find.text('Copy data'));
    await tester.pumpAndSettle();
    expect(buildCount, 2);
  }, variant: _MediaQueryAspectVariant(
    values: <_MediaQueryAspectCase>[
      const _MediaQueryAspectCase(MediaQuery.sizeOf, MediaQueryData(size: Size(1, 1))),
      const _MediaQueryAspectCase(MediaQuery.maybeSizeOf, MediaQueryData(size: Size(1, 1))),
      const _MediaQueryAspectCase(MediaQuery.orientationOf, MediaQueryData(size: Size(2, 1))),
      const _MediaQueryAspectCase(MediaQuery.maybeOrientationOf, MediaQueryData(size: Size(2, 1))),
      const _MediaQueryAspectCase(MediaQuery.devicePixelRatioOf, MediaQueryData(devicePixelRatio: 1.1)),
      const _MediaQueryAspectCase(MediaQuery.maybeDevicePixelRatioOf, MediaQueryData(devicePixelRatio: 1.1)),
      const _MediaQueryAspectCase(MediaQuery.textScaleFactorOf, MediaQueryData(textScaleFactor: 1.1)),
      const _MediaQueryAspectCase(MediaQuery.maybeTextScaleFactorOf, MediaQueryData(textScaleFactor: 1.1)),
      const _MediaQueryAspectCase(MediaQuery.platformBrightnessOf, MediaQueryData(platformBrightness: Brightness.dark)),
      const _MediaQueryAspectCase(MediaQuery.maybePlatformBrightnessOf, MediaQueryData(platformBrightness: Brightness.dark)),
      const _MediaQueryAspectCase(MediaQuery.paddingOf, MediaQueryData(padding: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.maybePaddingOf, MediaQueryData(padding: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.viewInsetsOf, MediaQueryData(viewInsets: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.maybeViewInsetsOf, MediaQueryData(viewInsets: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.systemGestureInsetsOf, MediaQueryData(systemGestureInsets: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.maybeSystemGestureInsetsOf, MediaQueryData(systemGestureInsets: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.viewPaddingOf, MediaQueryData(viewPadding: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.maybeViewPaddingOf, MediaQueryData(viewPadding: EdgeInsets.all(1))),
      const _MediaQueryAspectCase(MediaQuery.alwaysUse24HourFormatOf, MediaQueryData(alwaysUse24HourFormat: true)),
      const _MediaQueryAspectCase(MediaQuery.maybeAlwaysUse24HourFormatOf, MediaQueryData(alwaysUse24HourFormat: true)),
      const _MediaQueryAspectCase(MediaQuery.accessibleNavigationOf, MediaQueryData(accessibleNavigation: true)),
      const _MediaQueryAspectCase(MediaQuery.maybeAccessibleNavigationOf, MediaQueryData(accessibleNavigation: true)),
      const _MediaQueryAspectCase(MediaQuery.invertColorsOf, MediaQueryData(invertColors: true)),
      const _MediaQueryAspectCase(MediaQuery.maybeInvertColorsOf, MediaQueryData(invertColors: true)),
      const _MediaQueryAspectCase(MediaQuery.highContrastOf, MediaQueryData(highContrast: true)),
      const _MediaQueryAspectCase(MediaQuery.maybeHighContrastOf, MediaQueryData(highContrast: true)),
      const _MediaQueryAspectCase(MediaQuery.disableAnimationsOf, MediaQueryData(disableAnimations: true)),
      const _MediaQueryAspectCase(MediaQuery.maybeDisableAnimationsOf, MediaQueryData(disableAnimations: true)),
      const _MediaQueryAspectCase(MediaQuery.boldTextOf, MediaQueryData(boldText: true)),
      const _MediaQueryAspectCase(MediaQuery.maybeBoldTextOf, MediaQueryData(boldText: true)),
      const _MediaQueryAspectCase(MediaQuery.navigationModeOf, MediaQueryData(navigationMode: NavigationMode.directional)),
      const _MediaQueryAspectCase(MediaQuery.maybeNavigationModeOf, MediaQueryData(navigationMode: NavigationMode.directional)),
      const _MediaQueryAspectCase(MediaQuery.gestureSettingsOf, MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 1))),
      const _MediaQueryAspectCase(MediaQuery.maybeGestureSettingsOf, MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 1))),
      const _MediaQueryAspectCase(MediaQuery.displayFeaturesOf, MediaQueryData(displayFeatures: <DisplayFeature>[DisplayFeature(bounds: Rect.zero, type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown)])),
      const _MediaQueryAspectCase(MediaQuery.maybeDisplayFeaturesOf, MediaQueryData(displayFeatures: <DisplayFeature>[DisplayFeature(bounds: Rect.zero, type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown)])),
    ]
  ));
}

Future<void> pumpWidgetWithoutViewWrapper({required WidgetTester tester, required  Widget widget}) {
  tester.binding.attachRootWidget(widget);
  tester.binding.scheduleFrame();
  return tester.binding.pump();
}

class TestView implements FlutterView {
  TestView({
    PlatformDispatcher? platformDispatcher,
    required this.physicalSize,
    required this.devicePixelRatio,
    required this.padding,
    required this.viewPadding,
    required this.viewInsets,
    required this.systemGestureInsets,
  }) : _platformDispatcher = platformDispatcher;

  @override
  PlatformDispatcher get platformDispatcher => _platformDispatcher!;
  final PlatformDispatcher? _platformDispatcher;
  @override
  final Size physicalSize;
  @override
  final double devicePixelRatio;
  @override
  final ViewPadding padding;
  @override
  final ViewPadding viewPadding;
  @override
  final ViewPadding viewInsets;
  @override
  final ViewPadding systemGestureInsets;
  @override
  final ViewConfiguration viewConfiguration = const ViewConfiguration();
  @override
  final List<DisplayFeature> displayFeatures = <DisplayFeature>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestViewPadding implements ViewPadding {
  const TestViewPadding(this.value);
  final double value;

  @override
  double get bottom => value;
  @override
  double get left => value;
  @override
  double get right => value;
  @override
  double get top => value;
}
