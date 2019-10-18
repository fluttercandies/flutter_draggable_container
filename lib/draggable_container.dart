library flutter_draggable_container;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class StageItem {
  final Widget child;
  final bool fixed, deletable;

  StageItem({@required this.child, this.fixed: false, this.deletable: true});
}

Iterable<int> range(int start, int end) sync* {
  for (int i = start; i < end; ++i) {
    yield i;
  }
}

abstract class StageEvent {
  onPanStart(DragStartDetails details);

  onPanUpdate(DragUpdateDetails details);

  onPanEnd(details);
}

mixin StageDragEventMixin<T extends StatefulWidget> on State<T>
implements StageEvent {}

abstract class StageItemsEvent {
  deleteItem(StageItemWidget widget);
}

mixin StageItemsEventMixin<T extends StatefulWidget> on State<T>
implements StageItemsEvent {}

class Stage extends StatefulWidget {
  final Size itemSize;

  final EdgeInsets margin;

  final List<StageItem> children;
  final BoxDecoration slotDecoration, dragDecoration;
  final Function(List<StageItem> items) onChanged;
  final Function(bool editMode) onEditModeChanged;
  final bool autoTrim;
  final Widget deleteButton;

  Stage(
      {Key key,
        @required this.children,
        this.itemSize = const Size(100, 100),
        this.margin,
        this.slotDecoration,
        this.dragDecoration,
        this.onChanged,
        this.onEditModeChanged,
        this.autoTrim,
        this.deleteButton})
      : super(key: key);

  @override
  _StageState createState() => _StageState();
}

