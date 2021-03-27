import 'package:flutter/widgets.dart';

import 'draggable_item.dart';
import 'draggable_container.dart';

class DraggableWidget<T extends DraggableItem> extends StatefulWidget {
  final T? item;
  final GlobalKey<DraggableWidgetState<T>> key;
  final Rect rect;
  final NullableItemBuilder<T> itemBuilder;
  final Widget deleteButton;
  final Duration duration;
  final BoxDecoration? draggingDecoration;

  const DraggableWidget({
    required this.key,
    required this.rect,
    required this.itemBuilder,
    required this.duration,
    required this.deleteButton,
    required this.item,
    this.draggingDecoration,
  }) : super(key: key);

  @override
  DraggableWidgetState<T> createState() => DraggableWidgetState<T>();
}

class DraggableWidgetState<T extends DraggableItem>
    extends State<DraggableWidget<T>> {
  late final T? item = widget.item;
  late Rect _rect = widget.rect;
  bool _dragging = false;
  bool _edit = false;
  late Duration _duration = widget.duration;
  Widget? child;

  bool get edit => this._edit;

  @override
  void initState() {
    child = widget.itemBuilder(context, widget.item);
    super.initState();
  }

  set edit(bool value) {
    this._edit = value;
    setState(() {});
  }

  bool get dragging => _dragging;

  set dragging(bool value) {
    _dragging = value;
    if (_dragging) {
      _duration = Duration.zero;
    } else {
      _duration = widget.duration;
    }
    if (mounted) setState(() {});
  }

  update() {
    child = widget.itemBuilder(context, widget.item);
    if (mounted) setState(() {});
  }

  Rect get rect => _rect;

  set rect(Rect value) {
    // print('item更新rect from:$_rect to:$value');
    _rect = value;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget child = MetaData(
      metaData: this,
      child: Stack(
        children: [
          if (this.child != null) Positioned.fill(child: this.child!),
          if (_edit && item?.deletable == true)
            Positioned(
              right: 0,
              top: 0,
              child: widget.deleteButton,
            ),
        ],
      ),
    );
    if (_dragging && widget.draggingDecoration != null) {
      child = Container(
        decoration: widget.draggingDecoration,
        child: child,
      );
    }
    return AnimatedPositioned.fromRect(
      rect: _rect,
      duration: _duration,
      // curve: Curves.bounceInOut,
      child: child,
    );
  }
}
