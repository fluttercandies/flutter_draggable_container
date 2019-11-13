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
  testWidgets('Add a new slot', (WidgetTester tester) async {
    DraggableContainerState<TestDraggableItem> state =
        await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));

    print('await 1');

    /// add a empty slot
    state.addSlot();
    await tester.pump(Duration(seconds: 1));
    print('await 2');
    expect(state.items.length, 10);
    expect(state.items[9], null);

    /// add the new item to new slot
    final newItem = TestDraggableItem(666);
    state.addSlot(item: newItem);
    await tester.pump(Duration(seconds: 1));
    expect(state.items.length, 11);
    expect(state.items[10], newItem);
    expect(state.items[10].index, 666);

    /// because has a empty slot, so just has 9 children widgets
    /// but this children widget position is at the 10th slot
    expect(state.layers[9].position, state.relationship.keys.last.position);
  });

  testWidgets('Add multiple slots', (WidgetTester tester) async {
    DraggableContainerState<TestDraggableItem> state =
        await createContainer(tester);

    expect(state.layers[8].position, Offset(200, 200));

    /// add fail, need to > 1, nothing changed
    state.addSlots(0);
    await tester.pump(Duration(seconds: 1));
    expect(state.items.length, 9);

    state.addSlots(2);
    await tester.pump(Duration(seconds: 1));
    expect(state.items.length, 11);
  });
//
//  testWidgets('Remove the first item and the first slot',
//      (WidgetTester tester) async {
//    DraggableContainerState state = await createContainer(tester);
//
//    await tester.pump();
//    expect(state.layers[8].position, Offset(200, 200));
//    final item0 = state.items[0],
//        item1 = state.items[1],
//        item2 = state.items[2];
//    state.removeItem(item0);
//
//    /// because autoReorder = true, so the second item move to the first slot
//    expect(state.items[0], item1);
//
//    state.removeSlot(index: 0);
//    expect(state.items.length, 8);
//    expect(state.items[0], item2);
//  });
//
//  testWidgets('Remove the last item and the last slot',
//      (WidgetTester tester) async {
//    DraggableContainerState state = await createContainer(tester);
//
//    await tester.pump();
//    expect(state.layers[8].position, Offset(200, 200));
//
//    final item8 = state.items[8];
//    state.removeItem(item8);
//
//    expect(state.items[8], null);
//
//    state.removeSlot(index: 8);
//    expect(state.items.length, 8);
//    expect(state.layers[7].position, Offset(100, 200));
//  });
}
