import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'DraggableItemRecognizer.dart';

typedef IsFixed = bool Function(int index);
typedef IsDeletable = bool Function(int index);
typedef IndexItemBuilder = Widget? Function(BuildContext context,
    {int index, bool lock, bool deletable});

class DraggableContainer extends StatefulWidget {
  final int itemCount;
  final IndexItemBuilder? itemBuilder;
  final NullableIndexedWidgetBuilder? deleteButtonBuilder;
  final NullableIndexedWidgetBuilder? slotBuilder;
  final SliverGridDelegate gridDelegate;
  final IsFixed? isFixed;
  final IsDeletable? isDeletable;
  final EdgeInsets? padding;
  final Duration animationDuration;
  final Function(int newIndex, int oldIndex)? dragEnd;

  const DraggableContainer({
    Key? key,
    required this.itemCount,
    required this.gridDelegate,
    this.deleteButtonBuilder,
    this.slotBuilder,
    this.itemBuilder,
    this.isFixed,
    this.isDeletable,
    this.padding,
    this.dragEnd,
    Duration? animationDuration,
  })  : animationDuration = animationDuration ?? kThemeAnimationDuration,
        super(key: key);

  @override
  State<StatefulWidget> createState() => DraggableContainerState();
}

class DraggableContainerState extends State<DraggableContainer>
    with SingleTickerProviderStateMixin {
  final List<GlobalKey<_ItemWidget>> _keys = [];
  final List<Widget> _widgetLayers = [];
  final Map<DraggableSlot, GlobalKey<_ItemWidget>?> _relationship = {};
  late double layoutWidth;

  /// 事件竞技场
  late final Map<Type, GestureRecognizerFactory> _gestures = {
    LongPressGestureRecognizer: _longPressRecognizer
  };
  late final GestureRecognizerFactory _longPressRecognizer =
      GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(),
          (LongPressGestureRecognizer instance) {
    instance
      ..onLongPressStart = onLongPressStart
      ..onLongPressMoveUpdate = onLongPressMoveUpdate
      ..onLongPressEnd = onLongPressEnd;
  });

  late final GestureRecognizerFactory _draggableItemRecognizer =
      GestureRecognizerFactoryWithHandlers<DraggableItemRecognizer>(
          () => DraggableItemRecognizer(containerState: this),
          (DraggableItemRecognizer instance) {
    instance
      ..isHitItem = isHitItem
      ..isDraggingItem = () {
        return draggingItem != -1;
      }
      ..onPanStart = onPanStart
      ..onPanUpdate = onPanUpdate
      ..onPanEnd = onPanEnd;
  });

  bool _created = false;

  int draggingItem = -1;

  bool _edit = false;

  bool get edit => _edit;

  set edit(bool value) {
    _edit = value;
    _relationship.forEach((slot, item) {});
    if (value) {
      _gestures.remove(_longPressRecognizer);
      _gestures[DraggableItemRecognizer] = _draggableItemRecognizer;
    } else {
      _gestures.remove(_draggableItemRecognizer);
      _gestures[LongPressGestureRecognizer] = _longPressRecognizer;
    }
    setState(() {});
  }

  DraggableSlot createSlot({
    required int index,
    required Rect rect,
  }) {
    Widget child = widget.slotBuilder?.call(context, index) ??
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(
              width: 4,
              color: Colors.blueAccent,
            ),
          ),
        );
    return DraggableSlot(
      deletable: widget.isDeletable?.call(index) ?? true,
      fixed: widget.isFixed?.call(index) ?? false,
      rect: rect,
      child: child,
    );
  }

  Widget? createDeleteButton(GlobalKey<_ItemWidget> key, int index) {
    final isDeletable = widget.isDeletable?.call(index) ?? true;
    if (isDeletable == false) return null;
    Widget? button = widget.deleteButtonBuilder?.call(context, index);
    if (button != null) {
      button = AbsorbPointer(child: button);
    } else {
      button = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Icon(
          Icons.clear,
          size: 14,
          color: Colors.white,
        ),
      );
    }
    button = GestureDetector(
      onTap: () {
        _widgetLayers.remove(key.currentWidget);
        _relationship.removeWhere((Widget key, GlobalKey<_ItemWidget>? value) {
          if (value == null) return false;
          final isDelete = value == key;
          if (!isDelete) {}
          return isDelete;
        });
        print('删除 $index');
        setState(() {});
      },
      child: button,
    );
    return button;
  }

  void create() {
    _created = true;
    _keys.clear();
    _widgetLayers.clear();
    _relationship.clear();
    globalX = 0;
    globalY = 0;
    late Rect rect;
    for (var index = 0; index < widget.itemCount; index++) {
      rect = itemSize(layoutWidth, index);
      final lock = widget.isFixed?.call(index) ?? false;
      final deletable = widget.isDeletable?.call(index) ?? true;
      final slot = createSlot(index: index, rect: rect);
      final key = GlobalKey<_ItemWidget>();
      _keys.add(key);
      Widget? child = widget.itemBuilder?.call(
        context,
        index: index,
        lock: lock,
        deletable: deletable,
      );
      if (child != null) {
        _widgetLayers.add(ItemWidget(
          key: key,
          width: rect.height,
          height: rect.height,
          x: rect.left,
          y: rect.top,
          child: child,
          duration: widget.animationDuration,
          deleteButton: createDeleteButton(key, index),
          onLongPress: (_) {
            print('edit = true');
            this.edit = true;
          },
          dragStart: (_) {
            DraggableSlot? slot = findSlotFromState(_);
            final isLock = slot?.fixed ?? false;
            if (!isLock) {
              draggingItem = _widgetLayers.indexOf(_.widget);
              _widgetLayers.add(_widgetLayers.removeAt(draggingItem));
              setState(() {});
            }
            return !isLock;
          },
          dragUpdate: (_, position, DragUpdateDetails details) {
            print('dragUpdate ${details.globalPosition}');
            GlobalKey<_ItemWidget>? currentKey, targetKey;
            DraggableSlot? current, target;
            _relationship.keys.forEach((slot) {
              print(
                  'drag contain ${slot.rect.contains(details.globalPosition)}');
              if (_relationship[slot]?.currentState == _) {
                currentKey = _relationship[slot];
                current = slot;
                _relationship[slot] = null;
              } else if (!slot.fixed &&
                  slot.isContain(details.globalPosition)) {
                target = slot;
                targetKey = _relationship[slot];
                _relationship[slot] = currentKey;
              }
            });
            if (current != null && target != null) {
              print('批量移动');
              // _relationship.forEach((key, value) {
              // });
            }
          },
          dragEnd: (_) {
            // draggingItem = -1;
            setState(() {});
          },
        ));
      }
      _relationship[slot] = key;
    }
    globalY = rect.bottom +
        (widget.padding?.top ?? 0) +
        (widget.padding?.bottom ?? 0);
  }

  List<DraggableSlot> slots() => _relationship.keys.toList();

  DraggableSlot findSlotFromIndex(int index) {
    return this.slots()[index];
  }

  DraggableSlot? findSlotFromState(_ItemWidget state) {
    final slots = this.slots();
    for (var i = 0; i < widget.itemCount; i++) {
      if (_relationship[slots[i]]?.currentState == state) return slots[i];
    }
  }

  DraggableSlot? findSlotFromOffset(Offset offset) {
    final slots = this.slots();
    for (var i = 0; i < widget.itemCount; i++) {
      if (slots[i].isContain(offset)) return slots[i];
    }
  }

  bool isHitItem(Offset globalPosition, Offset localPosition) {
    final slot = findSlotFromOffset(localPosition);
    final state = _relationship[slot]?.currentState;
    if (slot == null || state == null) return false;
    if (slot.fixed) return false;
    return true;
  }

  late GlobalKey<_ItemWidget>? pickUp;

  onPanStart(_) {
    print('panStart');
    final slot = findSlotFromOffset(_.localPosition);
    final key = _relationship[slot];
    if (slot == null || slot.fixed || key == null) return;
    pickUp = key;
    key.currentState!.dragging = true;
    _widgetLayers.remove(key.currentWidget);
    _widgetLayers.add(key.currentWidget!);
    setState(() {});
  }

  onPanUpdate(DragUpdateDetails _) {
    if (pickUp != null) {
      // 移动抓起的item
      pickUp!.currentState!.position += _.delta;
      final slot = findSlotFromOffset(_.localPosition);
      if (slot != null && !slot.fixed) {
        // todo
      }
    }
  }

  onPanEnd(_) {
    pickUp?.currentState?.dragging = false;
  }

  late Offset longPressPosition;

  onLongPressStart(LongPressStartDetails _) {
    longPressPosition = _.localPosition;
    onPanStart(DragStartDetails(localPosition: _.localPosition));
  }

  onLongPressMoveUpdate(LongPressMoveUpdateDetails _) {
    print('onLongPressMoveUpdate');
    onPanUpdate(DragUpdateDetails(
      globalPosition: _.globalPosition,
      delta: _.localPosition - longPressPosition,
      localPosition: _.localPosition,
    ));
    longPressPosition = _.localPosition;
  }

  onLongPressEnd(_) {
    onPanEnd(null);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: _gestures,
      child: Container(
        color: Colors.grey,
        height: globalY,
        padding: widget.padding,
        child: LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            layoutWidth = constraints.maxWidth;
            if (_created == false) {
              create();
            }
            return Stack(
              children: [
                ..._relationship.keys,
                ..._widgetLayers,
              ],
            );
          },
        ),
      ),
    );
  }

  double globalX = 0, globalY = 0;

  Rect itemSize(double layoutWidth, int index) {
    var delegate = widget.gridDelegate;
    double left = 0,
        top = 0,
        width = 0,
        height = 0,
        crossSpacing = 0.0,
        mainSpacing = 0;
    if (delegate is SliverGridDelegateWithFixedCrossAxisCount) {
      crossSpacing = delegate.crossAxisSpacing;
      mainSpacing = delegate.mainAxisSpacing;
      width = (layoutWidth - ((delegate.crossAxisCount - 1) * mainSpacing)) /
          delegate.crossAxisCount;
      height = delegate.mainAxisExtent ?? width * delegate.childAspectRatio;
    } else if (delegate is SliverGridDelegateWithMaxCrossAxisExtent) {
      crossSpacing = delegate.crossAxisSpacing;
      width = delegate.maxCrossAxisExtent;
      height = width * delegate.childAspectRatio;
      left = width * index;
    }

    if (index == 0) {
      left = 0;
      top = 0;
    } else {
      left = globalX + width + mainSpacing;
      top = globalY;
    }
    if (left < layoutWidth) {
      globalX = left;
    } else {
      left = globalX = 0.0;
      top = globalY += height + crossSpacing;
    }
    // print('$index ${Rect.fromLTWH(left, top, width, height)}');
    return Rect.fromLTWH(left, top, width, height);
  }
}

class ItemWidget extends StatefulWidget {
  final Widget? deleteButton;
  final double width, height;
  final double x, y;
  final bool Function(_ItemWidget state) dragStart;
  final Function(
    _ItemWidget state,
    Offset position,
    DragUpdateDetails details,
  ) dragUpdate;
  final Function(_ItemWidget state) dragEnd;
  final Function(_ItemWidget state) onLongPress;
  final Widget child;
  final Duration duration;

  const ItemWidget({
    Key? key,
    required this.deleteButton,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.child,
    required this.dragStart,
    required this.dragUpdate,
    required this.dragEnd,
    required this.onLongPress,
    required this.duration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ItemWidget();
}

class _ItemWidget extends State<ItemWidget> {
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

class DraggableSlot extends StatelessWidget {
  final bool fixed;
  final bool deletable;
  final Rect rect;
  final Widget child;

  const DraggableSlot({
    Key? key,
    required this.fixed,
    required this.deletable,
    required this.rect,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: child,
    );
  }

  bool isContain(Offset offset) => rect.contains(offset);
}
