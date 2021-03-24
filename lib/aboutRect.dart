import 'package:draggable_container/utils.dart';
import 'package:flutter/widgets.dart';

/// 关于rect的计算放在这里
mixin AboutRect {
  final List<Rect> _slots = [];
  late Size _itemSize;
  late double _crossSpacing, _mainSpacing;

  double get containerHeight {
    if (_slots.isEmpty) return 0;
    return _slots.last.bottom + _itemSize.height;
  }

  @protected
  Size get itemSize => this._itemSize;

  @protected
  clearCaches() {
    _slots.clear();
  }

  @protected
  buildSlotRectCaches(Iterable<BuildContext> list) {
    // print('buildSlotRectCaches ${list.length}');
    _slots
      ..clear()
      ..addAll(list.map((context) => getRect(context)));
    // print('buildSlotRectCaches $_slots');
  }

  @protected
  int findSlotByOffset(Offset offset) {
    // print('slots $offset \n ${_slots.join('\n')} ');
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i].contains(offset)) return i;
    }
    return -1;
  }

  // 根据index计算slot的坐标和大小
  @protected
  Rect calcSlotRect({
    required int index,
    required double layoutWidth,
  }) {
    final double width = _itemSize.width, height = _itemSize.height;
    double lineX = 0, lineY = 0;
    for (var i = 0; i < index; i++) {
      if (index > 0) {
        lineX += width + _crossSpacing;
        if ((lineX + width > layoutWidth)) {
          lineX = 0;
          lineY += height + _mainSpacing;
        }
      }
    }
    // print('calcSlotRect $index: $lineX,$lineY');
    return Rect.fromLTWH(lineX, lineY, width, height);
  }

  // 根据Delegate计算每个item的大小
  void calcItemSize(SliverGridDelegate delegate, double layoutWidth) {
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
    _itemSize = Size(width.roundToDouble(), height.roundToDouble());
  }
}
