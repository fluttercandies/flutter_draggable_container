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
  late Size _size = widget.rect.size;
  late Offset _offset = widget.rect.topLeft;
  bool _dragging = false;

  Size get size => _size;

  set size(Size value) {
    _size = value;
    setState(() {});
  }

  Offset get offset => _offset;

  set offset(Offset value) {
    print('更新item offset');
    _offset = value;
    setState(() {});
  }

  bool get dragging => _dragging;

  set dragging(bool value) {
    _dragging = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: _offset.dx,
      top: _offset.dy,
      width: _size.width,
      height: _size.height,
      duration: _dragging ? Duration.zero : widget.duration,
      child: MetaData(
        metaData: widget.key,
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
