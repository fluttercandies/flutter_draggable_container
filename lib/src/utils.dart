import 'package:flutter/material.dart';

Iterable<int> range(int start, int end) sync* {
  for (int i = start; i < end; ++i) {
    yield i;
  }
}

class DraggableItem {
  final Widget child;
  final bool fixed, deletable;

  DraggableItem(
      {@required this.child, this.fixed: false, this.deletable: true});
}

abstract class DraggableContainerEvent {
  onPanStart(DragStartDetails details);

  onPanUpdate(DragUpdateDetails details);

  onPanEnd(details);
}

abstract class ItemWidgetEvent {
  updatePosition(Offset position);

  updateEditMode(bool editMode);

  updateActive(bool isActive);

  Offset get position;
}
