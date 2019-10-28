import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/draggable_container.dart';

List<Offset> defaultItemsPosition() {
  return [
    Offset(0, 0),
    Offset(100, 0),
    Offset(200, 0),
    Offset(0, 100),
    Offset(100, 100),
    Offset(200, 100),
    Offset(0, 200),
    Offset(100, 200),
    Offset(200, 200),
  ];
}

List<Offset> getWidgetsPosition(
    Map<DraggableSlot, GlobalKey<DraggableItemWidgetState<TestDraggableItem>>> map) {
  return List.from(map.values.map((key) => key.currentState.position));
}

List<int> getWidgetsIndex(
    Map<DraggableSlot, GlobalKey<DraggableItemWidgetState<TestDraggableItem>>> map) {
  return List.from(map.values.map((key) => key.currentState.item.index));
}

class TestDraggableItem extends DraggableItem {
  final int index;

  TestDraggableItem(this.index, {bool fixed})
      : super(child: Container(), fixed: fixed);

  @override
  String toString() {
    return toJson().toString();
  }

  Map toJson() => {'index': index, 'fixed': fixed};
}

Future<DraggableContainerState<TestDraggableItem>> createContainer(WidgetTester tester) async {
  GlobalKey<DraggableContainerState> key = GlobalKey();
  await tester.binding.setSurfaceSize(Size(320, 1920));
  await tester.pumpWidget(
    StatefulBuilder(
      builder: (context, StateSetter setState) {
        return MaterialApp(
          home: Scaffold(
            body: DraggableContainer<TestDraggableItem>(
              key: key,
              items: createItems(9),
              slotSize: Size(100, 100),
              deleteButton: Container(),
            ),
          ),
        );
      },
    ),
  );
  await tester.pump();
  DraggableContainerState<TestDraggableItem> state = key.currentState;
  await tester.pump();
  return state;
}

List<TestDraggableItem> createItems(int count) {
  return List.generate(count, (i) => TestDraggableItem(i, fixed: i == 4));
}

printAllWidget(Map<DraggableSlot, DraggableItemWidget> map,
    {int start: 0, int end: -1}) {
  final entries = map.entries;
  if (end == -1) end = entries.length;
  for (var i = start; i < end; i++) {
    print('$i : ${entries.elementAt(i).value.position}');
  }
}

printAllItem(Map<DraggableSlot, DraggableItemWidget> map,
    {int start: 0, int end: -1}) {
  final entries = map.entries;
  if (end == -1) end = entries.length;
  for (var i = start; i < end; i++) {
    print('$i : ${entries.elementAt(i).value?.item.toString()}');
  }
}
