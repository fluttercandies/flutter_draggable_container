import 'dart:math';

import 'package:draggable_container/draggable_container.dart';
import 'package:flutter/material.dart';

class MyItem extends DraggableItem {
  final int index;
  final String key;
  Widget child, deleteButton;
  final Function onTap;

  MyItem({this.key = 'key', this.index, this.onTap}) {
    this.child = GestureDetector(
      onTap: () {
        if (onTap != null) onTap();
      },
      child: Container(
        color: randomColor(),
        child: Center(child: Text(index.toString())),
      ),
    );
  }

  @override
  String toString() => index.toString();

  Map<String, dynamic> toJson() {
    return {key: index};
  }
}

Color randomColor({int min = 150}) {
  final random = Random.secure();
  return Color.fromARGB(255, random.nextInt(255 - min) + min,
      random.nextInt(255 - min) + min, random.nextInt(255 - min) + min);
}
