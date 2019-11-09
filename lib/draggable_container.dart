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
//  _deleteFromWidget(DraggableItemWidget widget);

  _deleteFromKey(GlobalKey<DraggableItemWidgetState> key);
}

mixin StageItemsEventMixin<T extends StatefulWidget> on State<T>
    implements DraggableItemsEvent {}

class DraggableContainer<T extends DraggableItem> extends StatefulWidget {
  final Size slotSize;

  final EdgeInsets slotMargin;

  final BoxDecoration slotDecoration, dragDecoration;
  final Function(List<T> items) onChanged;
  final Function(bool mode) onDraggableModeChanged;
  final Future<bool> Function(int index, T item) onBeforeDelete;
  final Function onDragEnd;
  final bool draggableMode, autoReorder;
  final Offset deleteButtonPosition;
  final Duration animateDuration;
  final bool allWayUseLongPress;
  final List<DraggableItem> items;
  final Widget deleteButton;

  DraggableContainer({
    Key key,
    @required this.items,
    this.deleteButton,
    this.slotSize = const Size(100, 100),
    this.slotMargin,
    this.slotDecoration,
    this.dragDecoration,
    this.autoReorder: true,

    /// events
    this.onChanged,
    this.onDraggableModeChanged,
    this.onBeforeDelete,
    this.onDragEnd,

    /// Enter draggable mode as soon as possible
    this.draggableMode: false,

    /// When in draggable mode,
    /// still use LongPress events to drag the children widget
    this.allWayUseLongPress: false,

    /// The duration for the children widget position transition animation
    this.animateDuration: const Duration(milliseconds: 200),
    this.deleteButtonPosition: const Offset(0, 0),
  }) : super(key: key) {
    if (items == null || items.length == 0) {
      throw Exception('The items parameter is undeinfed or empty');
    }
  }

  @override
  DraggableContainerState createState() => DraggableContainerState<T>();
}

