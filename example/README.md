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
  final Function onTap;
  Widget child;

  MyItem(this.key, this.index, this.onTap) {
    this.child = GestureDetector(
      onTap: () => onTap(),
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

class DemoWidget extends StatelessWidget {
  GlobalKey<ScaffoldState> _key = GlobalKey();

  void showSnackBar(String text) {
    _key.currentState.hideCurrentSnackBar();
    _key.currentState.showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(title: Text('Re-entry will reset')),
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
          deleteButton: Container(
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
          ),
          // item list
          children: [
            ...List.generate(
                8,
                (i) => MyItem('item $i', i, () {
                      showSnackBar('Clicked the ${i}th item');
                    })),
            StageItem(
              fixed: true,
              deletable: false,
              child: RaisedButton.icon(
                  color: Colors.blue,
                  onPressed: () {
                    showSnackBar('Clicked the fixed item');
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
            showSnackBar('Items Changed\njson: ${json.encode(res)}');
          },
          onEditModeChanged: (bool editMode) {
            if (editMode) return showSnackBar('Enter edit mode');
            showSnackBar('Exit edit mode');
          },
        ),
      ]),
    );
  }
}

```