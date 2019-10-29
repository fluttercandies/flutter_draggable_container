import 'dart:convert';

import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_draggable_container/draggable_container.dart';
import 'package:oktoast/oktoast.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: "draggable_container://listview",
    routeName: "listView",
    description: "show how to use DraggableContainer in ListView")
class ListViewDemo extends StatefulWidget {
  @override
  _ListViewDemoState createState() => _ListViewDemoState();
}

class _ListViewDemoState extends State<ListViewDemo> {
  final items = [
    ...List.generate(
        4,
        (i) => MyItem(
            key: 'item $i',
            index: i,
            onTap: () {
              showToast('Clicked the ${i}th item');
            })),
    DraggableItem(
      fixed: true,
      deletable: false,
      child: Container(
          child: RaisedButton.icon(
              color: Colors.transparent,
              onPressed: () {
                showToast('Clicked the fixed item');
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
              showToast('Clicked the ${i}th item');
            });
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Re-entry will reset')),
      body: ListView(children: <Widget>[
        Card(
            child: Container(
                padding: EdgeInsets.all(10),
                child: Text('DraggableContainer in ListView'))),
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
                showToast(
                    'Items changed\nraw: $items\njson: ${json.encode(res)}');
              },
              onDraggableModeChanged: (bool draggableMode) {
                if (draggableMode) showToast('Enter the draggable mode');
                showToast('Exit the draggable mode');
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
