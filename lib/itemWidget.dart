import 'package:flutter/widgets.dart';

import 'draggable_container.dart';

class DraggableWidget<T extends DraggableItem> extends StatefulWidget {
  final T item;
  final GlobalKey<DraggableWidgetState<T>> key;
  final Rect rect;
  final Widget child;
  final Widget? deleteButton;
  final Duration duration;

  const DraggableWidget({
    required this.key,
    required this.rect,
    required this.child,
    required this.item,
    required this.duration,
    this.deleteButton,
  }) : super(key: key);

  @override
  DraggableWidgetState<T> createState() => DraggableWidgetState<T>();
}

class DraggableWidgetState<T extends DraggableItem>
    extends State<DraggableWidget<T>> {
  late final T item = widget.item;
  late Rect _rect = widget.rect;
  bool _dragging = false;

  bool get dragging => _dragging;

  set dragging(bool value) {
    _dragging = value;
    setState(() {});
  }

  Rect get rect => _rect;
  set rect(Rect value) {
    // print('item更新rect from:$_rect to:$value');
    _rect = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned.fromRect(
      rect: _rect,
      duration: _dragging ? Duration.zero : widget.duration,
      child: MetaData(
        metaData: this,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (item.deletable() && widget.deleteButton != null)
              Positioned(
                right: 0,
                top: 0,
                child: AbsorbPointer(child: widget.deleteButton!),
              ),
          ],
        ),
      ),
    );
  }
}
