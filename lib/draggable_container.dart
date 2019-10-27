library flutter_draggable_container;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

Iterable<int> range(int start, int end) sync* {
  for (int i = start; i < end; ++i) {
    yield i;
  }
}

class DraggableItem {
  final Widget child;
  final bool fixed, deletable;

  DraggableItem(
      {@required this.child, this.fixed: false, this.deletable: true});
}

abstract class DraggableContainerEvent {
  onPanStart(DragStartDetails details);

  onPanUpdate(DragUpdateDetails details);

  onPanEnd(details);
}

mixin DraggableContainerEventMixin<T extends StatefulWidget> on State<T>
    implements DraggableContainerEvent {}

abstract class DraggableItemsEvent {
  _deleteFromWidget(DraggableItemWidget widget);
}

mixin StageItemsEventMixin<T extends StatefulWidget> on State<T>
    implements DraggableItemsEvent {}

// ignore: must_be_immutable
class DraggableContainer<T extends DraggableItem> extends StatefulWidget {
  final Size slotSize;

  final EdgeInsets slotMargin;

  final BoxDecoration slotDecoration, dragDecoration;
  final Function(List<T> items) onChanged;
  final Function(bool mode) onDraggableModeChanged;
  final Future<bool> Function(int index, T item) onBeforeDelete;
  final bool draggableMode, autoReorder;
  final Offset deleteButtonPosition;
  final Duration animateDuration;
  final bool allWayUseLongPress;
  List<DraggableItem> _items;
  Widget _deleteButton;

  DraggableContainer({
    Key key,
    @required List<DraggableItem> items,
    Widget deleteButton,
    this.slotSize = const Size(100, 100),
    this.slotMargin,
    this.slotDecoration,
    this.dragDecoration,
    this.autoReorder = true,
    this.onChanged,
    this.onDraggableModeChanged,
    this.onBeforeDelete,

    /// Enter draggable mode as soon as possible
    this.draggableMode: false,

    /// When in draggable mode,
    /// still use LongPress events to drag the children widget
    this.allWayUseLongPress: false,

    /// The duration for the children widget position transition animation
    this.animateDuration: const Duration(milliseconds: 200),
    this.deleteButtonPosition: const Offset(0, 0),
  }) : super(key: key) {
    if (deleteButton == null)
      deleteButton = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Icon(
          Icons.clear,
          size: 14,
          color: Colors.white,
        ),
      );
    this._deleteButton = deleteButton;
    if (items == null || items.length == 0) {
      throw Exception(
          'The items parameter need to define and cannot be an empty list');
    }
    this._items = items;
  }

  @override
  DraggableContainerState createState() => DraggableContainerState<T>();
}

