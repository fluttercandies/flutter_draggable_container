import 'dart:core';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/draggable_container.dart';
import '../utils.dart';

/// The items position
///
/// [0] [1] [2]
/// [3] <4> [5]
/// [6] [7] [8]
///
/// The fourth item is fixed

void main() {
  testWidgets('Pick up the first item', (WidgetTester tester) async {

    DraggableContainerState state = await createContainer(tester);

    await tester.pump();
    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);
    final pickUp = state.layers.first;
    final TestGesture gesture = await tester.startGesture(Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, pickUp);
    await gesture.moveTo(Offset(10, 10));
    expect(state.pickUp.position, Offset(-40, -40));
    await gesture.up();
    expect(state.pickUp, null);
    expect(pickUp.position, Offset(0, 0));
  });

  testWidgets('Pick up the 4th item, but it\'s fixed', (WidgetTester tester) async {

    DraggableContainerState state = await createContainer(tester);

    await tester.pump();
    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);
    final pickUp = state.layers[4];
    final TestGesture gesture =
        await tester.startGesture(pickUp.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, null);
    await gesture.moveTo(Offset(200, 200));
    await gesture.up();
    expect(state.pickUp, null);
    expect(pickUp.position, Offset(100, 100));
  });
}
