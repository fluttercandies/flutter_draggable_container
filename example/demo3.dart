import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../lib/draggable_container.dart';

Color randomColor({int min = 150}) {
  final random = Random.secure();
  return Color.fromARGB(255, random.nextInt(255 - min) + min,
      random.nextInt(255 - min) + min, random.nextInt(255 - min) + min);
}

enum ConfirmAction { CANCEL, ACCEPT }

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

class DemoWidget3 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DemoWidget3();
}

class _DemoWidget3 extends State<DemoWidget3> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final GlobalKey<DraggableContainerState> _containerKey = GlobalKey();
  DraggableItem _addButton;
  int _count = 0;

  initState() {
    super.initState();
    _addButton = DraggableItem(
      fixed: true,
      deletable: false,
      child: Container(
          child: RaisedButton.icon(
              color: Colors.orange,
              onPressed: () {
                if (_containerKey.currentState
                    .addItem(MyItem(key: _count.toString(), index: _count))) {
                  _count++;
                } else {
                  showSnackBar(
                      'It\'s full, remove this button and add the last item');
                  _containerKey.currentState
                      .deleteItem(_addButton);
                  _containerKey.currentState
                      .addItem(MyItem(key: _count.toString(), index: _count));
                }
              },
              textColor: Colors.white,
              icon: Icon(
                Icons.add_box,
                size: 20,
              ),
              label: Text(
                'Add',
                style: TextStyle(fontSize: 12),
              ))),
    );
  }

  _showDialog(int index, item) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text('Delete the ${index}th item?'),
          actions: <Widget>[
            FlatButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void showSnackBar(String text) {
    _key.currentState.hideCurrentSnackBar();
    _key.currentState.showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

  Widget build(BuildContext context) {
    final items = [
      ...List.generate(8, (i) => null),
      _addButton,
    ];
    return Scaffold(
      key: _key,
      appBar: AppBar(title: Text('Demo 3')),
      body: Card(
        child: Container(
          width: 500,
          height: 330,
          child: DraggableContainer(
            key: _containerKey,
//              draggableMode: true,
            autoReorder: true,
//              allWayUseLongPress: true,
            // slot decoration
            slotDecoration:
                BoxDecoration(border: Border.all(width: 2, color: Colors.blue)),
            // the decoration when dragging item
            dragDecoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)]),
            // slot margin
            slotMargin: EdgeInsets.all(5),
            // the slot size
            slotSize: Size(100, 100),
            // item list
            items: items,
            onChanged: (items) {
              final finalItems = items.where((item) => item is MyItem).toList();
              showSnackBar(
                  'Items changed\nraw: $items\njson: ${json.encode(finalItems)}');
              if (finalItems.length == 8)
                _containerKey.currentState
                    .addItem(_addButton);
            },
            onDraggableModeChanged: (bool draggableMode) {
              if (draggableMode)
                return showSnackBar('Enter the draggable mode');
              showSnackBar('Exit the draggable mode');
            },
            onBeforeDelete: (int index, item) => _showDialog(index, item),
          ),
        ),
      ),
    );
  }
}
