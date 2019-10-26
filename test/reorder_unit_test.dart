import 'dart:core';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import "package:test/test.dart";


///
///
/// Because the flutter unit test without ui system
/// So this file just test the reorder logic
///
///


class DraggableItem {
  final int index;
  final bool fixed;

  const DraggableItem(this.index, {this.fixed: false});

  @override
  String toString() {
    return toJson().toString();
  }

  Map toJson() => {'index': index, 'fixed': fixed};
}

class DraggableSlot {
  final double width, height;
  Offset _position, _maxPosition;

  DraggableSlot({this.width, this.height, Offset position}) {
    this.position = position;
  }

  set position(Offset value) {
    _position = value;
    _maxPosition = _position + Offset(width, height);
  }

  get position => _position;

  get maxPosition => _maxPosition;
}

class DraggableItemWidget {
  final double width, height;
  final DraggableItem item;
  Offset _position, _maxPosition;
  bool active = false;

  DraggableItemWidget({this.width, this.height, this.item, Offset position}) {
    this.position = position;
  }

  set position(Offset value) {
    _position = value;
    _maxPosition = _position + Offset(width, height);
  }

  get position => _position;

  get maxPosition => _maxPosition;
}

class ContainerWidget {
  final List<DraggableItem> items = [];
  final Function(List<DraggableItem> items) onChanged = (items) {};
  final bool autoReorder = true;
  final Function(bool mode) onDraggableModeChanged = (mode) {};
}

class Container {
  final List<DraggableItemWidget> layers = [];
  final Map<DraggableSlot, DraggableItemWidget> relationship = {};
  final Offset itemSize;
  final int itemCount;
  final widget = ContainerWidget();

  bool draggableMode = true;

  Container({this.itemCount, this.itemSize}) {
    init();
  }

  setState(VoidCallback callback) {}

  init() {
    draggableMode = true;
    relationship.clear();
    List.generate(itemCount, (i) {
      final position = itemSize * i.toDouble();
      final slot = DraggableSlot(
        width: itemSize.dx,
        height: itemSize.dy,
        position: position,
      );
      final item = DraggableItem(i, fixed: i == 4);
      final widget = DraggableItemWidget(
        position: position,
        width: itemSize.dx,
        height: itemSize.dy,
        item: item,
      );
      relationship[slot] = widget;
      layers.add(widget);
    });
  }

  bool deleteFromIndex(int index) {
    if (index < 0 || index >= relationship.length) return false;
    final entries = relationship.entries;
    for (var i = 0; i < entries.length; i++) {
      if (i != index) continue;
      final entry = entries.elementAt(i);
      if (entry.value == null) return false;
      relationship[entry.key] = null;
      layers.remove(entry.value);
      widget.items.remove(entry.value.item);
      setState(() {});
      return true;
    }
    return false;
  }

  bool deleteFromItem(DraggableItem item) {
    final entries = relationship.entries;
    for (var kv in entries) {
      if (kv.value?.item == item) {
        relationship[kv.key] = null;
        layers.remove(kv.value);
        widget.items.remove(kv.value.item);
        setState(() {});
        return true;
      }
    }
    return false;
  }

  _triggerOnChanged() {
    if (widget.onChanged != null)
      widget.onChanged(
          relationship.values.map((widget) => widget?.item).toList());
  }

  DraggableItemWidget _pickUp;
  DraggableSlot _fromSlot, _toSlot;
  final List<DraggableItemWidget> _dragBeforeList = [];

  onPanStart(DraggableSlot slot) {
    if (!draggableMode) return;
    final item = relationship[slot];
    if (item == null || item.item.fixed) return;
    _pickUp = item;
    _pickUp.active = true;
    _fromSlot = _toSlot = slot;
    _dragBeforeList.addAll(relationship.values);
    layers.remove(_pickUp);
    layers.add(_pickUp);
    setState(() {});
  }

  onPanEnd() {
    if (_pickUp != null) {
      if (relationship[_toSlot]?.item?.fixed == false) {
        _pickUp.position = _toSlot.position;
      }
      _pickUp.active = false;
    }
    _pickUp = _fromSlot = _toSlot = null;
    if (listEquals(_dragBeforeList, relationship.values.toList()) == false) {
      if (widget.autoReorder) reorder();
      setState(() {});
      // print('changed');
      _triggerOnChanged();
    }
    _dragBeforeList.clear();
  }

