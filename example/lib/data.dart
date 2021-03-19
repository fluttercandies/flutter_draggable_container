import 'dart:math';

import 'package:flutter/material.dart';

const _colors = Colors.accents;

Color randomColor() {
  final _random = new Random();
  return _colors[_random.nextInt(_colors.length)];
}
