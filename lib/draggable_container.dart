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
  final Size slotSize;

  final EdgeInsets slotMargin;

  final List<StageItem> children;
  final BoxDecoration slotDecoration, dragDecoration;
  final Function(List<StageItem> items) onChanged;
  final Function(bool editMode) onEditModeChanged;
  final bool autoTrim;
  final Widget deleteButton;
  final Offset deleteButtonPosition;
  final Duration animateDuration;

  Stage(
      {Key key,
        @required this.children,
        this.slotSize = const Size(100, 100),
        this.slotMargin,
        this.slotDecoration,
        this.dragDecoration,
        this.onChanged,
        this.onEditModeChanged,

        /// When true, when delete a item,
        /// the remaining items will automatically fill the empty slot
        this.autoTrim: true,

        /// The children widget position animate duration
        this.animateDuration: const Duration(milliseconds: 200),
        this.deleteButton,
        this.deleteButtonPosition: const Offset(0, 0)})
      : super(key: key);

  @override
  _StageState createState() => _StageState();
}

class _StageState extends State<Stage>
    with StageDragEventMixin, StageItemsEventMixin {
  final GlobalKey _containerKey = GlobalKey();
  final List<StageItemWidget> items = [];
  final Map<StageSlot, StageItemWidget> relationship = {};
  final List<StageItemWidget> dragBefore = [], dragEnd = [];

  bool editMode = false;
  StageItemWidget _pickUp;
  StageSlot _fromSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(initItems);
  }

  void addItem(StageItem item) {}

  void initItems(_) {
//    print('initItems');
    relationship.clear();
    final RenderBox renderBoxRed =
    _containerKey.currentContext.findRenderObject();
    final size = renderBoxRed.size;
//    print('size $size');
    EdgeInsets margin = widget.slotMargin ?? EdgeInsets.all(0);
    double x = margin.left, y = margin.top;
    for (var i = 0; i < widget.children.length; i++) {
      final item = widget.children[i];
      final Offset position = Offset(x, y),
          maxPosition =
          Offset(x + widget.slotSize.width, y + widget.slotSize.height);
      final slot = StageSlot(
        position: position,
        width: widget.slotSize.width,
        height: widget.slotSize.height,
        decoration: widget.slotDecoration,
        maxPosition: maxPosition,
        event: this,
      );
      final itemWidget = StageItemWidget(
        key: UniqueKey(),
        stage: this,
        item: item,
        width: widget.slotSize.width,
        height: widget.slotSize.height,
        decoration: widget.dragDecoration,
        deleteButton: widget.deleteButton,
        deleteButtonPosition: widget.deleteButtonPosition,
        position: position,
        animateDuration: widget.animateDuration,
      );
      items.add(itemWidget);
      relationship[slot] = itemWidget;
      x += widget.slotSize.width + margin.right;
      if (x + widget.slotSize.width + margin.right > size.width) {
        x = margin.left;
        y += widget.slotSize.height + margin.bottom + margin.top;
      }
    }
    setState(() {});
  }

  @override
  deleteItem(StageItemWidget widget) {
    if (this.widget.children.contains(widget.item)) {
      this.widget.children.remove(widget.item);
      this.items.remove(widget);
      final slots = relationship.keys;
      final index = relationship.values.toList().indexOf(widget);
      if (this.widget.autoTrim) {
        for (var i = index; i < slots.length - 1; i++) {
          final slot = slots.elementAt(i), nextSlot = slots.elementAt(i + 1);
          final nextItem = relationship[nextSlot];
          if (nextItem != null && nextItem.item.fixed) {
            relationship[slot] = null;
            break;
          }
          relationship[slot] = relationship[nextSlot];
          if (relationship[slot] == null) continue;
          relationship[slot].position = slot.position;
        }
      } else {
        relationship[slots.elementAt(index)] = null;
      }

      setState(() {});
      _triggerOnChanged();
    }
  }

  _triggerOnChanged() {
    if (widget.onChanged != null)
      widget.onChanged(relationship.keys
//          .where((widget) => widget != null)
          .map((key) =>
      relationship[key] == null ? null : relationship[key].item)
          .toList());
  }

  StageSlot findSlot(Offset position) {
    final keys = relationship.keys.toList();
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
    dragBefore.addAll(relationship.values);
    if (item != null && item.item.fixed == false) {
//      print('onPanStart');
      _pickUp = item;
      _fromSlot = _toSlot = slot;
      items.remove(_pickUp);
      items.add(_pickUp);
      _pickUp.isDragging = true;
      setState(() {});
    }
  }

  onPanUpdate(DragUpdateDetails details) {
    final slots = relationship.keys.toList();
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
          final item = relationship[_toSlot];
          // 槽为空 或 锁住不能移动
          if (item == null || item.item.fixed) {
            _toSlot = _fromSlot;
            return;
          }
          final from = slots.indexOf(_fromSlot), to = slots.indexOf(_toSlot);
          final start = math.min(from, to), end = math.max(from, to);

          if ((end - start == 1) && item != _pickUp) {
//            print('两个交换');
            item.position = _fromSlot.position;
            relationship[_fromSlot] = item;
            relationship[_toSlot] = _pickUp;
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

//            print('${slots.indexOf(_fromSlot)} 需要移动的槽 $indexes');
            for (var i = 0; i < indexes.length - 1; i++) {
              final s = indexes[i], e = indexes[i + 1];
              final slotS = slots[s],
                  slotE = slots[e],
                  itemS = relationship[slotS],
                  itemE = relationship[slotE];
//              print('从 $s 到 $e');

              relationship[slotS] = itemE;
              if (itemS != _pickUp && itemS != null) {
//                print('$s');
                itemS.position = slotE.position;
              }

              relationship[slotE] = itemS;
              if (itemE != _pickUp && itemE != null) {
//                print('$e');
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
//      print('onPanCancel');
      _pickUp.isDragging = false;
      _pickUp.position = _toSlot.position;
      _pickUp = _fromSlot = _toSlot = null;
      // 有变化
      if (listEquals<StageItemWidget>(
          dragBefore, relationship.values.toList()) ==
          false) _triggerOnChanged();
    }
  }

  onLongPressStart(LongPressStartDetails details) {
    if (editMode == false) {
//      print('进入编辑模式');
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
//                print('退出编辑模式');
                items.forEach((item) => item.editMode = false);
                if (widget.onEditModeChanged != null)
                  widget.onEditModeChanged(editMode);
                return false;
              }
              return true;
            },
            child: Stack(
              key: _containerKey,
              children: [...relationship.keys, ...items],
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

// ignore: must_be_immutable
class StageItemWidget extends StatefulWidget {
  final StageItem item;
  final double width, height;
  final BoxDecoration decoration;
  final StageItemsEvent stage;
  final Widget deleteButton;
  final Offset deleteButtonPosition;
  final Duration animateDuration;
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
    this.animateDuration,
    this.deleteButtonPosition,
  }) : super(key: key) {
    this._beginPosition = position;
    this._maxPosition = position + Offset(width, height);
  }

  @override
  _StageItemWidgetState createState() => _StageItemWidgetState();
}

class _StageItemWidgetState extends State<StageItemWidget> {
  final zeroDuration = Duration.zero;
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
//    print('itemWidget build');
    final children = <Widget>[
      Container(
        decoration: active ? widget.decoration : null,
        width: widget.width,
        height: widget.height,
        child: IgnorePointer(
          ignoring: editMode &&
              (widget.item.deletable == true && widget.item.fixed == false),
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
          right: widget.deleteButtonPosition.dx,
          top: widget.deleteButtonPosition.dy,
          child: GestureDetector(
            onTap: () {
              widget.stage.deleteItem(widget);
            },
            child: widget.deleteButton,
          ),
        ));
      }
    }
    return AnimatedPositioned(
      left: x,
      top: y,
      duration: active ? zeroDuration : widget.animateDuration,
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