  dragTo(DraggableSlot to) {
    if (_fromSlot == null || _pickUp == null) return;
    if (to == _fromSlot || to == _toSlot) return;
    _toSlot = to;
    final slots = relationship.keys.toList();
    final fromIndex = slots.indexOf(_fromSlot), toIndex = slots.indexOf(to);
    final start = math.min(fromIndex, toIndex),
        end = math.max(fromIndex, toIndex);
    final item = relationship[to];
    // 目标是固定位置的，不进行移动操作
    if (item != null && item.item.fixed) {
      return;
    }
    // 前后互相移动
    if (end - start == 1) {
      item.position = _fromSlot.position;
      relationship[_fromSlot] = item;
    }
    // 多个移动
    else {
      // 从前往后拖动
      if (fromIndex == start) {
        relationship[_fromSlot] = null;
        reorder(start: start, end: end + 1);
      }
      // 将后面的item移动到前面
      else {
        DraggableSlot lastSlot = slots[start], currentSlot;
        DraggableItemWidget lastItem = relationship[lastSlot], currentItem;
        for (var i = start + 1; i <= end; i++) {
          currentSlot = slots[i];
          currentItem = relationship[currentSlot];
          print('i: $i ,${currentItem?.item.toString()}');
          if (currentItem?.item?.fixed == true) continue;
          relationship[currentSlot] = lastItem;
          lastItem = currentItem;
          if (lastItem != _pickUp) lastItem?.position = currentSlot.position;
        }
      }
    }
    relationship[_toSlot] = _pickUp;
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
          if (nextItem != _pickUp) nextItem.position = slot.position;
          relationship[nextSlot] = null;
        }
      }
    }
  }

  MapEntry<DraggableSlot, DraggableItemWidget> findNextDraggableItem(
      {start: 0, end: -1}) {
    if (end == -1) end = relationship.length;
    print('findNextDraggableItem start: $start, end: $end');
    var i = start;
    var str = [];

    var res =
        relationship.entries.toList().getRange(start, end).firstWhere((pair) {
      str.add('$i:' + pair?.value?.item.toString());
      i++;
      return pair.value != null && !pair.value.item.fixed;
    }, orElse: () => null);
    print('=========findNextDraggableItem\n' + str.join('\n') + '\n=========');
    return res;
  }
}

