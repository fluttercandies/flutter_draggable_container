import 'package:draggable_container/utils.dart';
import 'package:flutter/widgets.dart';

mixin RectCaches {
  final List<Rect> _slots = [];
  final List<Rect> _items = [];

  @protected
  clearCaches() {
    _slots.clear();
    _items.clear();
  }

  @protected
  buildSlotRectCaches(Iterable<BuildContext> list) {
    _slots
      ..clear()
      ..addAll(list.map((context) => getRect(context)));
  }

  @protected
  buildItemRectCaches(Iterable<BuildContext> list) {
    _items
      ..clear()
      ..addAll(list.map((context) => getRect(context)));
  }

  @protected
  int findSlotByOffset(Offset offset) {
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i].contains(offset)) return i;
    }
    return -1;
  }
}
