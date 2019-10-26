# Example

```dart
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:draggable_container/draggable_container.dart';

void main() =>
    runApp(MaterialApp(title: 'Draggable Container Demo', home: App()));

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Draggable Container Demo')),
      body: Column(children: <Widget>[
        RaisedButton(
          child: Text('Demo 1'),
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => DemoWidget()));
          },
        )
      ]),
    );
  }
}

Color randomColor({int min = 150}) {
  final random = Random.secure();
  return Color.fromARGB(255, random.nextInt(255 - min) + min,
      random.nextInt(255 - min) + min, random.nextInt(255 - min) + min);
}

class MyItem extends DraggableItem {
  final int index;
  final String key;
  Widget child, deleteButton;
  final Function onTap;

  MyItem({this.key, this.index, this.onTap}) {
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
      body: ListView(children: <Widget>[
        Card(
            child: Container(
                padding: EdgeInsets.all(10),
                child: Text('DraggableContainer In ListView'))),
        Card(
          child: Container(
            width: 500,
            height: 500,
            child: DraggableContainer(
              editMode: true,
              // slot decoration
              slotDecoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.blue)),
              // slot margin
              slotMargin: EdgeInsets.all(5),
              // the decoration when dragging item
              dragDecoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)]),
              // item size
              slotSize: Size(100, 100),
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
                DraggableItem(
                  fixed: false,
                  deletable: false,
                  child: Container(
                      child: RaisedButton.icon(
                          color: Colors.transparent,
                          onPressed: () {
                            showSnackBar('Clicked the fixed item');
                          },
                          textColor: Colors.white,
                          icon: Icon(
                            Icons.add,
                            size: 20,
                          ),
                          label: Text('Add'))),
                )
              ],
              onChanged: (items) {
                final res = items.where((item) => item is MyItem).toList();
                showSnackBar(
                    'Items changed\nraw: $items\njson: ${json.encode(res)}');
              },
              onEditModeChanged: (bool editMode) {
                if (editMode) return showSnackBar('Enter edit mode');
                showSnackBar('Exit edit mode');
              },
            ),
          ),
        ),
        Card(
          child: Container(
            height: 1000,
          ),
        ),
      ]),
    );
  }
}
```