class DraggableContainerState<T extends DraggableItem>
    extends State<DraggableContainer>
    with DraggableContainerEventMixin, StageItemsEventMixin {
  final GlobalKey _containerKey = GlobalKey();
  final List<DraggableItemWidget<T>> layers = [];
  final Map<DraggableSlot, DraggableItemWidget<T>> relationship = {};
  final List<DraggableItemWidget<T>> _dragBeforeList = [];

  bool draggableMode = false;
  DraggableItemWidget<T> pickUp;
  DraggableSlot toSlot;
  Offset longPressPosition;

  List get items =>
      List.from(relationship.values.map((widget) => widget?.item));

  @override
  void initState() {
    super.initState();
    draggableMode = widget.draggableMode;
    WidgetsBinding.instance.addPostFrameCallback(initItems);
  }

  DraggableItemWidget _createItemWidget(T item, Offset position) {
    return DraggableItemWidget<T>(
      key: UniqueKey(),
      stage: this,
      item: item,
      width: widget.slotSize.width,
      height: widget.slotSize.height,
      decoration: widget.dragDecoration,
      deleteButton: widget._deleteButton,
      deleteButtonPosition: widget.deleteButtonPosition,
      position: position,
      editMode: draggableMode,
      animateDuration: widget.animateDuration,
    );
  }

  bool addItem(T item, {bool triggerEvent: true}) {
    if (item == null) return false;
    final entries = relationship.entries;
    for (var i = 0; i < entries.length; i++) {
      final kv = entries.elementAt(i);
      if (kv.value == null) {
        final _widget = _createItemWidget(item, kv.key.position);
        relationship[kv.key] = _widget;
        layers.add(_widget);
        setState(() {});
        if (triggerEvent) _triggerOnChanged();
        return true;
      }
    }
    return false;
  }

  bool hasItem(T item) {
    return relationship.values
            .map((widget) => widget?.item)
            .toList()
            .indexOf(item) !=
        -1;
  }

  void initItems(_) {
    // print('initItems');
    relationship.clear();
    layers.clear();
    final RenderBox renderBoxRed =
        _containerKey.currentContext.findRenderObject();
    final size = renderBoxRed.size;
    // print('size $size');
    EdgeInsets margin = widget.slotMargin ?? EdgeInsets.all(0);
    double x = margin.left, y = margin.top;
    for (var i = 0; i < widget._items.length; i++) {
      final item = widget._items[i];
      final Offset position = Offset(x, y),
          maxPosition =
              Offset(x + widget.slotSize.width, y + widget.slotSize.height);
      final slot = DraggableSlot(
        position: position,
        width: widget.slotSize.width,
        height: widget.slotSize.height,
        decoration: widget.slotDecoration,
        maxPosition: maxPosition,
        event: this,
      );
      if (item == null) {
        relationship[slot] = null;
      } else {
        final itemWidget = _createItemWidget(item, position);
        layers.add(itemWidget);
        relationship[slot] = itemWidget;
      }
      x += widget.slotSize.width + margin.right;
      if (x + widget.slotSize.width + margin.right > size.width) {
        x = margin.left;
        y += widget.slotSize.height + margin.bottom + margin.top;
      }
    }
    setState(() {});
  }

  bool deleteIndex(int index, {bool triggerEvent: true}) {
    if (index < 0 || index >= relationship.length) return false;
    final entries = relationship.entries;
    for (var i = 0; i < entries.length; i++) {
      if (i != index) continue;
      final entry = entries.elementAt(i);
      if (entry.value == null) return false;
      relationship[entry.key] = null;
      layers.remove(entry.value);
      widget._items.remove(entry.value.item);
      reorder();
      setState(() {});
      if (triggerEvent) _triggerOnChanged();
      return true;
    }
    return false;
  }

  bool deleteItem(T item, {bool triggerEvent: true}) {
    final entries = relationship.entries;
    for (var kv in entries) {
      if (kv.value?.item == item) {
        relationship[kv.key] = null;
        layers.remove(kv.value);
        widget._items.remove(kv.value.item);
        reorder();
        setState(() {});
        if (triggerEvent) _triggerOnChanged();
        return true;
      }
    }
    return false;
  }

  bool insteadOfIndex(int index, T item, {bool triggerEvent: true}) {
    final slots = relationship.keys;
    if (index < 0 || slots.length < index) return false;
    final widget = _createItemWidget(item, slots.elementAt(index).position);
    relationship[slots.elementAt(index)] = widget;
    if (layers.length <= index)
      layers.add(widget);
    else
      layers[index] = widget;
    if (triggerEvent) _triggerOnChanged();
    reorder();
    setState(() {});
    return true;
  }

  T getItem(int index) {
    return relationship.values.elementAt(index)?.item;
  }

  Future<bool> _deleteFromWidget(DraggableItemWidget widget) async {
    if (this.widget.onBeforeDelete != null) {
      bool isDelete = await this.widget.onBeforeDelete(
          relationship.values.toList().indexOf(widget), widget.item);
      if (!isDelete) return false;
    }
    final entries = relationship.entries;
    for (var kv in entries) {
      if (kv.value == widget) {
        relationship[kv.key] = null;
        layers.remove(widget);
        this.widget._items.remove(widget.item);
        reorder();
        setState(() {});
        _triggerOnChanged();
        return true;
      }
    }
    return false;
  }

  reorder({int start: 0, int end: -1}) {
    var entries = relationship.entries;
    if (end == -1 || end > relationship.length) end = relationship.length;
    for (var i = start; i < end; i++) {
      final entry = entries.elementAt(i);
      final slot = entry.key;
      final item = entry.value;
      if (item == null) {
        final pair = findNextDraggableItem(start: i, end: end);
        if (pair == null) {
          break;
        } else {
          final nextSlot = pair.key, nextItem = pair.value;
          relationship[slot] = nextItem;
          if (nextItem != pickUp) nextItem.position = slot.position;
          relationship[nextSlot] = null;
        }
      }
    }
  }

  MapEntry<DraggableSlot, DraggableItemWidget> findNextDraggableItem(
      {start: 0, end: -1}) {
    if (end == -1) end = relationship.length;

    var res =
        relationship.entries.toList().getRange(start, end).firstWhere((pair) {
      return pair.value != null && !pair.value.item.fixed;
    }, orElse: () => null);

    return res;
  }

  _triggerOnChanged() {
    if (widget.onChanged != null)
      widget.onChanged(
          relationship.keys.map((key) => relationship[key]?.item).toList());
  }

  DraggableSlot findSlot(Offset position) {
    final keys = relationship.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final DraggableSlot slot = keys[i];
      if (slot.position <= position && slot.maxPosition >= position) {
        return slot;
      }
    }
    return null;
  }

  DraggableItemWidget findItem(Offset position) {
    for (var i = layers.length - 1; i >= 0; i--) {
      final item = layers[i];
      if (item.position <= position && item.maxPosition >= position) {
        return item;
      }
    }
    return null;
  }

  @override
  onPanStart(DragStartDetails details) {
    if (!draggableMode) return;
    final DraggableItemWidget item = findItem(details.localPosition);
    final DraggableSlot slot = findSlot(details.localPosition);
    if (item == null || item.item.fixed) return;
    pickUp = item;
    pickUp.active = true;
    toSlot = slot;
    _dragBeforeList.addAll(relationship.values);
    layers.remove(pickUp);
    layers.add(pickUp);
    setState(() {});
  }

  var temp;
  var moveChanged = 0;

  @override
  onPanUpdate(DragUpdateDetails details) {
    if (pickUp != null) {
      // 移动抓起的item
      pickUp.position += details.delta;
      final slot = findSlot(details.localPosition);
      if (slot != null && temp != slot) {
        temp = slot;
        moveChanged++;
        if (slot == toSlot) return;
        dragTo(slot);
      }
    }
  }

  dragTo(DraggableSlot to) {
    if (pickUp == null) return;
    final slots = relationship.keys.toList();
    final fromIndex = slots.indexOf(toSlot), toIndex = slots.indexOf(to);
    final start = math.min(fromIndex, toIndex),
        end = math.max(fromIndex, toIndex);
    // print('$start to $end');
    final widget = relationship[to];
    // 目标是固定位置的，不进行移动操作
    if (widget?.item?.fixed == true) {
      // print('移动失败');
      return;
    }
    // 前后互相移动
    if (end - start == 1) {
      // print('前后互相移动');
      if (widget != pickUp) widget?.position = toSlot.position;
      relationship[toSlot] = widget;
      relationship[to] = pickUp;
      toSlot = to;
    }
    // 多个移动
    else if (end - start > 1) {
      // print('跨多个slot');
      // 从前往后拖动
      relationship[toSlot] = null;
      toSlot = to;
      // print('从前往后拖动: 从 $start 到 $end');
      if (fromIndex == start) {
        reorder(start: start, end: end + 1);
        relationship[toSlot] = pickUp;
      }
      // 将后面的item移动到前面
      else {
        // print('将后面的item移动到前面: 从 $start 到 $end');
        DraggableSlot lastSlot = slots[start], currentSlot;
        DraggableItemWidget lastItem = relationship[lastSlot], currentItem;
        relationship[toSlot] = null;
        for (var i = start + 1; i <= end; i++) {
          currentSlot = slots[i];
          currentItem = relationship[currentSlot];
          // print('i: $i ,${currentItem?.item.toString()}');
          if (currentItem?.item?.fixed == true) continue;
          relationship[currentSlot] = lastItem;
          lastItem?.position = currentSlot.position;
          lastItem = currentItem;
        }
        setState(() {});
      }
      relationship[toSlot] = pickUp;
    }
  }

  @override
  onPanEnd(_) {
    if (pickUp != null) {
      pickUp.position = toSlot.position;
      pickUp.active = false;
    }
    pickUp = toSlot = null;
    if (listEquals(_dragBeforeList, relationship.values.toList()) == false) {
      if (widget.autoReorder) reorder();
      setState(() {});
      // print('changed');
      _triggerOnChanged();
      layers.clear();
      layers.addAll(relationship.values.where((widget) => widget != null));
    }
    _dragBeforeList.clear();

    setState(() {});
  }

  onLongPressStart(LongPressStartDetails details) {
    if (draggableMode == false) {
      // print('进入编辑模式');
      draggableMode = true;
      if (widget.onDraggableModeChanged != null)
        widget.onDraggableModeChanged(draggableMode);
      HapticFeedback.lightImpact();
      layers.forEach((item) => item.editMode = true);
    }

    if (draggableMode || (draggableMode && widget.allWayUseLongPress == true)) {
      longPressPosition = details.localPosition;
      onPanStart(DragStartDetails(localPosition: details.localPosition));
    }
  }

  onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    onPanUpdate(DragUpdateDetails(
        globalPosition: details.globalPosition,
        delta: details.localPosition - longPressPosition,
        localPosition: details.localPosition));
    longPressPosition = details.localPosition;
  }

  onLongPressEnd(_) {
    onPanEnd(null);
  }

  bool isDraggingItem(Offset globalPosition, Offset localPosition) {
    if (!draggableMode) return false;
    final slot = findSlot(localPosition);
    final item = relationship[slot];
    if (slot == null || item == null) return false;
    if (item.item.fixed == true) return false;
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition);
    for (HitTestEntry entry in result.path) {
      if (entry.target is RenderMetaData) {
        // print(entry.target);
        final RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is ItemDeleteButton) {
          // print('点击了删除按钮');
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // print('stage build');
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};
    gestures[LongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(),
            (LongPressGestureRecognizer instance) {
      instance
        ..onLongPressStart = onLongPressStart
        ..onLongPressMoveUpdate = onLongPressMoveUpdate
        ..onLongPressEnd = onLongPressEnd;
    });
    if (draggableMode && widget.allWayUseLongPress == false) {
      gestures[DraggableItemRecognizer] =
          GestureRecognizerFactoryWithHandlers<DraggableItemRecognizer>(
              () => DraggableItemRecognizer(containerState: this),
              (DraggableItemRecognizer instance) {
        instance
          ..isHitItem = isDraggingItem
          ..isDraggingItem = () {
            return pickUp != null;
          }
          ..onPanStart = onPanStart
          ..onPanUpdate = onPanUpdate
          ..onPanEnd = onPanEnd;
      });
    }

    return Container(
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: gestures,
        child: WillPopScope(
          onWillPop: () async {
            if (draggableMode) {
              draggableMode = false;
              // print('退出编辑模式');
              layers.forEach((item) => item.editMode = false);
              if (widget.onDraggableModeChanged != null)
                widget.onDraggableModeChanged(draggableMode);
              setState(() {});
              return false;
            }
            return true;
          },
          child: Stack(
            key: _containerKey,
            children: [...relationship.keys, ...layers],
          ),
        ),
      ),
    );
  }
}

