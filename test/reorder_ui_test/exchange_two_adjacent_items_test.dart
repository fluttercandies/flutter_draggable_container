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
  testWidgets('Echange 0 and 1', (WidgetTester tester) async {
    DraggableContainerState<TestDraggableItem> state = await createContainer(tester);
    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    /// Move 0 to 1
    GlobalKey<DraggableItemWidgetState<TestDraggableItem>> from = state.relationship.entries.elementAt(0).value,
        to = state.relationship.entries.elementAt(1).value;
    TestGesture gesture = await tester.startGesture(Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect(
      [
        state.relationship.entries.elementAt(0).value.currentState.position,
        state.relationship.entries.elementAt(1).value.currentState.position,
      ],
      [Offset(0, 0), Offset(100, 0)],
    );

    /// Move 1 to 0
    from = state.relationship.entries.elementAt(1).value;
    to = state.relationship.entries.elementAt(0).value;
    gesture = await tester.startGesture(from.currentState.position + Offset(10, 10));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect([from.currentState.position, to.currentState.position], [Offset(0, 0), Offset(100, 0)]);
    expect([from.currentState.item.index, to.currentState.item.index], [0, 1]);

    /// Move 0 to 1 and move to back
    from = state.relationship.entries.elementAt(0).value;
    to = state.relationship.entries.elementAt(1).value;
    gesture = await tester.startGesture(from.currentState.position + Offset(10, 10));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(Offset(150, 50));
    expect([
      state.relationship.entries.elementAt(0).value,
      state.relationship.entries.elementAt(1).value
    ], [
      to,
      from
    ]);
    await gesture.moveTo(Offset(10, 10));
    expect([
      state.relationship.entries.elementAt(0).value,
      state.relationship.entries.elementAt(1).value
    ], [
      from,
      to
    ]);
    await gesture.up();
    expect([from.currentState.position, to.currentState.position], [Offset(0, 0), Offset(100, 0)]);
    expect([from.currentState.item.index, to.currentState.item.index], [0, 1]);
  });

  testWidgets('Echange 3 and 4, but the 4th item is\'s locked',
      (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    await tester.pump();
    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final from = state.relationship.entries.elementAt(3).value,
        to = state.relationship.entries.elementAt(4).value;
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(20, 20));
    await gesture.up();
    expect(
      getWidgetsPosition(state.relationship),
      defaultItemsPosition(),
    );
  });

  testWidgets('Echange 5 and 4, but the 4th item is\'s locked',
      (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final from = state.relationship.entries.elementAt(5).value,
        to = state.relationship.entries.elementAt(4).value;
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(20, 20));
    await gesture.up();
    expect(
      getWidgetsPosition(state.relationship),
      defaultItemsPosition(),
    );
  });
}
