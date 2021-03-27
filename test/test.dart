import 'package:draggable_container/draggable_container.dart';
import 'package:draggable_container/src/draggable_item_widget.dart';
import 'package:draggable_container/src/draggable_slot.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MyItem extends DraggableItem {
  final int index;
  final bool deletable;
  final bool fixed;

  MyItem({
    required this.index,
    required this.deletable,
    required this.fixed,
  });

  @override
  String toString() {
    return '<MyItem> $index';
  }
}

Future<DraggableContainerState<MyItem>> createContainer(
    WidgetTester tester) async {
  GlobalKey<DraggableContainerState<MyItem>> key = GlobalKey();
  await tester.binding.setSurfaceSize(Size(300, 1920));
  await tester.pumpWidget(
    StatefulBuilder(
      builder: (context, StateSetter setState) {
        return MaterialApp(
          home: Scaffold(
            body: DraggableContainer<MyItem>(
              key: key,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              items: [
                MyItem(index: 0, deletable: true, fixed: false),
                MyItem(index: 1, deletable: true, fixed: false),
                MyItem(index: 2, deletable: true, fixed: false),
                MyItem(index: 3, deletable: true, fixed: false),
                MyItem(index: 4, deletable: true, fixed: true),
                MyItem(index: 5, deletable: true, fixed: false),
                MyItem(index: 6, deletable: true, fixed: false),
                MyItem(index: 7, deletable: true, fixed: false),
                MyItem(index: 8, deletable: true, fixed: false),
              ],
              itemBuilder: (_, item, index) {
                return Container(
                  child: Center(
                    child: Text(
                      item!.index.toString(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ),
  );
  await tester.pump();
  DraggableContainerState<MyItem> state = key.currentState!;
  await tester.pump();
  return state;
}

/// The items position
///
/// [0] [1] [2]
/// [3] <4> [5]
/// [6] [7] [8]
///
/// The fourth item is fixed

void main() {
  testWidgets('Move 0 to 3', (WidgetTester tester) async {
    DraggableContainerState<MyItem> state = await createContainer(tester);
    final GlobalKey<DraggableSlotState<MyItem>> fromSlot =
            state.relationship.entries.elementAt(0).key,
        toSlot = state.relationship.entries.elementAt(3).key;
    final GlobalKey<DraggableWidgetState<MyItem>> from =
            state.relationship.entries.elementAt(0).value!,
        to = state.relationship.entries.elementAt(3).value!;
    expect(
      [
        from.currentState!.rect.center,
        to.currentState!.rect.topLeft,
      ],
      [Offset(50, 50), Offset(0, 100)],
    );
    print('第一个item ${from.currentState!.rect.center}');
    TestGesture gesture = await tester.startGesture(Offset(10, 10));
    await tester.pump(kLongPressTimeout);
    expect(state.pickUp, from.currentState);
    await gesture.up();
  });
}
