import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Widget;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'draggable_item_recognizer.dart';
import 'about_rect.dart';
import 'delete_button.dart';
import 'draggable_item.dart';
import 'draggable_item_widget.dart';
import 'draggable_slot.dart';
import 'utils.dart';

typedef Widget? NullableItemBuilder<T extends DraggableItem>(
  BuildContext context,
  T? item,
);
typedef Future<bool> BeforeDropCallBack<T extends DraggableItem>({
  T? fromItem,
  int fromSlotIndex,
  T? toItem,
  int toSlotIndex,
});
typedef Future<bool> BeforeRemoveCallBack<T extends DraggableItem>(
    T? item, int slotIndex);

class DraggableContainer<T extends DraggableItem> extends StatefulWidget {
  final List<T?> items;
  final NullableItemBuilder<T> itemBuilder;
  final NullableItemBuilder<T>? deleteButtonBuilder;
  final NullableItemBuilder<T>? slotBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets? padding;
  final Duration animationDuration;
  final void Function(List<T?> items)? onChanged;
  final void Function(bool editting)? onEditModeChanged;
  final BeforeRemoveCallBack<T>? beforeRemove;
  final BeforeDropCallBack<T>? beforeDrop;
  final bool? tapOutSideExitEditMode;
  final BoxDecoration? draggingDecoration;

  const DraggableContainer({
    Key? key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.deleteButtonBuilder,
    this.slotBuilder,
    this.padding,
    this.onChanged,
    this.onEditModeChanged,
    this.beforeRemove,
    this.beforeDrop,
    this.tapOutSideExitEditMode,
    this.draggingDecoration,
    Duration? animationDuration,
  })  : animationDuration =
            animationDuration ?? const Duration(milliseconds: 200),
        super(key: key);

  @override
  DraggableContainerState<T> createState() => DraggableContainerState<T>();
}