class DraggableSlot extends StatefulWidget {
  final double width, height;
  final BoxDecoration decoration;
  final Offset position;
  final DraggableContainerEventMixin event;
  final Offset maxPosition;

//  get maxPosition => _maxPosition;

  const DraggableSlot(
      {Key key,
      this.width,
      this.height,
      this.decoration,
      this.position,
      this.maxPosition,
      this.event})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DraggableSlotState();
}

class _DraggableSlotState extends State<DraggableSlot> {
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

  Offset get position;
}

mixin ItemWidgetEventMixin<T extends StatefulWidget> on State<T>
    implements ItemWidgetEvent {}

// ignore: must_be_immutable
class DraggableItemWidget<T extends DraggableItem> extends StatefulWidget {
  final T item;
  final double width, height;
  final BoxDecoration decoration;
  final DraggableItemsEvent stage;
  final Widget deleteButton;
  final Offset deleteButtonPosition;
  final Duration animateDuration;
  final bool editMode;
  Offset _beginPosition, _maxPosition;
  _DraggableItemWidgetState myState;

  get position => myState?.position;

  set position(Offset position) {
    myState?.updatePosition(position);
    _maxPosition = position + Offset(width, height);
  }

  set editMode(bool value) => myState?.updateEditMode(value);

  set active(bool isActive) => myState?.updateActive(isActive);

