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
  testWidgets('Move 0 to 3', (WidgetTester tester) async {
    DraggableContainerState<TestDraggableItem> state =
        await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final GlobalKey<DraggableItemWidgetState<TestDraggableItem>> from =
            state.relationship.entries.elementAt(0).value,
        to = state.relationship.entries.elementAt(3).value;
    expect(
      [
        from.currentState.position,
        to.currentState.position,
      ],
      [Offset(0, 0), Offset(0, 100)],
    );
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect(getWidgetsIndex(state.relationship), [1, 2, 3, 0, 4, 5, 6, 7, 8]);
    expect([from.currentState.position, to.currentState.position],
        [Offset(0, 100), Offset(200, 0)]);
  });

  testWidgets('Move 3 to 0', (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final GlobalKey<DraggableItemWidgetState<TestDraggableItem>> from =
            state.relationship.entries.elementAt(3).value,
        to = state.relationship.entries.elementAt(0).value;
    expect([from.currentState.position, to.currentState.position],
        [Offset(0, 100), Offset(0, 0)]);
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect(getWidgetsPosition(state.relationship), defaultItemsPosition());
    expect(getWidgetsIndex(state.relationship), [3, 0, 1, 2, 4, 5, 6, 7, 8]);
  });

  testWidgets('Move 0 to 6', (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final GlobalKey<DraggableItemWidgetState<TestDraggableItem>> from =
            state.relationship.entries.elementAt(0).value,
        to = state.relationship.entries.elementAt(6).value;
    expect([from.currentState.position, to.currentState.position],
        [Offset(0, 0), Offset(0, 200)]);
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect(getWidgetsPosition(state.relationship), defaultItemsPosition());
    expect(getWidgetsIndex(state.relationship), [1, 2, 3, 5, 4, 6, 0, 7, 8]);
  });

  testWidgets('Move 6 to 0', (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final GlobalKey<DraggableItemWidgetState<TestDraggableItem>> from =
            state.relationship.entries.elementAt(6).value,
        to = state.relationship.entries.elementAt(0).value;
    expect([from.currentState.position, to.currentState.position],
        [Offset(0, 200), Offset(0, 0)]);
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect(getWidgetsPosition(state.relationship), defaultItemsPosition());
    expect(getWidgetsIndex(state.relationship), [6, 0, 1, 2, 4, 3, 5, 7, 8]);
  });

  testWidgets('Move 5 to 8', (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final GlobalKey<DraggableItemWidgetState<TestDraggableItem>> from =
            state.relationship.entries.elementAt(5).value,
        to = state.relationship.entries.elementAt(8).value;
    expect(
      [
        from.currentState.position,
        to.currentState.position,
      ],
      [Offset(200, 100), Offset(200, 200)],
    );
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect(getWidgetsPosition(state.relationship), defaultItemsPosition());
    expect(
      getWidgetsIndex(state.relationship),
      [0, 1, 2, 3, 4, 6, 7, 8, 5],
    );
  });

  testWidgets('Move 8 to 5', (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    expect(state.draggableMode, false);
    expect(state.pickUp, null);

    final GlobalKey<DraggableItemWidgetState<TestDraggableItem>> from =
            state.relationship.entries.elementAt(8).value,
        to = state.relationship.entries.elementAt(5).value;
    expect(
      [
        from.currentState.position,
        to.currentState.position,
      ],
      [Offset(200, 200), Offset(200, 100)],
    );
    TestGesture gesture =
        await tester.startGesture(from.currentState.position + Offset(50, 50));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from);
    await gesture.moveTo(to.currentState.position + Offset(10, 10));
    await gesture.up();
    expect(getWidgetsPosition(state.relationship), defaultItemsPosition());
    expect(
      getWidgetsIndex(state.relationship),
      [0, 1, 2, 3, 4, 8, 5, 6, 7],
    );
  });
}
