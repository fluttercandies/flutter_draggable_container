import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'draggable_container.dart';
import 'itemWidget.dart';

class DraggableSlot<T extends DraggableItem> extends StatefulWidget {
  final int index;
  final GlobalKey<DraggableSlotState<T>> key;
  final NullableItemBuilder<T> itemBuilder;
  final NullableItemBuilder<T>? deleteButtonBuilder;
  final NullableItemBuilder<T>? slotBuilder;
  final Size itemSize;

  const DraggableSlot({
    required this.key,
    required this.index,
    required this.itemBuilder,
    required this.itemSize,
    this.slotBuilder,
    this.deleteButtonBuilder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DraggableSlotState<T>();
}

class DraggableSlotState<T extends DraggableItem>
    extends State<DraggableSlot<T>> {
  late T? item;
  late Widget slot;
  Widget? child, deleteButton;
  GlobalKey<DraggableWidgetState<T>>? childKey;

  Rect get rect {
    RenderBox box = context.findRenderObject() as RenderBox;
    final rect = box.paintBounds;
    final positionRed = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      positionRed.dx,
      positionRed.dy,
      rect.width,
      rect.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        slot,
        if (childKey != null) child!,
        if (deleteButton != null) deleteButton!,
      ],
    );
  }
}
