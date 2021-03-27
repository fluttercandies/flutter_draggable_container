import 'package:draggable_container/draggable_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class DraggableItemRecognizer extends OneSequenceGestureRecognizer {
  late Function onPanStart, onPanUpdate, onPanEnd;
  late bool Function(Offset globalPosition) isHitItem;
  late bool Function() isDraggingItem;
  final DraggableContainerState containerState;

  DraggableItemRecognizer({required this.containerState})
      : super(debugOwner: containerState);

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    if (isHitItem(event.position)) {
      // print('占用事件');
      resolve(GestureDisposition.accepted);
    } else {
      resolve(GestureDisposition.rejected);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    // print('handleEvent $event');
    if (event is PointerDownEvent) {
      if (!isHitItem(event.position)) return;
      onPanStart(DragStartDetails(globalPosition: event.position));
    } else if (event is PointerMoveEvent) {
      onPanUpdate(DragUpdateDetails(
          globalPosition: event.position, delta: event.delta));
    } else if (event is PointerUpEvent) {
      if (isDraggingItem()) onPanEnd(DragEndDetails());
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'customPan';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
