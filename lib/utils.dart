import 'package:flutter/widgets.dart';

Rect getRect(BuildContext context) {
  final box = context.findRenderObject() as RenderBox;
  final size = box.size;
  final offset = box.localToGlobal(Offset.zero);
  return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
}