class DraggableContainerState<T extends DraggableItem>
    extends State<DraggableContainer<T>> with AboutRect {
  final Map<DraggableSlot<T>, DraggableWidget<T>?> _relationship = {};

  List<T?> get items => _relationship.values.map((e) => e?.item).toList();

  late BeforeDropCallBack<T>? beforeDrop = widget.beforeDrop;
  late BeforeRemoveCallBack<T>? beforeRemove = widget.beforeRemove;

  double layoutWidth = 0;
  double _maxHeight = 0;

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
      ..isHitItem = _isHitItem
      ..isDraggingItem = () {
        return pickUp != null;
      }
      ..onPanStart = onPanStart
      ..onPanUpdate = onPanUpdate
      ..onPanEnd = onPanEnd;
  });

  /// 事件竞技场
  late final Map<Type, GestureRecognizerFactory> _gestures = {
    LongPressGestureRecognizer: _longPressRecognizer,
  };

  DraggableWidget<T>? pickUp;

  DraggableSlot<T>? _fromSlot;

  Widget? draggingWidget;
  T? draggingItem;
  GlobalKey<DraggableWidgetState>? draggingKey;

  Size get itemSize => super.itemSize;
  late bool _tapOutSideExitEditMode = widget.tapOutSideExitEditMode ?? true;

  bool get tapOutSideExitEditMode => this._tapOutSideExitEditMode;

  Map<DraggableSlot<T>, DraggableWidget<T>?> get relationship =>
      Map.from(_relationship);

  set tapOutSideExitEditMode(bool value) =>
      this._tapOutSideExitEditMode = value;

  bool _editMode = false;

  bool get editMode => _editMode;

  List<DraggableSlot<T>> get slots => _relationship.keys.toList();

  set editMode(bool value) {
    _editMode = value;
    if (value) {
      // 进入编辑模式
      _createOverlay();
      // _gestures.remove(LongPressGestureRecognizer);
      _gestures[DraggableItemRecognizer] = _draggableItemRecognizer;
    } else {
      // 退出编辑模式
      _removeOverlay();
      _gestures.remove(DraggableItemRecognizer);
      // _gestures[LongPressGestureRecognizer] = _longPressRecognizer;
    }
    _relationship.forEach((slot, item) {
      if (item == null) return;
      item.key.currentState?.edit = _editMode;
    });
    setState(() {});
    widget.onEditModeChanged?.call(_editMode);
  }

  OverlayEntry? _overlayEntry;
  final GlobalKey _containerKey = GlobalKey(), _stackKey = GlobalKey();

  late Rect _containerRect;

  void _createOverlay() {
    _overlayEntry?.remove();
    _containerRect = getRect(_containerKey.currentContext!);
    // print('_createOverlay $_containerRect');

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerMove: (e) {
                _containerRect = getRect(_containerKey.currentContext!);
                // print('onPointerMove $_containerRect');
              },
              onPointerUp: (e) {
                // print('onPointerUp $_containerRect');
                if (_tapOutSideExitEditMode &&
                    !_containerRect.contains(e.position) &&
                    pickUp == null) {
                  editMode = false;
                }
              },
            ),
            // Positioned.fromRect(
            //   rect: _containerRect,
            //   child: Listener(
            //     behavior: HitTestBehavior.opaque,
            //     child: Container(
            //       color: Colors.yellow.withOpacity(0.3),
            //     ),
            //   ),
            // ),
            if (pickUp != null) pickUp!,
          ],
        );
      },
    );
    Overlay.of(context)!.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    // print('_removeOverlay');
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool _created = false;

  void _createSlots() {
    if (_created) return;
    _created = true;
    _relationship.clear();
    List.generate(widget.items.length, (index) {
      addSlot(widget.items[index], update: false);
    });
  }

  void _updateSlots() {
    final entries = _relationship.entries;
    late Rect rect;
    for (var index = 0; index < entries.length; index++) {
      final entry = entries.elementAt(index);
      final slot = entry.key;
      final tile = entry.value;
      rect = calcSlotRect(index: index, layoutWidth: layoutWidth);
      // print('更新槽 $index ${key.currentState}');
      slot.key.currentState?.rect = rect;
      tile?.key.currentState?.rect = rect;
    }
    _maxHeight = rect.bottom;
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      _buildSlotRectCaches();
    });
  }

  DraggableWidget<T>? _createItem({
    required int index,
    T? item,
    required Rect rect,
  }) {
    Widget? child = widget.itemBuilder(context, item);
    if (child == null) return null;
    Widget button = widget.deleteButtonBuilder?.call(context, item) ??
        Container(
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
    final key = GlobalKey<DraggableWidgetState<T>>();
    late DraggableWidget<T> tile;
    tile = DraggableWidget<T>(
      key: key,
      rect: rect,
      item: item,
      edit: _editMode,
      duration: widget.animationDuration,
      itemBuilder: widget.itemBuilder,
      draggingDecoration: widget.draggingDecoration,
      deleteButton: GestureDetector(
        child: DeleteItemButton(child: button),
        onTap: () async {
          var isTrue = true;
          if (beforeRemove != null)
            isTrue = await beforeRemove!(
              item,
              _relationship.values.toList().indexOf(tile),
            );
          if (isTrue == true) {
            removeItem(item!);
            reorder();
            widget.onChanged?.call(items);
          }
        },
      ),
    );
    return tile;
  }

  @override
  void didUpdateWidget(DraggableContainer<T> oldWidget) {
    // print('didUpdateWidget');
    _relationship.values.forEach((element) {
      if (element != null) {
        element.key.currentState
          ?..edit = _editMode
          ..update();
      }
    });
    super.didUpdateWidget(oldWidget);
  }

  bool _isHitItem(Offset globalPosition) {
    return findItemByEventPosition(globalPosition)?.item?.fixed == false;
  }

  DraggableWidget<T>? findItemByEventPosition(Offset globalPosition) {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance!.hitTest(result, globalPosition);
    // print('path length ${result.path.length}');
    for (HitTestEntry entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        final data = target.metaData;
        if (data is DraggableWidgetState<T> && data != pickUp) {
          return data.widget;
        } else if (data is DeleteItemButton) {
          return null;
        }
      }
    }
  }

  void _buildSlotRectCaches() {
    buildSlotRectCaches(_relationship.keys.map((e) => e.key.currentContext!));
  }

  Offset _dragOffset = Offset.zero;

  onPanStart(DragStartDetails _) {
    _buildSlotRectCaches();
    var _pickUp = findItemByEventPosition(_.globalPosition);
    if (_pickUp != null && _pickUp.item?.fixed == false) {
      this.pickUp = _pickUp;
      _dragOffset = getRect(_stackKey.currentContext!).topLeft;
      _fromSlot = findSlotFromTile(_pickUp);
      final offset = _pickUp.key.currentState!.rect.topLeft + _dragOffset;
      _pickUp.key.currentState!
        ..dragging = true
        ..rect = Rect.fromLTWH(
          offset.dx,
          offset.dy,
          _pickUp.rect.width,
          _pickUp.rect.height,
        );
      _createOverlay();
      setState(() {});
    }
  }

  Offset? startPosition;

  onPanUpdate(DragUpdateDetails _) {
    if (pickUp != null) {
      // print('panUpdate ${_.delta}');
      final rect = pickUp!.key.currentState!.rect;
      pickUp!.key.currentState?.rect = Rect.fromLTWH(
        rect.left + _.delta.dx,
        rect.top + _.delta.dy,
        rect.width,
        rect.height,
      );

      final entryIndex = findSlotByOffset(_.globalPosition);
      if (entryIndex != -1) {
        final entry = _relationship.entries.elementAt(entryIndex);
        final slot = entry.key;
        if (slot != _fromSlot) {
          _dragTo(slot);
        }
      }
    }
  }

  onPanEnd(_) {
    final _pickUp = this.pickUp;
    if (_pickUp != null) {
      // print('panEnd');
      final _fromSlot = this._fromSlot!;
      this.pickUp = null;
      this._fromSlot = null;
      final offset = _pickUp.key.currentState!.rect.topLeft - _dragOffset;
      _pickUp.key.currentState!.rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        _pickUp.rect.width,
        _pickUp.rect.height,
      );
      SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
        _pickUp.key.currentState!
          ..dragging = false
          ..rect = Rect.fromLTWH(
            _fromSlot.key.currentState!.rect.left,
            _fromSlot.key.currentState!.rect.top,
            _fromSlot.key.currentState!.rect.width,
            _fromSlot.key.currentState!.rect.height,
          );
      });
      _relationship[_fromSlot] = _pickUp;
      _createOverlay();
      setState(() {});
    }

    widget.onChanged?.call(items);
  }

  late Offset longPressPosition;

  onLongPressStart(LongPressStartDetails _) {
    // print('onLongPressStart');
    editMode = true;
    longPressPosition = _.localPosition;
    onPanStart(DragStartDetails(globalPosition: _.globalPosition));
  }

  onLongPressMoveUpdate(LongPressMoveUpdateDetails _) {
    // print('onLongPressMoveUpdate');
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

  void _dragTo(DraggableSlot<T> toSlot) async {
    if (_fromSlot == null || _fromSlot == toSlot) return;
    final slots = _relationship.keys.toList();
    final tiles = _relationship.values.toList();
    final fromIndex = slots.indexOf(_fromSlot!),
        toIndex = slots.indexOf(toSlot);
    final start = math.min(fromIndex, toIndex),
        end = math.max(fromIndex, toIndex);
    final T? fromItem = tiles[fromIndex]?.item;
    final T? toItem = tiles[toIndex]?.item;
    var canDrop = toItem == null || !toItem.fixed;
    if (beforeDrop != null) {
      canDrop = await beforeDrop!.call(
        fromItem: fromItem,
        fromSlotIndex: fromIndex,
        toItem: toItem,
        toSlotIndex: toIndex,
      );
    }
    // print('_dragTo $canDrop');
    if (!canDrop) return;
    if (end - start == 1) {
      // 前后交换
      // print('前后位置交换： $start to $end');
      _relationship[toSlot]?.key.currentState?.rect =
          _fromSlot!.key.currentState!.rect;
      _relationship[_fromSlot!] = _relationship[toSlot];
    } else if (end - start > 1) {
      // 多个交换
      _relationship[_fromSlot!] = null;
      if (fromIndex == start) {
        // 从前往后拖动
        // print('从前往后拖动： $start to $end, ${_relationship[_fromSlot!]}');
        reorder(start: start, end: end);
      } else {
        // print('从后往前拖动： $start to $end, ${_relationship[_fromSlot!]}');
        reorder(start: start, end: end, reverse: true);
      }
    }
    _fromSlot = toSlot;
  }

  void reorder({int start: 0, int end: -1, reverse: false}) {
    var slots = _relationship.keys.toList().getRange(start, end + 1).toList();
    // print('revers: $reverse, total: ${slots.length}, from $start to $end');
    if (reverse) {
      slots = slots.reversed.toList();
    }
    // print('after, from $start to $end');
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final tile = _relationship[slot];
      // print('i $i $tile');
      if (tile == null) {
        int next = -1;
        for (var j = i + 1; j < slots.length; j++) {
          // print('j $j');
          final nextItem = _relationship[slots[j]]?.item;
          if (j == (slots.length - 1) || nextItem?.fixed == false) {
            next = j;
            break;
          }
        }
        // print('next $next');
        if (next == -1) {
          break;
        } else {
          final nextSlot = _fromSlot = slots[next];
          final nextTile = _relationship[nextSlot];
          _relationship[slot] = nextTile;
          nextTile?.key.currentState?.rect = slot.key.currentState!.rect;
          _relationship[nextSlot] = null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('build');
    Widget child = RawGestureDetector(
      gestures: _gestures,
      child: LayoutBuilder(
        key: _containerKey,
        builder: (_, BoxConstraints constraints) {
          final _layoutWidth = constraints.maxWidth == double.infinity
              ? MediaQuery.of(context).size.width.roundToDouble()
              : constraints.maxWidth.roundToDouble();
          if (_layoutWidth != layoutWidth) {
            layoutWidth = _layoutWidth;
            try {
              _containerRect = getRect(_containerKey.currentContext!);
            } catch (e) {}
            // print('layoutBuild $layoutWidth');
            calcItemSize(widget.gridDelegate, layoutWidth);
            _createSlots();
            _updateSlots();
            if (_editMode) {
              SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
                _createOverlay();
              });
            }
          }
          // 容器高度
          final height = constraints.maxHeight == double.infinity
              ? _maxHeight
              : constraints.maxHeight;
          // print('容器高度 $height');
          final _slots = _relationship.keys;
          final _tiles = _relationship.values
              .where((e) => e != null && e != pickUp)
              .map((e) => e!);
          return Container(
            height: height,
            child: Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                ..._slots,
                ..._tiles,
              ],
            ),
          );
        },
      ),
    );
    if (widget.padding != null)
      child = Padding(padding: widget.padding!, child: child);
    return child;
  }

  DraggableSlot<T> _createSlot({
    required int index,
    required T? item,
    required Rect rect,
  }) {
    return DraggableSlot<T>(
      key: GlobalKey<DraggableSlotState<T>>(),
      item: item,
      rect: rect,
      duration: widget.animationDuration,
      slot: widget.slotBuilder?.call(context, item) ??
          Container(
            decoration: BoxDecoration(
              // borderRadius: BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                width: 4,
                color: Colors.blue,
              ),
            ),
            // child: Center(child: Text(_relationship.keys.length.toString())),
          ),
    );
  }

  DraggableSlot<T>? findSlotFromTile(DraggableWidget<T>? widget) {
    if (widget == null) return null;
    final index = _relationship.values.toList().indexOf(widget);
    if (index > -1) return _relationship.keys.elementAt(index);
  }

  void addSlot(T? item, {bool update = true}) {
    final index = _relationship.length;
    final Rect rect = calcSlotRect(index: index, layoutWidth: layoutWidth);
    final slot = _createSlot(index: index, item: item, rect: rect);
    final child = _createItem(index: index, item: item, rect: rect);
    _relationship[slot] = child;

    if (mounted && update) {
      _updateSlots();
      setState(() {});
      widget.onChanged?.call(items);
    }
  }

  void insertSlot(int index, T? item, {bool update = true}) {
    // print('insertSlot $index');
    final entry = _create(index, item);
    final keys = _relationship.keys.toList();
    final values = _relationship.values.toList();
    keys.insert(index, entry.key);
    values.insert(index, entry.value);
    final Iterable<MapEntry<DraggableSlot<T>, DraggableWidget<T>?>> entries =
        Iterable.generate(
      keys.length,
      (index) => MapEntry(keys[index], values[index]),
    );

    _relationship
      ..clear()
      ..addEntries(entries);
    if (mounted && update) {
      _updateSlots();
      setState(() {});
    }
    widget.onChanged?.call(items);
  }

  T? removeSlot(int index) {
    final key = _relationship.keys.elementAt(index);
    final item = _relationship.values.elementAt(index)?.item;
    _relationship.remove(key);
    if (mounted) {
      _updateSlots();
      setState(() {});
    }
    widget.onChanged?.call(items);
    return item;
  }

  void replaceItem(int index, T? item) {
    assert(
      index.clamp(0, _relationship.length - 1) == index,
      'Out of items range [${0}-${_relationship.length}]:$index',
    );
    final slot = _relationship.keys.elementAt(index);
    print('replaceItem $slot ${_relationship[slot]?.item}');
    final child = _createItem(
        index: index, item: item, rect: slot.key.currentState!.rect);
    _relationship[slot] = child;
    if (mounted) {
      _updateSlots();
      setState(() {});
    }
    widget.onChanged?.call(items);
  }

  int removeItem(T item) {
    final List<T?> items = _relationship.values.map((e) => e?.item).toList();
    final index = items.indexOf(item);
    if (index > -1) {
      removeItemAt(index);
    }
    return index;
  }

  T? removeItemAt(int index) {
    assert(
      index.clamp(0, _relationship.length - 1) == index,
      'Out of items range [${0}-${_relationship.length}]:$index',
    );
    final List<T?> items = _relationship.values.map((e) => e?.item).toList();
    final slot = _relationship.keys.elementAt(index);
    final child = _relationship[slot];
    _relationship[slot] = null;
    reorder();
    if (mounted) {
      _updateSlots();
      setState(() {});
    }
    widget.onChanged?.call(items);
    return child?.item;
  }

  MapEntry<DraggableSlot<T>, DraggableWidget<T>?> _create(int index, T? item) {
    final Rect rect = calcSlotRect(index: index, layoutWidth: layoutWidth);
    final slot = _createSlot(index: index, item: item, rect: rect);
    final child = _createItem(index: index, item: item, rect: rect);
    return MapEntry(slot, child);
  }
}
