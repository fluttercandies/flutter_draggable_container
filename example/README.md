# Example

```dart
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:draggable_container/draggable_container.dart';

Color randomColor({int min = 150}) {
  final random = Random.secure();
  return Color.fromARGB(255, random.nextInt(255 - min) + min,
      random.nextInt(255 - min) + min, random.nextInt(255 - min) + min);
}

void main() =>
    runApp(MaterialApp(title: 'Draggable Container Demo', home: App()));

class MyItem extends StageItem {
  final int index;
  final String key;
  Widget child, deleteButton;

  MyItem(this.key, this.index) {
    this.child = GestureDetector(
      onTap: () => print('tap $index'),
      child: Container(
        color: randomColor(),
        child: Text(index.toString()),
      ),
    );
    this.deleteButton = Container(
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
  }

  @override
  String toString() => index.toString();

  Map<String, dynamic> toJson() {
    return {key: index};
  }
}

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Draggable Container Demo')),
      body: Column(children: <Widget>[
        Stage(
          // slot decoration
          slotDecoration:
              BoxDecoration(border: Border.all(width: 2, color: Colors.blue)),
          // slot margin
          margin: EdgeInsets.all(5),
          // the decoration when dragging item
          dragDecoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)]),
          // item size
          itemSize: Size(100, 100),
          // item list
          children: [
            ...List.generate(8, (i) => MyItem('item $i', i)),
            StageItem(
              fixed: true,
              deletable: false,
              child: RaisedButton.icon(
                  color: Colors.blue,
                  onPressed: () {
                    print('Clicked a button');
                  },
                  textColor: Colors.white,
                  icon: Icon(
                    Icons.add,
                    size: 20,
                  ),
                  label: Text('Add')),
            )
          ],
          onChanged: (items) {
            final res = items.where((item) => item is MyItem).toList();
            print('onChanged\nstring: $res\njson: ${json.encode(res)}');
          },
        ),
      ]),
    );
  }
}

```