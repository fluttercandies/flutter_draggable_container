import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Widget;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'DraggableItemRecognizer.dart';
import 'itemWidget.dart';
import 'utils.dart';
import 'aboutRect.dart';
import 'slot2.dart';
import 'deleteButton.dart';

typedef Widget? NullableItemBuilder<T extends DraggableItem>(
  BuildContext context,
  T? item,
  int index,
);

abstract class DraggableItem {
  bool fixed();

  bool deletable();

  @override
  String toString() {
    return 'DraggableItem: ${this.hashCode}';
  }
}

class DraggableContainer<T extends DraggableItem> extends StatefulWidget {
  final List<T?> items;
  final NullableItemBuilder<T> itemBuilder;
  final NullableItemBuilder<T>? deleteButtonBuilder;
  final NullableItemBuilder<T>? slotBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets? padding;
  final Duration animationDuration;
  final Function(int newIndex, int oldIndex)? dragEnd;
  final Function(bool editting)? onEditModeChange;
  final bool? tapOutSizeExitEdieMode;
  final BoxDecoration? draggingDecoration;

  const DraggableContainer({
    Key? key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.deleteButtonBuilder,
    this.slotBuilder,
    this.padding,
    this.dragEnd,
    this.onEditModeChange,
    this.tapOutSizeExitEdieMode,
    this.draggingDecoration,
    Duration? animationDuration,
  })  : animationDuration =
            animationDuration ?? const Duration(milliseconds: 200),
        super(key: key);

  @override
  DraggableContainerState<T> createState() => DraggableContainerState<T>();
}

