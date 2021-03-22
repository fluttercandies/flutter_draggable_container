import 'package:draggable_container/draggable_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class DraggableItemRecognizer extends OneSequenceGestureRecognizer {
  late Function onPanStart, onPanUpdate, onPanEnd;
  late bool Function(Offset globalPosition, Offset localPosition) isHitItem;
  late bool Function() isDraggingItem;
  final DraggableContainerState containerState;
  Offset widgetPosition = Offset.zero;
  Offset widgetLeftTopPadding = Offset.zero;

  DraggableItemRecognizer({required this.containerState})
      : super(debugOwner: containerState);

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    final RenderBox renderBox =
        containerState.context.findRenderObject() as RenderBox;
    widgetPosition = renderBox.localToGlobal(Offset.zero);
    if (isHitItem(event.position, event.localPosition)) {
      // print('占用事件');
      resolve(GestureDisposition.accepted);
    } else
      resolve(GestureDisposition.rejected);
  }

  @override
  void handleEvent(PointerEvent event) {
    // print('handleEvent $event');
    final localPosition = event.position - widgetPosition - widgetLeftTopPadding;
    if (event is PointerDownEvent) {
      if (!isHitItem(event.position, localPosition)) return;
      onPanStart(DragStartDetails(
          globalPosition: event.position, localPosition: localPosition));
    } else if (event is PointerMoveEvent) {
      onPanUpdate(DragUpdateDetails(
          globalPosition: event.position,
          localPosition: localPosition,
          delta: event.delta));
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