class _StageState extends State<Stage>
    with StageDragEventMixin, StageItemsEventMixin {
  final GlobalKey _containerKey = GlobalKey();
  final List<StageItemWidget> items = [];
  final Map<StageSlot, StageItemWidget> relationShips = {};
  final List<StageItemWidget> dragBefore = [], dragEnd = [];

  bool editMode = false;
  StageItemWidget _pickUp;
  StageSlot _fromSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(initItems);
  }

  void initItems(_) {
    print('initItems');
    relationShips.clear();
    final RenderBox renderBoxRed =
    _containerKey.currentContext.findRenderObject();
    final size = renderBoxRed.size;
    print('size $size');
    EdgeInsets margin = widget.margin ?? EdgeInsets.all(0);
    double x = margin.left, y = margin.top;
    for (var i = 0; i < widget.children.length; i++) {
      final item = widget.children[i];
      final Offset position = Offset(x, y),
          maxPosition =
          Offset(x + widget.itemSize.width, y + widget.itemSize.height);
      final slot = StageSlot(
        position: position,
        width: widget.itemSize.width,
        height: widget.itemSize.height,
        decoration: widget.slotDecoration,
        maxPosition: maxPosition,
        event: this,
      );
      final itemWidget = StageItemWidget(
        key: UniqueKey(),
        stage: this,
        item: item,
        width: widget.itemSize.width,
        height: widget.itemSize.height,
        decoration: widget.dragDecoration,
        deleteButton: widget.deleteButton,
        position: position,
      );
      items.add(itemWidget);
      relationShips[slot] = itemWidget;
      x += widget.itemSize.width + margin.right;
      if (x + widget.itemSize.width + margin.right > size.width) {
        x = margin.left;
        y += widget.itemSize.height + margin.bottom + margin.top;
      }
    }
    setState(() {});
  }

  @override
  deleteItem(StageItemWidget widget) {
    if (this.widget.children.contains(widget.item)) {
      final slots = relationShips.keys;
      final index = relationShips.values.toList().indexOf(widget);
      this.widget.children.remove(widget.item);
      this.items.remove(widget);
      for (var i = index; i < slots.length - 1; i++) {
        final slot = slots.elementAt(i), nextSlot = slots.elementAt(i + 1);
        final item = relationShips[slot], nextItem = relationShips[nextSlot];
        if (item != null && item.item.fixed) continue;
        if (nextItem != null && nextItem.item.fixed) continue;
        relationShips[slot] = relationShips[nextSlot];
        relationShips[nextSlot] = null;
        if (relationShips[slot] == null) continue;
        relationShips[slot].position = slot.position;
      }
      setState(() {});
      _triggerOnChanged();
    }
  }

  _triggerOnChanged() {
    if (widget.onChanged != null)
      widget.onChanged(relationShips.values
          .where((widget) => widget != null)
          .map((widget) => widget.item)
          .toList());
  }

  StageSlot findSlot(Offset position) {
    final keys = relationShips.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final StageSlot slot = keys[i];
      if (slot.position <= position && slot.maxPosition >= position) {
        return slot;
      }
    }
    return null;
  }

  StageItemWidget findItem(Offset position) {
    for (var i = items.length - 1; i >= 0; i--) {
      final item = items[i];
      if (item.position <= position && item.maxPosition >= position) {
        return item;
      }
    }
    return null;
  }

  onPanStart(DragStartDetails details) {
    if (!editMode) return;
    final StageItemWidget item = findItem(details.localPosition);
    final StageSlot slot = findSlot(details.localPosition);
    dragBefore.clear();
    dragBefore.addAll(relationShips.values);
    if (item != null && item.item.fixed == false) {
      print('onPanStart');
      _pickUp = item;
      _fromSlot = _toSlot = slot;
      items.remove(_pickUp);
      items.add(_pickUp);
      _pickUp.isDragging = true;
      setState(() {});
    }
  }

  onPanUpdate(DragUpdateDetails details) {
    final slots = relationShips.keys.toList();
    if (_pickUp != null) {
//      print('panUpdate');
      // 移动抓起的item
      _pickUp.position += details.delta;
      final slot = findSlot(details.localPosition);
      if (slot != null) {
//        print('在 槽${slots.indexOf(slot)}');
        if (_toSlot == slot) return;
        _toSlot = slot;
        if (_toSlot != _fromSlot) {
          final item = relationShips[_toSlot];
          // 槽为空 或 锁住不能移动
          if (item == null || item.item.fixed) {
            _toSlot = _fromSlot;
            _pickUp.position = _toSlot.position;
            return;
          }
          final from = slots.indexOf(_fromSlot), to = slots.indexOf(_toSlot);
          final start = math.min(from, to), end = math.max(from, to);

          if ((end - start == 1) && item != _pickUp) {
            print('两个交换');
            item.position = _fromSlot.position;
            relationShips[_fromSlot] = item;
            relationShips[_toSlot] = _pickUp;
            _toSlot = _fromSlot;
            _fromSlot = slot;
            setState(() {});
          } else if (end - start > 1) {
            var indexes = range(start, end).toList();
            _toSlot = _fromSlot;
            _fromSlot = slot;
            if (from == end) {
              indexes = indexes.reversed.toList();
            }
            indexes.add(end);

            print('${slots.indexOf(_fromSlot)} 需要移动的槽 $indexes');
            for (var i = 0; i < indexes.length - 1; i++) {
              final s = indexes[i], e = indexes[i + 1];
              final slotS = slots[s],
                  slotE = slots[e],
                  itemS = relationShips[slotS],
                  itemE = relationShips[slotE];
              print('从 $s 到 $e');

              relationShips[slotS] = itemE;
              if (itemS != _pickUp && itemS != null) {
                print('$s');
                itemS.position = slotE.position;
              }

              relationShips[slotE] = itemS;
              if (itemE != _pickUp && itemE != null) {
                print('$e');
                itemE.position = slotS.position;
              }
            }
          }
          setState(() {});
        }
      }
    }
  }

  onPanEnd(details) {
//    print('onPanEnd');
    onPanCancel();
  }

  onPanCancel() {
    if (_pickUp != null) {
      print('onPanCancel');
      _pickUp.isDragging = false;
      _pickUp.position = _toSlot.position;
      _pickUp = _fromSlot = _toSlot = null;
      // 有变化
      if (listEquals<StageItemWidget>(
          dragBefore, relationShips.values.toList()) ==
          false) _triggerOnChanged();
    }
  }

  onLongPressStart(LongPressStartDetails details) {
    if (editMode == false) {
      print('进入编辑模式');
      editMode = true;
      HapticFeedback.lightImpact();
      if (widget.onEditModeChanged != null) widget.onEditModeChanged(editMode);
      items.forEach((item) => item.editMode = true);
      longPressPosition = details.localPosition;
      onPanStart(DragStartDetails(localPosition: details.localPosition));
    }
  }

  Offset longPressPosition;

  onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    onPanUpdate(DragUpdateDetails(
        globalPosition: details.globalPosition,
        delta: details.localPosition - longPressPosition,
        localPosition: details.localPosition));
    longPressPosition = details.localPosition;
  }

  onLongPressEnd(_) {
    onPanCancel();
  }

  @override
  Widget build(BuildContext context) {
//    print('stage build');
    return Container(
      child: Expanded(
        child: GestureDetector(
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onLongPressStart: onLongPressStart,
          onLongPressMoveUpdate: onLongPressMoveUpdate,
          onLongPressEnd: onLongPressEnd,
          child: WillPopScope(
            onWillPop: () async {
              if (editMode) {
                editMode = false;
                print('退出编辑模式');
                items.forEach((item) => item.editMode = false);
                if (widget.onEditModeChanged != null)
                  widget.onEditModeChanged(editMode);
                return false;
              }
              return true;
            },
            child: Stack(
              key: _containerKey,
              children: [...relationShips.keys, ...items],
            ),
          ),
        ),
      ),
    );
  }

  StageSlot _toSlot;
}