class DraggableContainerState<T extends DraggableItem>
    extends State<DraggableContainer<T>>
    with SingleTickerProviderStateMixin, AboutRect {
  final List<T?> items = [];
  final Map<GlobalKey<DraggableSlot2State<T>>,
      GlobalKey<DraggableWidgetState<T>>?> _relationship = {};
  final List<DraggableSlot2<T>> _slots = [];
  final List<DraggableWidget<T>> _children = [];
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
      ..isHitItem = isHitItem
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

  DraggableWidgetState<T>? pickUp;

  GlobalKey<DraggableSlot2State<T>>? _fromSlot;

  Widget? draggingWidget;
  T? draggingItem;
  GlobalKey<DraggableWidgetState>? draggingKey;

  Size get itemSize => super.itemSize;
  late bool _tapOutSizeExitEditMode = widget.tapOutSizeExitEdieMode ?? true;

  bool get tapOutSideExitEditMode => this._tapOutSizeExitEditMode;

  set tapOutSideExitEditMode(bool value) =>
      this._tapOutSizeExitEditMode = value;

  bool _editMode = false;

  bool get editMode => _editMode;

  List<GlobalKey<DraggableSlot2State<T>>> get slots =>
      _relationship.keys.toList();

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
      item.currentState?.edit = _editMode;
    });
    setState(() {});
    widget.onEditModeChange?.call(_editMode);
  }

  OverlayEntry? _overlayEntry;
  late GlobalKey _stackKey = GlobalKey();

  void _createOverlay() {
    _overlayEntry?.remove();
    if (!_tapOutSizeExitEditMode) return;
    // final rect = getRect(context);

    _overlayEntry = new OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (e) {
                if (findSlotByOffset(e.position) == -1 && pickUp == null) {
                  editMode = false;
                }
              },
            ),
            // Positioned.fromRect(
            //   rect: rect,
            //   child: Container(
            //     color: Colors.yellow.withOpacity(0.3),
            //   ),
            // ),
            if (pickUp != null) pickUp!.widget,
          ],
        );
      },
    );
    Overlay.of(context)!.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool _created = false;

  void _createSlots() {
    if (_created) return;
    _created = true;
    _slots.clear();
    _children.clear();
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
      final key = entry.key;
      final value = entry.value;
      rect = calcSlotRect(index: index, layoutWidth: layoutWidth);
      // print('更新槽 $index ${key.currentState}');
      key.currentState?.rect = rect;
      value?.currentState?.rect = rect;
    }
    _maxHeight = rect.bottom;
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      _buildSlotRectCaches();
    });
  }

  DraggableWidget<T>? createItem({
    required int index,
    T? item,
    required Rect rect,
  }) {
    Widget? child = widget.itemBuilder(context, item, index);
    if (child == null) return null;
    Widget button = widget.deleteButtonBuilder?.call(context, item, index) ??
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
    return DraggableWidget(
      key: GlobalKey<DraggableWidgetState<T>>(),
      rect: rect,
      item: item,
      duration: widget.animationDuration,
      child: child,
      draggingDecoration: widget.draggingDecoration,
      deleteButton: GestureDetector(
        child: DeleteItemButton(child: button),
        onTap: () {
          // todo
          print('删除项目');
        },
      ),
    );
  }

  bool isHitItem(Offset globalPosition) {
    return findItemByEventPosition(globalPosition)?.item?.fixed() == false;
  }

  DraggableWidgetState<T>? findItemByEventPosition(Offset globalPosition) {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance!.hitTest(result, globalPosition);
    // print('path length ${result.path.length}');
    for (HitTestEntry entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        final data = target.metaData;
        if (data is DraggableWidgetState<T> && data != pickUp) {
          return data;
        } else if (data is DeleteItemButton) {
          return null;
        }
      }
    }
  }

  void _buildSlotRectCaches() {
    buildSlotRectCaches(_relationship.keys.map((e) => e.currentContext!));
  }

  Offset _dragOffset = Offset.zero;
  onPanStart(DragStartDetails _) {
    _buildSlotRectCaches();
    pickUp = findItemByEventPosition(_.globalPosition);
    if (pickUp != null) {
      _dragOffset = getRect(_stackKey.currentContext!).topLeft;
      _createOverlay();
      _fromSlot = findSlotFromItemState(pickUp!);
      print('panStart $_fromSlot');
      _children.remove(pickUp!.widget);
      pickUp!.dragging = true;
      final offset = pickUp!.rect.topLeft + _dragOffset;
      pickUp!.rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        pickUp!.rect.width,
        pickUp!.rect.height,
      );
      setState(() {});
    }
  }

  Offset? startPosition;

  onPanUpdate(DragUpdateDetails _) {
    if (pickUp != null) {
      // print('panUpdate ${_.delta}');
      final rect = pickUp!.rect;
      pickUp!.rect = Rect.fromLTWH(
        rect.left + _.delta.dx,
        rect.top + _.delta.dy,
        rect.width,
        rect.height,
      );

      final entryIndex = findSlotByOffset(_.globalPosition);
      if (entryIndex != -1) {
        final entry = _relationship.entries.elementAt(entryIndex);
        final slot = entry.key;
        print('panUpdate $_fromSlot $slot');
        final value = entry.value;
        if ((value == null || value.currentState?.item?.fixed() == false) &&
            slot != _fromSlot) {
          _reorder(slot);
        }
      }
    }
  }

  onPanEnd(_) {
    if (pickUp != null) {
      print('panEnd');
      final _pickUp = this.pickUp!;
      final _fromSlot = this._fromSlot!;
      _children.add(_pickUp.widget);
      this.pickUp = null;
      this._fromSlot = null;
      final offset = _pickUp.rect.topLeft - _dragOffset;
      _pickUp.rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        _pickUp.rect.width,
        _pickUp.rect.height,
      );
      SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
        _pickUp.dragging = false;
        _pickUp.rect = Rect.fromLTWH(
          _fromSlot.currentState!.rect.left,
          _fromSlot.currentState!.rect.top,
          _fromSlot.currentState!.rect.width,
          _fromSlot.currentState!.rect.height,
        );
      });
      _relationship[_fromSlot] = _pickUp.widget.key;
      _createOverlay();
      setState(() {});
    }
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

  void _reorder(GlobalKey<DraggableSlot2State<T>> toSlot) {
    if (_fromSlot == null) return;
    final slots = _relationship.keys.toList();
    final fromIndex = slots.indexOf(_fromSlot!),
        toIndex = slots.indexOf(toSlot);
    final start = math.min(fromIndex, toIndex),
        end = math.max(fromIndex, toIndex);
    print('reorder $start to $end');
    if (end - start == 1) {
      // 前后交换
      print('前后交换');
      _relationship[toSlot]?.currentState?.rect = _fromSlot!.currentState!.rect;
      _relationship[_fromSlot!] = _relationship[toSlot];
      _fromSlot = toSlot;
    } else if (end - start > 1) {
      // 多个交换
      for (var i = start; i < end; i++) {
        print('reorder $i');
        final current = _relationship.entries.elementAt(i);
        final slot = current.key;
        final item = current.value;
        if (item == null) {
          final next = findNextDraggableItem(start: i, end: end);
          if (next == null) {
            break;
          }
          final nextSlot = next.key;
          final nextItem = next.value!;
          nextItem.currentState?.rect = Rect.fromLTWH(
            slot.currentState!.rect.left,
            slot.currentState!.rect.top,
            nextItem.currentState!.rect.width,
            nextItem.currentState!.rect.height,
          );
          _relationship[slot] = nextItem;
          _relationship[nextSlot] = null;
        }
      }
    }
  }

  MapEntry<GlobalKey<DraggableSlot2State<T>>,
      GlobalKey<DraggableWidgetState<T>>?>? findNextDraggableItem({
    required int start,
    required int end,
  }) {
    final entries = _relationship.entries.toList();
    for (var i = start; i < end; i++) {
      final entry = entries[i];
      if (entry.value?.currentState?.item?.fixed() == false) return entry;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = RawGestureDetector(
      gestures: _gestures,
      child: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          final _layoutWidth = constraints.maxWidth == double.infinity
              ? MediaQuery.of(context).size.width.roundToDouble()
              : constraints.maxWidth.roundToDouble();
          if (_layoutWidth != layoutWidth) {
            layoutWidth = _layoutWidth;
            print('layoutBuild $layoutWidth');
            calcItemSize(widget.gridDelegate, layoutWidth);
            _createSlots();
            _updateSlots();
          }
          // 容器高度
          final height = constraints.maxHeight == double.infinity
              ? _maxHeight
              : constraints.maxHeight;
          // print('容器高度 $height');
          return Container(
            height: height,
            child: Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                ..._slots,
                ..._children,
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

  DraggableSlot2<T> createSlot({
    required int index,
    required T? item,
    required Rect rect,
  }) {
    return DraggableSlot2<T>(
      key: GlobalKey<DraggableSlot2State<T>>(),
      item: item,
      rect: rect,
      duration: widget.animationDuration,
      slot: widget.slotBuilder?.call(context, item, index) ??
          Container(
            decoration: BoxDecoration(
              // borderRadius: BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                width: 4,
                color: Colors.blue,
              ),
            ),
            child: Center(child: Text(_relationship.keys.length.toString())),
          ),
    );
  }

  GlobalKey<DraggableSlot2State<T>>? findSlotFromItemState(
      DraggableWidgetState<T>? state) {
    if (state == null) return null;
    final index = _relationship.values.toList().indexOf(state.widget.key);
    if (index > -1) return _relationship.keys.elementAt(index);
  }

  addSlot(T? item, {bool update = true}) {
    final index = items.length;
    items.add(item);
    final Rect rect = calcSlotRect(index: index, layoutWidth: layoutWidth);
    final slot = createSlot(index: index, item: item, rect: rect);
    final child = createItem(index: index, item: item, rect: rect);
    if (child != null) {
      _children.add(child);
    }
    _slots.add(slot);
    _relationship[slot.key] = child?.key;

    if (update) {
      _updateSlots();
      setState(() {});
    }
  }

  insertSlot(int index, T? item, {bool update = true}) {
    print('insertSlot $index');
    items.insert(index, item);
    final entry = _create(index, item);
    if (entry.value != null) {
      _children.add(entry.value!);
    }
    _slots.insert(index, entry.key);
    final keys = _relationship.keys.toList();
    final values = _relationship.values.toList();
    keys.insert(index, entry.key.key);
    values.insert(index, entry.value?.key);
    final Iterable<
        MapEntry<GlobalKey<DraggableSlot2State<T>>,
            GlobalKey<DraggableWidgetState<T>>?>> entries = Iterable.generate(
      keys.length,
      (index) => MapEntry(keys[index], values[index]),
    );

    _relationship
      ..clear()
      ..addEntries(entries);
    if (update) {
      _updateSlots();
      setState(() {});
    }
  }

  replaceSlot(int index, T? item) {
    items[index] = item;
    final key = _relationship.keys.elementAt(index);
    if (_relationship[key] != null) {
      _children.remove(_relationship[key]!.currentWidget);
    }
    final child =
        createItem(index: index, item: item, rect: key.currentState!.rect);
    if (child != null) {
      _children.add(child);
    }
    _relationship[key] = child?.key;
    setState(() {});
  }

  MapEntry<DraggableSlot2<T>, DraggableWidget<T>?> _create(int index, T? item) {
    final Rect rect = calcSlotRect(index: index, layoutWidth: layoutWidth);
    final slot = createSlot(index: index, item: item, rect: rect);
    final child = createItem(index: index, item: item, rect: rect);
    return MapEntry(slot, child);
  }
}
