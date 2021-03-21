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
  final Map<GlobalKey<DraggableSlot2State<T>>,
      GlobalKey<DraggableWidgetState<T>>?> _relationship = {};
  final List<DraggableSlot2<T>> _slots = [];
  final List<Widget> _children = [];
  double layoutWidth = 0;
  final Map<T, Widget> itemCaches = {};
  Widget? setTop;

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
        return pickUp != null;
      }
      ..onPanStart = onPanStart
      ..onPanUpdate = onPanUpdate
      ..onPanEnd = onPanEnd;
  });

  bool _edit = false;

  bool get edit => _edit;

  GlobalKey<DraggableWidgetState>? pickUp;

  GlobalKey<DraggableSlot2State>? _fromSlot, _toSlot;

  Widget? draggingWidget;
  T? draggingItem;
  GlobalKey<DraggableWidgetState>? draggingKey;
  Size? itemSize;
  late double mainSpacing, crossSpacing;
  double _maxHeight = 0;

  set edit(bool value) {
    _edit = value;
    _relationship.forEach((slot, item) {});
    if (value) {
      _gestures.remove(LongPressGestureRecognizer);
      _gestures[DraggableItemRecognizer] = _draggableItemRecognizer;
    } else {
      _gestures.remove(DraggableItemRecognizer);
      _gestures[LongPressGestureRecognizer] = _longPressRecognizer;
    }
    setState(() {});
  }

  bool _created = false;

  createSlots() {
    if (_created) return;
    _created = true;
    _slots.clear();
    _relationship.clear();
    final positions = getPositions();
    List.generate(widget.itemCount, (index) {
      final item = widget.items?[index];
      final slotKey = GlobalKey<DraggableSlot2State<T>>();
      final slot = createSlot(index, slotKey, item, positions[index]);
      var child;
      if (item != null) {
        child = GlobalKey<DraggableWidgetState<T>>();
        _children.add(
          createItem(
            child,
            item,
            Rect.fromLTWH(
              positions[index].dx,
              positions[index].dy,
              itemSize!.width,
              itemSize!.height,
            ),
          ),
        );
      }
      _relationship[slotKey] = child;
      _slots.add(slot);
    });
  }

  void updateSlots() {
    final keys = _relationship.keys.toList();
    final positions = getPositions();
    for (var index = 0; index < keys.length; index++) {
      keys[index].currentState?.updateRect(
            Rect.fromLTWH(
              positions[index].dx,
              positions[index].dy,
              itemSize!.width,
              itemSize!.height,
            ),
          );
      final child = _relationship[keys[index]];
      child?.currentState?.size = itemSize!;
      child?.currentState?.offset = positions[index];
    }
  }

  Widget createItem(GlobalKey<DraggableWidgetState> key, T item, Rect rect) {
    return DraggableWidget(
      key: key,
      rect: rect,
      child: widget.itemBuilder(context, item),
      item: item,
      duration: widget.animationDuration,
    );
  }

  GlobalKey<DraggableSlot2State<T>>? findSlotFromOffset(Offset globalPosition) {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance!.hitTest(result, globalPosition);
    for (HitTestEntry entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        final metaData = target.metaData;
        if (metaData is GlobalKey<DraggableSlot2State<T>>) {
          return metaData;
        }
      }
    }
  }

  bool isHitItem(Offset globalPosition) {
    return findItemWithPosition(globalPosition)?.currentState?.item.fixed() ==
        false;
  }

  GlobalKey<DraggableWidgetState<T>>? findItemWithPosition(
      Offset globalPosition) {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance!.hitTest(result, globalPosition);
    for (HitTestEntry entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        print(entry.target);
        final data = target.metaData;
        if (data is GlobalKey<DraggableWidgetState<T>>) {
          return data;
        }
      }
    }
  }

  onPanStart(DragStartDetails _) {
    final slot = _toSlot = findSlotFromItemWidget(_.globalPosition);
    pickUp = _relationship[slot];
    print('panStart ${slot}');
    if (pickUp != null) {
      setState(() {});
    }
  }

  Offset? startPosition;

  onPanUpdate(DragUpdateDetails _) {
    if (draggingKey != null) {
      // 移动抓起的item
      print('移动抓起的item ${draggingKey}');
    }
  }

  onPanEnd(_) {
    // pickUp?.currentState?.position = _toSlot!.rect.topLeft;
    pickUp?.currentState?.dragging = false;
    pickUp = null;
  }

  late Offset longPressPosition;

  onLongPressStart(LongPressStartDetails _) {
    edit = true;
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
    Widget child = RawGestureDetector(
      gestures: _gestures,
      child: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          final _layoutWidth = constraints.maxWidth == double.infinity
              ? MediaQuery.of(context).size.width
              : constraints.maxWidth;
          if (_layoutWidth != layoutWidth) {
            layoutWidth = _layoutWidth;
            // print('layoutBuild $layoutWidth');
            itemSize = getItemSize();
            createSlots();
            updateSlots();
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
                if (setTop != null) setTop!,
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

  DraggableSlot2<T> createSlot(int index, Key key, T? item, Offset offset) {
    return DraggableSlot2<T>(
      key: key,
      item: item,
      rect: Rect.fromLTWH(
          offset.dx, offset.dy, itemSize!.width, itemSize!.height),
      slot: widget.slotBuilder?.call(context, item) ??
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
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
      crossSpacing = delegate.crossAxisSpacing;
      mainSpacing = delegate.mainAxisSpacing;
      width = (layoutWidth - ((delegate.crossAxisCount - 1) * mainSpacing)) /
          delegate.crossAxisCount;
      height = delegate.mainAxisExtent ?? width * delegate.childAspectRatio;
    } else if (delegate is SliverGridDelegateWithMaxCrossAxisExtent) {
      crossSpacing = delegate.crossAxisSpacing;
      mainSpacing = delegate.mainAxisSpacing;
      width = delegate.maxCrossAxisExtent;
      height = delegate.mainAxisExtent ?? width * delegate.childAspectRatio;
    }
    return Size(width, height);
  }

  List<Offset> getPositions() {
    final double width = itemSize!.width, height = itemSize!.height;
    double lineX = 0, lineY = 0;
    final list = List.generate(widget.itemCount, (index) {
      if (index > 0) {
        lineX += width + crossSpacing;
        if ((lineX + width >= layoutWidth)) {
          lineX = 0;
          lineY += height + mainSpacing;
        }
      }
      // print('$layoutWidth $index:($lineX,$lineY)');
      return Offset(lineX, lineY);
    });
    _maxHeight = lineY + height;
    return list;
  }

  GlobalKey<DraggableSlot2State<T>>? findSlotFromItemWidget(
      Offset globalPosition) {
    final itemKey = findItemWithPosition(globalPosition);
    if (itemKey == null) return null;
    if (_relationship.containsValue(itemKey)) {
      final index = _relationship.values.toList().indexOf(itemKey);
      return _relationship.keys.elementAt(index);
    }
    return null;
  }
}
