import 'package:flutter/widgets.dart';

import 'draggable_container.dart';

class DraggableSlot2<T extends DraggableItem> extends StatefulWidget {
  final T? item;
  final Widget slot;
  final Rect rect;
  final Duration duration;

  const DraggableSlot2({
    Key? key,
    required this.slot,
    required this.rect,
    required this.duration,
    this.item,
  }) : super(key: key);

  @override
  DraggableSlot2State<T> createState() => DraggableSlot2State<T>();
}

class DraggableSlot2State<T extends DraggableItem>
    extends State<DraggableSlot2<T>> {
  late T? item = widget.item;
  late Rect rect = widget.rect;

  updateRect(Rect rect) {
    this.rect = rect;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned.fromRect(
      rect: rect,
      duration: widget.duration,
      child: widget.slot,
    );
  }
}
