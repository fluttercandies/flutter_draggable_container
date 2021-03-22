import 'package:flutter/widgets.dart';

import 'draggable_container.dart';

class DraggableWidget<T extends DraggableItem> extends StatefulWidget {
  final T item;
  final GlobalKey<DraggableWidgetState<T>> key;
  final Rect rect;
  final Widget child;
  final Widget deleteButton;
  final Duration duration;

  const DraggableWidget({
    required this.key,
    required this.rect,
    required this.child,
    required this.item,
    required this.duration,
    required this.deleteButton,
  }) : super(key: key);

  @override
  DraggableWidgetState<T> createState() => DraggableWidgetState<T>();
}

class DraggableWidgetState<T extends DraggableItem>
    extends State<DraggableWidget<T>> {
  late final T item = widget.item;
  late Rect _rect = widget.rect;
  bool _dragging = false;
  bool _edit = false;
  Curve _curve = Curves.linear;
  late Duration _duration = widget.duration;

  bool get edit => this._edit;

  set edit(bool value) {
    this._edit = value;
    setState(() {});
  }

  bool get dragging => _dragging;

  set dragging(bool value) {
    _dragging = value;
    if (_dragging) {
      _duration = Duration.zero;
      _curve = Curves.linear;
    } else {
      _duration = widget.duration;
      _curve = Curves.easeOut;
    }
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
      duration: _duration,
      // curve: Curves.bounceInOut,
      child: MetaData(
        metaData: this,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_edit && item.deletable())
              Positioned(
                right: 0,
                top: 0,
                child: widget.deleteButton,
              ),
          ],
        ),
      ),
    );
  }
}
