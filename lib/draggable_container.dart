import 'package:draggable_container/slot2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Widget;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'DraggableItemRecognizer.dart';
import 'itemWidget.dart';

typedef Widget NullableItemBuilder<T extends DraggableItem>(
  BuildContext context,
  T? item,
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
  final int itemCount;
  final List<T?>? items;
  final NullableItemBuilder<T> itemBuilder;
  final NullableItemBuilder<T>? deleteButtonBuilder;
  final NullableItemBuilder<T>? slotBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets? padding;
  final Duration animationDuration;
  final Function(int newIndex, int oldIndex)? dragEnd;
  final Function(bool editting)? onEditModeChange;
  final bool? tapOutSizeExitEdieMode;

  const DraggableContainer({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.items,
    this.deleteButtonBuilder,
    this.slotBuilder,
    this.padding,
    this.dragEnd,
    this.onEditModeChange,
    this.tapOutSizeExitEdieMode,
    Duration? animationDuration,
  })  : animationDuration =
            animationDuration ?? const Duration(milliseconds: 200),
        assert(items != null && items.length <= itemCount),
        super(key: key);

  @override
  DraggableContainerState<T> createState() => DraggableContainerState<T>();
}

class DraggableContainerState<T extends DraggableItem>
    extends State<DraggableContainer<T>> with SingleTickerProviderStateMixin {
  final List<T?> items = [];
  final Map<GlobalKey<DraggableSlot2State<T>>, DraggableWidget<T>?>
      _relationship = {};
  final List<DraggableSlot2<T>> _slots = [];
  final List<DraggableWidget<T>> _children = [];
  double layoutWidth = 0;
  final Map<T, Widget> itemCaches = {};

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
  bool _edit = false;

  bool get edit => _edit;

  DraggableWidgetState<T>? pickUp;

  GlobalKey<DraggableSlot2State<T>>? _fromSlot, _toSlot;

  Widget? draggingWidget;
  T? draggingItem;
  GlobalKey<DraggableWidgetState>? draggingKey;
  late Size _itemSize;
  Size get itemSize => _itemSize;
  late double _mainSpacing, _crossSpacing;
  double _maxHeight = 0;
  late bool _tapOutSizeExitEdieMode = widget.tapOutSizeExitEdieMode ?? true;

  bool get tapOutSizeExitEdieMode => this._tapOutSizeExitEdieMode;

  set tapOutSizeExitEdieMode(bool value) =>
      this._tapOutSizeExitEdieMode = value;

  set edit(bool value) {
    _edit = value;
    if (value) {
      // 进入编辑模式
      _createOverlay();
      // _gestures.remove(LongPressGestureRecognizer);
      _gestures[DraggableItemRecognizer] = _draggableItemRecognizer;
    } else {
      // 退出编辑模式
      _removeOverlay();
      _gestures.remove(DraggableItemRecognizer);
      _overlayEntry?.remove();
      // _gestures[LongPressGestureRecognizer] = _longPressRecognizer;
    }
    _relationship.forEach((slot, item) {
      if (item == null) return;
      item.key.currentState?.edit = _edit;
    });
    setState(() {});
    widget.onEditModeChange?.call(_edit);
  }

  OverlayEntry? _overlayEntry;
  void _createOverlay() {
    _overlayEntry?.remove();
    if (!_tapOutSizeExitEdieMode) return;
    final rect = _getRect(context);
    _overlayEntry = new OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (e) {
                if (rect.contains(e.position) == false && pickUp == null) {
                  edit = false;
                }
              },
            ),
            // Positioned.fromRect(
            //   rect: rect,
            //   child: Container(
            //     color: Colors.yellow.withOpacity(0.3),
            //   ),
            // ),
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
    _relationship.clear();
    final positions = getPositions();
    List.generate(widget.itemCount, (index) {
      final item = widget.items?[index];
      final slotKey = GlobalKey<DraggableSlot2State<T>>();
      final Rect rect = Rect.fromLTWH(
        positions[index].dx,
        positions[index].dy,
        _itemSize.width,
        _itemSize.height,
      );
      final slot = createSlot(index, slotKey, item, rect);
      DraggableWidget<T>? child;
      if (item != null) {
        child = createItem(GlobalKey<DraggableWidgetState<T>>(), item, rect);
        _children.add(child);
      }
      _relationship[slotKey] = child;
      _slots.add(slot);
    });
  }

  void _updateSlots() {
    final keys = _relationship.keys.toList();
    final values = _relationship.values.toList();
    final positions = getPositions();
    for (var index = 0; index < keys.length; index++) {
      final rect = Rect.fromLTWH(
        positions[index].dx,
        positions[index].dy,
        _itemSize.width,
        _itemSize.height,
      );
      keys[index].currentState?.updateRect(rect);
      final DraggableWidget? child = values[index];
      child?.key.currentState?.rect = rect;
    }
  }

  DraggableWidget<T> createItem(
      GlobalKey<DraggableWidgetState<T>> key, T item, Rect rect) {
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
    return DraggableWidget(
      key: key,
      rect: rect,
      item: item,
      duration: widget.animationDuration,
      child: widget.itemBuilder(context, item),
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
    return findItemWithPosition(globalPosition)?.item.fixed() == false;
  }

  DraggableWidgetState<T>? findItemWithPosition(Offset globalPosition) {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance!.hitTest(result, globalPosition);
    print('path length ${result.path.length}');
    for (HitTestEntry entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        final data = target.metaData;
        print('hit $pickUp $data');
        if (data is DraggableWidgetState<T> && data != pickUp) {
          return data;
        } else if (data is DeleteItemButton) {
          return null;
        }
      }
    }
  }

  MapEntry<GlobalKey<DraggableSlot2State<T>>, DraggableWidget<T>?>?
      findSlotWithPosition(Offset globalPosition) {
    for (var entry in _relationship.entries) {
      if (_getRect(entry.key.currentContext!).contains(globalPosition))
        return entry;
    }
  }

  Rect _getRect(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  onPanStart(DragStartDetails _) {
    pickUp = findItemWithPosition(_.globalPosition);
    print('panStart $pickUp');
    if (pickUp != null) {
      _children.remove(pickUp!.widget);
      pickUp!.dragging = true;
      _fromSlot = findSlotFromItemWidget(pickUp!.widget);
      setState(() {});
    }
  }

  Offset? startPosition;

  onPanUpdate(DragUpdateDetails _) {
    if (pickUp != null) {
      final entry = findSlotWithPosition(_.globalPosition);
      if (entry != null) {
        final slot = entry.key;
        final value = entry.value;
        if (value == null || value.item.fixed() == false) {
          _toSlot = slot;
        }
      }
      // print('移动抓起的item ${_.delta}');
      final rect = pickUp!.rect;
      pickUp!.rect = Rect.fromLTWH(
        rect.left + _.delta.dx,
        rect.top + _.delta.dy,
        rect.width,
        rect.height,
      );
    }
  }

  onPanEnd(_) {
    if (pickUp != null) {
      _children.add(pickUp!.widget);
      pickUp!.dragging = false;
      pickUp!.rect =
          _toSlot?.currentState!.rect ?? _fromSlot!.currentState!.rect;
      pickUp = null;
      _toSlot = null;
      setState(() {});
    }
  }

  late Offset longPressPosition;

  onLongPressStart(LongPressStartDetails _) {
    // print('onLongPressStart');
    edit = true;
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
            // print('layoutBuild $layoutWidth');
            _itemSize = getItemSize();
            _createSlots();
            _updateSlots();
          }
          final height = constraints.maxHeight == double.infinity
              ? _maxHeight
              : constraints.maxHeight;
          return Container(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ..._slots,
                ..._children,
                if (pickUp != null) pickUp!.widget,
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

  DraggableSlot2<T> createSlot(int index, Key key, T? item, Rect rect) {
    return DraggableSlot2<T>(
      key: key,
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
            child: Text(index.toString()),
          ),
    );
  }

  Size getItemSize() {
    var delegate = widget.gridDelegate;
    double width = 0, height = 0;
    if (delegate is SliverGridDelegateWithFixedCrossAxisCount) {
      _crossSpacing = delegate.crossAxisSpacing;
      _mainSpacing = delegate.mainAxisSpacing;
      width = (layoutWidth - ((delegate.crossAxisCount - 1) * _mainSpacing)) /
          delegate.crossAxisCount;
      height = delegate.mainAxisExtent ?? width * delegate.childAspectRatio;
    } else if (delegate is SliverGridDelegateWithMaxCrossAxisExtent) {
      _crossSpacing = delegate.crossAxisSpacing;
      _mainSpacing = delegate.mainAxisSpacing;
      width = delegate.maxCrossAxisExtent;
      height = delegate.mainAxisExtent ?? width * delegate.childAspectRatio;
    }
    return Size(width, height);
  }

  List<Offset> getPositions() {
    final double width = _itemSize.width, height = _itemSize.height;
    double lineX = 0, lineY = 0;
    final list = List.generate(widget.itemCount, (index) {
      if (index > 0) {
        lineX += width + _crossSpacing;
        if ((lineX + width > layoutWidth)) {
          lineX = 0;
          lineY += height + _mainSpacing;
        }
      }
      // print('$layoutWidth $index:($lineX,$lineY)');
      return Offset(lineX, lineY);
    });
    _maxHeight = lineY + height;
    return list;
  }

  GlobalKey<DraggableSlot2State<T>>? findSlotFromItemWidget(
      DraggableWidget<T>? widget) {
    if (widget == null) return null;
    if (_relationship.containsValue(widget)) {
      final index = _relationship.values.toList().indexOf(widget);
      return _relationship.keys.elementAt(index);
    }
    return null;
  }
}

class DeleteItemButton extends StatelessWidget {
  final Widget child;

  const DeleteItemButton({
    Key? key,
    required this.child,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      child: AbsorbPointer(child: child),
    );
  }
}