class DraggableContainerState<T extends DraggableItem>
    extends State<DraggableContainer>
    with DraggableContainerEventMixin, StageItemsEventMixin {
  final GlobalKey _containerKey = GlobalKey();
  final Map<DraggableSlot, GlobalKey<DraggableItemWidgetState<T>>>
      relationship = {};
  final List<DraggableItemWidget> layers = [];
  final List<GlobalKey> _dragBeforeList = [];
  final Map<Type, GestureRecognizerFactory> gestures = {};

  Widget deleteButton;
  bool draggableMode = false;
  GlobalKey<DraggableItemWidgetState> pickUp;
  DraggableSlot toSlot;
  Offset longPressPosition;
  GestureRecognizerFactory _draggableItemRecognizer;
  double _maxHeight = 0;

  List get items => List.from(
      relationship.values.map((globalKey) => globalKey?.currentState?.item));

  @override
  void initState() {
    super.initState();
    deleteButton = widget.deleteButton;
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
    draggableMode = widget.draggableMode;
    gestures[LongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(),
            (LongPressGestureRecognizer instance) {
      instance
        ..onLongPressStart = onLongPressStart
        ..onLongPressMoveUpdate = onLongPressMoveUpdate
        ..onLongPressEnd = onLongPressEnd;
    });
    _draggableItemRecognizer =
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

    if (draggableMode && !widget.allWayUseLongPress) {
      gestures[DraggableItemRecognizer] = _draggableItemRecognizer;
    }

    WidgetsBinding.instance.addPostFrameCallback(_initItems);
  }

  void _createItemWidget(DraggableSlot slot, T item) {
    if (item == null) {
      relationship[slot] = null;
    } else {
      final GlobalKey<DraggableItemWidgetState<T>> key = GlobalKey();
      final widget = DraggableItemWidget<T>(
        key: key,
        stage: this,
        item: item,
        width: this.widget.slotSize.width,
        height: this.widget.slotSize.height,
        decoration: this.widget.dragDecoration,
        deleteButton: this.deleteButton,
        deleteButtonPosition: this.widget.deleteButtonPosition,
        position: slot.position,
        editMode: draggableMode,
        animateDuration: this.widget.animateDuration,
      );
      layers.add(widget);
      relationship[slot] = key;
    }
  }

  bool addItem(T item, {bool triggerEvent: true}) {
    if (item == null) return false;
    final entries = relationship.entries;
    for (var i = 0; i < entries.length; i++) {
      final kv = entries.elementAt(i);
      if (kv.value == null) {
        _createItemWidget(kv.key, item);
        setState(() {});
        if (triggerEvent) _triggerOnChanged();
        return true;
      }
    }
    return false;
  }

  bool hasItem(T item) {
    return relationship.values
            .map((key) => key?.currentState?.item)
            .toList()
            .indexOf(item) >
        -1;
  }

  void _initItems(_) {
    // print('initItems');
    relationship.clear();
    layers.clear();
    final RenderBox renderBoxRed =
        _containerKey.currentContext.findRenderObject();
    final size = renderBoxRed.size;
    // print('size $size');
    EdgeInsets margin = widget.slotMargin ?? EdgeInsets.all(0);
    double x = margin.left, y = margin.top;
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
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
      _createItemWidget(slot, item);
      x += widget.slotSize.width + margin.right;
      if (x + widget.slotSize.width + margin.right > size.width) {
        x = margin.left;
        y += widget.slotSize.height + margin.bottom + margin.top;
      }
    }
    _maxHeight = y;
    _changeChildrenMode(widget.draggableMode);
    setState(() {});
  }

  bool deleteIndex(int index, {bool triggerEvent: true}) {
    if (index < 0 || index >= relationship.length) return false;
    final entries = relationship.entries;
    for (var i = 0; i < entries.length; i++) {
      if (i != index) continue;
      final kv = entries.elementAt(i);
      if (kv.value == null) return false;
      relationship[kv.key] = null;
      layers.remove(kv.value?.currentWidget);
      if (widget.autoReorder) reorder();
      setState(() {});
      if (triggerEvent) _triggerOnChanged();
      return true;
    }
    return false;
  }

  bool deleteItem(T item, {bool triggerEvent: true}) {
    final entries = relationship.entries;
    for (var kv in entries) {
      if (kv.value?.currentState?.item == item) {
        layers.remove(kv.value.currentWidget);
        relationship[kv.key] = null;
        if (widget.autoReorder) reorder();
        setState(() {});
        if (triggerEvent) _triggerOnChanged();
        return true;
      }
    }
    return false;
  }

  bool insteadOfIndex(int index, T item,
      {bool triggerEvent: true, bool force: false}) {
    final slots = relationship.keys;
    if (index < 0 || slots.length <= index) return false;
    final slot = slots.elementAt(index);
    if (!force && relationship[slot]?.currentState?.item?.deletable == false)
      return false;
    layers.remove(relationship[slot]?.currentWidget);
    _createItemWidget(slot, item);
    if (widget.autoReorder) reorder();
    setState(() {});
    if (triggerEvent) _triggerOnChanged();
    return true;
  }

  bool moveTo(int from, int to, {bool triggerEvent: true, bool force: false}) {
    final slots = relationship.keys;
    if (from == to) return false;
    if (from < 0 || slots.length <= from) return false;
    if (to < 0 || slots.length <= to) return false;
    final fromSlot = slots.elementAt(from), toSlot = slots.elementAt(to);
    if (relationship[fromSlot] == null) return false;
    if (!force &&
        relationship[toSlot]?.currentState?.item?.deletable == false) {
      return false;
    }
    relationship[toSlot] = relationship[fromSlot];
    relationship[toSlot]?.currentState?.position = toSlot.position;
    relationship[fromSlot] = null;

    if (triggerEvent) _triggerOnChanged();
    return true;
  }

  T getItem(int index) {
    return relationship.values.elementAt(index)?.currentState?.item;
  }

  Future<bool> _deleteFromKey(GlobalKey<DraggableItemWidgetState> key) async {
    if (relationship.containsValue(key) == false) return false;

    final index = relationship.values.toList().indexOf(key);
    if (this.widget.onBeforeDelete != null) {
      bool isDelete =
          await this.widget.onBeforeDelete(index, key?.currentState?.item);
      if (!isDelete) return false;
    }
    final kv = relationship.entries.elementAt(index);
    relationship[kv.key] = null;
    if (widget.autoReorder) reorder();
    setState(() {});
    layers.remove(kv.value?.currentWidget);
    _triggerOnChanged();
    return true;
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
          if (nextItem != pickUp)
            nextItem.currentState.position = slot.position;
          relationship[nextSlot] = null;
        }
      }
    }
  }

  MapEntry<DraggableSlot, GlobalKey<DraggableItemWidgetState>>
      findNextDraggableItem({start: 0, end: -1}) {
    if (end == -1) end = relationship.length;

    var res =
        relationship.entries.toList().getRange(start, end).firstWhere((pair) {
      return pair.value?.currentState?.item?.fixed == false;
    }, orElse: () => null);

    return res;
  }

  _triggerOnChanged() {
    if (widget.onChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(relationship.keys
            .map((key) => relationship[key]?.currentState?.item)
            .toList());
      });
    }
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

  @override
  onPanStart(DragStartDetails details) {
    if (!draggableMode) return;
    final DraggableSlot slot = findSlot(details.localPosition);
    final key = relationship[slot];
    if (key == null ||
        key.currentState?.item == null ||
        key.currentState?.item?.fixed == true) return;
    pickUp = key;
    pickUp.currentState.active = true;
    layers.remove(pickUp.currentWidget);
    layers.add(pickUp.currentWidget);
    toSlot = slot;
    _dragBeforeList.addAll(relationship.values);
    setState(() {});
  }

  var temp;
  var moveChanged = 0;

  @override
  onPanUpdate(DragUpdateDetails details) {
    if (pickUp != null) {
      // 移动抓起的item
      pickUp.currentState.position += details.delta;
      final slot = findSlot(details.localPosition);
      if (slot != null && temp != slot) {
        temp = slot;
        moveChanged++;
        if (slot == toSlot) return;
        _dragTo(slot);
      }
    }
  }

  void _dragTo(DraggableSlot to) {
    if (pickUp == null) return;
    final slots = relationship.keys.toList();
    final fromIndex = slots.indexOf(toSlot), toIndex = slots.indexOf(to);
    final start = math.min(fromIndex, toIndex),
        end = math.max(fromIndex, toIndex);
    // print('$start to $end');
    final key = relationship[to];
    final state = key?.currentState;
    // 目标是固定位置的，不进行移动操作
    if (state?.item?.fixed == true) {
      // print('移动失败');
      return;
    }
    // 前后互相移动
    if (end - start == 1) {
      // print('前后互相移动');
      if (key != pickUp) key?.currentState?.position = toSlot.position;
      relationship[toSlot] = key;
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
        GlobalKey<DraggableItemWidgetState> lastKey = relationship[lastSlot],
            currentKey;
        relationship[toSlot] = null;
        for (var i = start + 1; i <= end; i++) {
          currentSlot = slots[i];
          currentKey = relationship[currentSlot];
          // print('i: $i ,${currentItem?.item.toString()}');
          if (currentKey?.currentState?.item?.fixed == true) continue;
          relationship[currentSlot] = lastKey;
          lastKey?.currentState?.position = currentSlot.position;
          lastKey = currentKey;
        }
        setState(() {});
      }
      relationship[toSlot] = pickUp;
    }
  }

  @override
  onPanEnd(_) {
    if (widget.allWayUseLongPress) gestures.remove(DraggableItemRecognizer);
    if (pickUp != null) {
      pickUp.currentState.position = toSlot.position;
      pickUp.currentState.active = false;
    }
    pickUp = toSlot = null;
    if (listEquals(_dragBeforeList, relationship.values.toList()) == false) {
      if (widget.autoReorder) reorder();
      // print('changed');
      _triggerOnChanged();
    }
    _dragBeforeList.clear();

    setState(() {});
    if (widget.onDragEnd != null) widget.onDragEnd();
  }

  onLongPressStart(LongPressStartDetails details) {
    if (draggableMode == false) {
      // print('进入编辑模式');
      draggableMode = true;
      if (widget.onDraggableModeChanged != null)
        widget.onDraggableModeChanged(draggableMode);
      HapticFeedback.lightImpact();
      _changeChildrenMode(true);
    }

    if (draggableMode || (draggableMode && widget.allWayUseLongPress == true)) {
      longPressPosition = details.localPosition;
      onPanStart(DragStartDetails(localPosition: details.localPosition));
    }

    if (widget.allWayUseLongPress == false) {
      gestures[DraggableItemRecognizer] = _draggableItemRecognizer;
    }
    setState(() {});
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
    final state = relationship[slot]?.currentState;
    if (slot == null || state == null) return false;
    if (state.item.fixed == true) return false;
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

  _changeChildrenMode(bool draggableMode) {
    relationship.values
        .forEach((key) => key?.currentState?.draggableMode = draggableMode);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(height: _maxHeight),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: gestures,
        child: WillPopScope(
          onWillPop: () async {
            if (draggableMode) {
              draggableMode = false;
              // print('退出编辑模式');
              _changeChildrenMode(false);
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

class DraggableSlot extends StatelessWidget {
  final double width, height;
  final BoxDecoration decoration;
  final Offset position;
  final DraggableContainerEventMixin event;
  final Offset maxPosition;

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
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
      child: Container(
        decoration: decoration,
      ),
    );
  }
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

abstract class ItemWidgetEvent {
  updatePosition(Offset position);

  updateEditMode(bool editMode);

  updateActive(bool isActive);

  Offset get position;
}

mixin ItemWidgetEventMixin<T extends StatefulWidget> on State<T>
    implements ItemWidgetEvent {}

class DraggableItemWidget<T extends DraggableItem> extends StatefulWidget {
  final T item;
  final double width, height;
  final BoxDecoration decoration;
  final DraggableItemsEvent stage;
  final Widget deleteButton;
  final Offset deleteButtonPosition;
  final Duration animateDuration;
  final bool editMode;
  final Offset position;

  const DraggableItemWidget({
    Key key,
    this.item,
    this.width,
    this.height,
    this.decoration,
    this.position,
    this.stage,
    this.deleteButton,
    this.animateDuration,
    this.deleteButtonPosition,
    this.editMode: false,
  }) : super(key: key);

  @override
  DraggableItemWidgetState createState() => DraggableItemWidgetState<T>(item);
}

class DraggableItemWidgetState<T extends DraggableItem>
    extends State<DraggableItemWidget> {
  final T item;
  double x, y;
  bool _draggableMode = false;
  bool _active = false;
  Duration _duration;

  DraggableItemWidgetState(this.item);

  set draggableMode(bool value) {
    _draggableMode = value;
    setState(() {});
  }

  get draggableMode => _draggableMode;

  set active(bool value) {
    _active = value;
    _duration = _active ? Duration.zero : widget.animateDuration;
    setState(() {});
  }

  get active => _active;

  @override
  void initState() {
    super.initState();
    x = widget.position.dx;
    y = widget.position.dy;
    _draggableMode = widget.editMode;
    _duration = widget.animateDuration;
  }

  @override
  Widget build(BuildContext context) {
    // print('itemWidget build');
    final children = <Widget>[
      Container(
        decoration: _active ? widget.decoration : null,
        width: widget.width,
        height: widget.height,
        child: IgnorePointer(
          ignoring: _draggableMode &&
              (widget.item.deletable && widget.item.fixed == false),
          ignoringSemantics: _draggableMode,
          child: widget.item.child,
        ),
      )
    ];
    if (_draggableMode && widget.item.deletable) {
      if (widget.deleteButton == null) {
        throw Exception(
            'The deletable item need the delete button, but it is undefined');
      } else {
        children.add(Positioned(
          right: widget.deleteButtonPosition.dx,
          top: widget.deleteButtonPosition.dy,
          child: ItemDeleteButton(
            onTap: () {
              widget.stage._deleteFromKey(widget.key);
            },
            child: widget.deleteButton,
          ),
        ));
      }
    }
    return AnimatedPositioned(
      left: x,
      top: y,
      duration: _duration,
      width: widget.width,
      height: widget.height,
      child: Stack(children: children),
    );
  }

  _update() {
    if (mounted) setState(() {});
  }

  get position => Offset(x, y);

  set position(Offset position) {
    x = position.dx;
    y = position.dy;
    _update();
  }

  get maxPosition => Offset(widget.width + x, widget.height + y);
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
