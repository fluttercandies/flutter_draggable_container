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
  testWidgets('Test the insteadOfIndex method', (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));

    final item1 = TestDraggableItem(100, deletable: false),
        item2 = TestDraggableItem(200);
    state.insteadOfIndex(0, item1);
    await tester.pump(Duration(seconds: 1));
    expect(state.items[0], item1);

    state.insteadOfIndex(0, item2);
    await tester.pump(Duration(seconds: 1));
    state.insteadOfIndex(0, item2, force: true);
    await tester.pump(Duration(seconds: 1));
    expect(
        state.relationship.entries.elementAt(0).value.currentState.item, item2);
  });

  testWidgets('Test the moveTo method', (WidgetTester tester) async {
    DraggableContainerState state = await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));
    final item =
        state.relationship.entries.elementAt(0).value.currentState.item;
    expect(state.moveTo(0, 1), true);
    expect(state.items[0], null);
    expect(state.items[1], item);

    final item1 = TestDraggableItem(100, deletable: false);
    state.insteadOfIndex(0, item1);
    await tester.pump(Duration(seconds: 1));
    expect(state.items[0], item1);

    // move fail, because the 0th item not allow delete.
    expect(state.moveTo(1, 0), false);
    expect(state.items[0], item1);

    // force to move
    expect(state.moveTo(1, 0, force: true), true);
    expect(state.items[0], item);
  });
}
