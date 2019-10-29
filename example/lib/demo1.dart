import 'dart:convert';

import 'package:draggable_container/draggable_container.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class DemoWidget extends StatelessWidget {
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  void showSnackBar(String text) {
    _key.currentState.hideCurrentSnackBar();
    _key.currentState.showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

  Widget build(BuildContext context) {
    final items = [
      ...List.generate(
          4,
          (i) => MyItem(
              key: 'item $i',
              index: i,
              onTap: () {
                showSnackBar('Clicked the ${i}th item');
              })),
      DraggableItem(
        fixed: true,
        deletable: false,
        child: Container(
            child: RaisedButton.icon(
                color: Colors.transparent,
                onPressed: () {
                  showSnackBar('Clicked the fixed item');
                },
                textColor: Colors.white,
                icon: Icon(
                  Icons.lock,
                  size: 20,
                ),
                label: Text(
                  'Locked',
                  style: TextStyle(fontSize: 12),
                ))),
      ),
      ...List.generate(
        4,
        (i) {
          i += 5;
          return MyItem(
              key: 'item $i',
              index: i,
              onTap: () {
                showSnackBar('Clicked the ${i}th item');
              });
        },
      ),
    ];
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
            child: DraggableContainer(
//              draggableMode: true,
              autoReorder: true,
//              allWayUseLongPress: true,
              // slot decoration
              slotDecoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.blue)),
              // the decoration when dragging item
              dragDecoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)]),
              // slot margin
              slotMargin: EdgeInsets.all(5),
              // the slot size
              slotSize: Size(100, 100),
              // when undefined, use the red background white icon button.
              deleteButton: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              // item list
              items: items,
              onChanged: (items) {
                final res = items.where((item) => item is MyItem).toList();
                showSnackBar(
                    'Items changed\nraw: $items\njson: ${json.encode(res)}');
              },
              onDraggableModeChanged: (bool draggableMode) {
                if (draggableMode)
                  return showSnackBar('Enter the draggable mode');
                showSnackBar('Exit the draggable mode');
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
