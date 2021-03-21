import 'package:flutter/widgets.dart';

import 'draggable_container.dart';

class DraggableItemWidget extends StatefulWidget {
  final DraggableItem item;
  final Widget? deleteButton;
  final double width, height;
  final double x, y;
  final Widget child;
  final Duration duration;

  const DraggableItemWidget({
    Key? key,
    required this.item,
    required this.deleteButton,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.child,
    required this.duration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DraggableItemWidgetState();
}

class DraggableItemWidgetState extends State<DraggableItemWidget> {
  double width = 0, height = 0;
  Offset _position = Offset.zero;
  bool _dragging = false;
  bool _deletable = false;

  late Duration _duration = widget.duration;

  set deletable(bool value) {
    _deletable = value;
    setState(() {});
  }

  bool get dragging => _dragging;

  set dragging(bool value) {
    _dragging = value;
    setState(() {});
  }

  @override
  void initState() {
    width = widget.width;
    height = widget.height;
    _position = Offset(widget.x, widget.y);
    super.initState();
  }

  Offset get position => _position;

  set position(Offset value) {
    _position = value;
    setState(() {});
  }

  bool isContain(Offset offset) => Rect.fromLTWH(
        offset.dx,
        offset.dy,
        width,
        height,
      ).contains(offset);

  updateSize(double width, double height) {
    this.width = width;
    this.height = height;
    // print('update size');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : widget.duration,
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            child: widget.child,
          ),
          if (widget.deleteButton != null)
            Positioned(
              right: 0,
              top: 0,
              child: widget.deleteButton!,
            ),
        ],
      ),
    );
  }
}