class StageSlot extends StatefulWidget {
  final double width, height;
  final BoxDecoration decoration;
  final Offset position;
  final StageDragEventMixin event;
  final Offset maxPosition;

//  get maxPosition => _maxPosition;

  const StageSlot(
      {Key key,
        this.width,
        this.height,
        this.decoration,
        this.position,
        this.maxPosition,
        this.event})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _StageSlotState();
}

class _StageSlotState extends State<StageSlot> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: widget.decoration,
      ),
    );
  }
}

abstract class ItemWidgetEvent {
  updatePosition(Offset position);

  updateEditMode(bool editMode);

  updateActive(bool isActive);

  get position;
}

mixin ItemWidgetEventMixin<T extends StatefulWidget> on State<T>
implements ItemWidgetEvent {}

class StageItemWidget extends StatefulWidget {
  final StageItem item;
  final double width, height;
  final BoxDecoration decoration;
  final StageItemsEvent stage;
  final Widget deleteButton;
  Offset _beginPosition, _maxPosition;
  _StageItemWidgetState _state;

  get position => _state.position;

  set position(Offset position) {
    _state.updatePosition(position);
    _maxPosition = _state.position + Offset(width, height);
  }

  set editMode(bool value) => _state.updateEditMode(value);

  set isDragging(bool isActive) => _state.updateActive(isActive);

  get maxPosition => this._maxPosition;

  StageItemWidget({
    Key key,
    this.item,
    this.width,
    this.height,
    this.decoration,
    Offset position,
    this.stage,
    this.deleteButton,
  }) : super(key: key) {
    this._beginPosition = position;
    this._maxPosition = position + Offset(width, height);
  }

  @override
  _StageItemWidgetState createState() => _StageItemWidgetState();
}

class _StageItemWidgetState extends State<StageItemWidget> {
  double x, y;
  bool editMode = false;
  bool active = false;

  @override
  void initState() {
    super.initState();
    widget._state = this;
    updatePosition(widget._beginPosition);
  }

  @override
  Widget build(BuildContext context) {
    print('itemWidget build');
    final children = <Widget>[
      Container(
        decoration: active ? widget.decoration : null,
        width: widget.width,
        height: widget.height,
        child: IgnorePointer(
          ignoring: editMode && widget.deleteButton != null,
          ignoringSemantics: editMode,
          child: widget.item.child,
        ),
      )
    ];
    if (editMode && widget.item.deletable) {
      if (widget.deleteButton == null) {
        throw Exception('The deletable item need the delete button');
      } else {
        children.add(Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              widget.stage.deleteItem(widget);
            },
            child: widget.deleteButton,
          ),
        ));
      }
    }
    return Positioned(
      left: x,
      top: y,
      width: widget.width,
      height: widget.height,
      child: Stack(children: children),
    );
  }

  updateActive(bool isActive) {
    this.active = isActive;
    _update();
  }

  updateEditMode(bool editMode) {
    this.editMode = editMode;
    _update();
  }

  updatePosition(Offset position) {
    this.x = position.dx;
    this.y = position.dy;
    _update();
  }

  _update() {
    if (mounted) setState(() {});
  }

  get position => Offset(x, y);
}