void main() {
  final container = Container(itemCount: 9, itemSize: Offset(100, 100));

  /// simulate
  /// [0] [1] [2]
  /// [3] <4> [5]
  /// [6] [7] [8]
  ///
  /// The fourth item was fixed
  group('init', () {
    container.init();
    test('Total is 9', () {
      expect(container.relationship.length, 9);
    });

    test('4th was fixed', () {
      expect(container.layers[4].item.fixed, true);
    });
  });

  group('Find next draggable item', () {
    container.init();
    MapEntry<DraggableSlot, DraggableItemWidget> res;
    test('Looking from beginning, get the frist item', () {
      res = container.findNextDraggableItem();
      expect(res.value.item.index, 0);
    });
    test('Looking from 1, get the second item', () {
      res = container.findNextDraggableItem(start: 1);
      expect(res.value.item.index, 1);
    });
    test('Find in range from 4 to 5, 4 was locked, so get null', () {
      res = container.findNextDraggableItem(start: 4, end: 5);
      expect(res, null);
    });
  });

  /// simulate
  /// [0] [1] [2]
  /// [3] <4> [5]
  /// [6] [7] [8]
  ///
  /// The fourth item was fixed
  group('Exchange two adjacent items', () {
    container.init();
    test('Exchange 1 and 2', () {
      container.init();
      final slots = container.relationship.keys.toList();
      final fromSlot = slots[1], toSlot = slots[2];
      container.onPanStart(fromSlot);
      expect(container._pickUp, container.relationship[fromSlot]);
      container.dragTo(toSlot);
      container.onPanEnd();
      printAll(container.relationship);
      print(container.relationship[fromSlot] ?? 'null');
      expect(
        [
          container.relationship[fromSlot]?.item?.index,
          container.relationship[toSlot]?.item?.index
        ],
        [2, 1],
      );
    });
    test('Exchange 3 and 4, becasue 4 was locked, so move fail', () {
      container.init();
      final slots = container.relationship.keys.toList();
      final fromSlot = slots[3], toSlot = slots[4];
      container.onPanStart(fromSlot);
      container.dragTo(toSlot);
      container.onPanEnd();
      expect(
        [
          container.relationship[fromSlot]?.item?.index,
          container.relationship[toSlot]?.item?.index
        ],
        [3, 4],
      );
    });
    test('Exchange 4 and 5, becasue 4 was locked, so move fail', () {
      container.init();
      final slots = container.relationship.keys.toList();
      final fromSlot = slots[5], toSlot = slots[4];
      container.onPanStart(fromSlot);
      container.dragTo(toSlot);
      container.onPanEnd();
      expect(
        [
          container.relationship[fromSlot]?.item?.index,
          container.relationship[toSlot]?.item?.index
        ],
        [5, 4],
      );
    });
  });

  /// simulate
  /// [0] [1] [2]
  /// [3] <4> [5]
  /// [6] [7] [8]
  ///
  /// The fourth item was fixed
  group('Move across multiple slots, drag from the front to back', () {
    test('Move 0 to 2', () {
      container.init();
      final slots = container.relationship.keys.toList();
      final fromSlot = slots[0], toSlot = slots[2];
      container.onPanStart(fromSlot);
      expect(container._pickUp.item.index, 0);
      container.dragTo(toSlot);
      container.onPanEnd();
      printAll(container.relationship, start: 3, end: 6);
      expect(
        [
          container.relationship[slots[0]].item.index,
          container.relationship[slots[1]].item.index,
          container.relationship[slots[2]].item.index,
        ],
        [1, 2, 0],
      );
    });
    test('Move 3 to 5', () {
      container.init();
      final slots = container.relationship.keys.toList();
      final fromSlot = slots[3], fixedSlot = slots[4], toSlot = slots[5];
      container.onPanStart(fromSlot);
      expect(container._pickUp.item.index, 3);
      container.dragTo(toSlot);
      container.onPanEnd();
      printAll(container.relationship, start: 3, end: 6);
      expect(
        [
          container.relationship[fromSlot]?.item?.index,
          container.relationship[fixedSlot]?.item?.index,
          container.relationship[toSlot]?.item?.index
        ],
        [5, 4, 3],
      );
    });
    test('Move 2 to 7, 3 was null', () {
      container.init();
      container.deleteFromIndex(3);
      final slots = container.relationship.keys.toList();
      final fromSlot = slots[2], fixedSlot = slots[4], toSlot = slots[7];
      container.onPanStart(fromSlot);
      expect(container._pickUp.item.index, 2);
      container.dragTo(toSlot);
      container.onPanEnd();
      printAll(container.relationship);
      expect(
        [
          container.relationship[fromSlot]?.item?.index,
          container.relationship[fixedSlot]?.item?.index,
          container.relationship[toSlot]?.item?.index,
          container.relationship[slots.last]?.item?.index,
        ],
        [5, 4, 8, null],
      );
    });
  });

  /// simulate
  /// [0] [1] [2]
  /// [3] <4> [5]
  /// [6] [7] [8]
  ///
  /// The fourth item was fixed
  group('Move across multiple slots, drag from the back to front', () {
    test('Move 5 to 3', () {
      container.init();
      final slots = container.relationship.keys.toList();
      final fromSlot = slots[5], middleSlot = slots[4], toSlot = slots[3];
      final item5 = container.relationship[fromSlot],
          item4 = container.relationship[middleSlot],
          item3 = container.relationship[toSlot];
      container.onPanStart(fromSlot);
      expect(container._pickUp, item5);
      container.dragTo(toSlot);
      container.onPanEnd();
      print('3 ：' + container.relationship[toSlot]?.item?.toString());
      print('4 ：' + container.relationship[middleSlot]?.item?.toString());
      print('5 ：' + container.relationship[fromSlot]?.item?.toString());

      expect([
        container.relationship[fromSlot],
        container.relationship[middleSlot],
        container.relationship[toSlot]
      ], [
        item3,
        item4,
        item5
      ]);
    });
    test('Move 5 to 3, 3 was null', () {
      container.init();
      expect(container.relationship.length, 9);
      container.deleteFromIndex(3);
      final slots = container.relationship.keys.toList();
      final lockedSlot = slots[4];
      final from = 5, to = 3;
      container.onPanStart(slots[from]);
      expect(container.relationship[slots[3]], null);
      expect(container._pickUp.item.index, from);
      container.dragTo(slots[to]);
      container.onPanEnd();

      printAll(container.relationship);

      expect(
        [
          container.relationship[slots[3]]?.item?.index,
          container.relationship[lockedSlot]?.item?.index,
          container.relationship[slots[5]]?.item?.index
        ],
        [5, 4, 6],
      );
    });
    test('Move 8 to 2, 3 was null', () {
      // reset items
      container.init();
      expect(container.relationship.length, 9);
      container.deleteFromIndex(3);
      final slots = container.relationship.keys.toList();
      final lockedSlot = slots[4];
      final from = 7, to = 2;
      container.onPanStart(slots[from]);
      expect(container.relationship[slots[3]], null);
      expect(container._pickUp, container.relationship[slots[from]]);
      container.dragTo(slots[to]);
      container.onPanEnd();

      printAll(container.relationship);

      expect(
        [
          container.relationship[slots[2]]?.item?.index,
          container.relationship[lockedSlot]?.item?.index,
          container.relationship[slots[7]]?.item?.index
        ],
        [7, 4, 8],
      );
    });
  });
}

printAll(Map<DraggableSlot, DraggableItemWidget> map,
    {int start: 0, int end: -1}) {
  final entries = map.entries;
  if (end == -1) end = entries.length;
  for (var i = start; i < end; i++) {
    print('$i : ${entries.elementAt(i).value?.item.toString()}');
  }
}