  get active => myState?.active;

  get maxPosition => this._maxPosition;

  DraggableItemWidget({
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
    this.editMode: false,
  }) : super(key: key) {
    this._beginPosition = position;
    this._maxPosition = position + Offset(width, height);
  }

  @override
  _DraggableItemWidgetState createState() => _DraggableItemWidgetState();
}

class ItemDeleteButton extends StatelessWidget {
  final Widget child;
  final Function onTap;

  const ItemDeleteButton({Key key, this.onTap, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      child: GestureDetector(
        onTap: () {
          if (onTap != null) onTap();
        },
        child: child,
      ),
    );
  }
}

class _DraggableItemWidgetState extends State<DraggableItemWidget> {
  final zeroDuration = Duration.zero;
  double x, y;
  bool editMode = false;
  bool active = false;

  @override
  void initState() {
    super.initState();
    widget.myState = this;
    x = widget._beginPosition.dx;
    y = widget._beginPosition.dy;
    editMode = widget.editMode;
//    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // print('itemWidget build');
    final children = <Widget>[
      Container(
        decoration: active ? widget.decoration : null,
        width: widget.width,
        height: widget.height,
        child: IgnorePointer(
          ignoring:
              editMode && (widget.item.deletable && widget.item.fixed == false),
          ignoringSemantics: editMode,
          child: widget.item.child,
        ),
      )
    ];
    if (editMode && widget.item.deletable) {
      if (widget.deleteButton == null) {
        throw Exception(
            'The deletable item need the delete button, but it is undefined');
      } else {
        children.add(Positioned(
          right: widget.deleteButtonPosition.dx,
          top: widget.deleteButtonPosition.dy,
          child: ItemDeleteButton(
            onTap: () {
              widget.stage._deleteFromWidget(widget);
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

class DraggableItemRecognizer extends OneSequenceGestureRecognizer {
  Function onPanStart, onPanUpdate, onPanEnd;
  bool Function(Offset globalPosition, Offset localPosition) isHitItem;
  bool Function() isDraggingItem;
  final DraggableContainerState containerState;
  Offset widgetPosition = Offset.zero;

  DraggableItemRecognizer({@required this.containerState})
      : super(debugOwner: containerState);

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    final RenderBox renderBox = containerState.context.findRenderObject();
    widgetPosition = renderBox.localToGlobal(Offset.zero);
    if (isHitItem(event.position, event.localPosition)) {
      // print('占用事件');
      resolve(GestureDisposition.accepted);
    } else
      resolve(GestureDisposition.rejected);
  }

  @override
  void handleEvent(PointerEvent event) {
    // print('handleEvent');
    final localPosition = event.position - widgetPosition;
    if (event is PointerDownEvent) {
      if (!isHitItem(event.position, localPosition)) return;
      onPanStart(DragStartDetails(
          globalPosition: event.position, localPosition: localPosition));
    } else if (event is PointerMoveEvent) {
      onPanUpdate(DragUpdateDetails(
          globalPosition: event.position,
          localPosition: localPosition,
          delta: event.delta));
    } else if (event is PointerUpEvent) {
      if (isDraggingItem()) onPanEnd(DragEndDetails());
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'customPan';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
