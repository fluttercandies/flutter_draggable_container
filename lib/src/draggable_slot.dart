import 'package:flutter/widgets.dart';

import 'draggable_item.dart';

class DraggableSlot<T extends DraggableItem> extends StatefulWidget {
  final GlobalKey<DraggableSlotState<T>> key;
  final T? item;
  final Widget slot;
  final Rect rect;
  final Duration duration;

  const DraggableSlot({
    required this.key,
    required this.slot,
    required this.rect,
    required this.duration,
    this.item,
  }) : super(key: key);

  @override
  DraggableSlotState<T> createState() => DraggableSlotState<T>();
}

class DraggableSlotState<T extends DraggableItem>
    extends State<DraggableSlot<T>> {
  late T? item = widget.item;
  late Rect _rect = widget.rect;

  Rect get rect => this._rect;

  set rect(Rect value) {
    _rect = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned.fromRect(
      rect: _rect,
      duration: widget.duration,
      child: widget.slot,
    );
  }
}
