import 'dart:convert';

import 'package:draggable_container/draggable_container.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class Demo4 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DemoWidget3();
}

class _DemoWidget3 extends State<Demo4> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final GlobalKey<DraggableContainerState> _containerKey = GlobalKey();
  int _count = 0;
  DraggableItem _addButton;

  void showSnackBar(String text) {
    _key.currentState.hideCurrentSnackBar();
    _key.currentState.showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

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
                    .addItem(MyItem(index: _count)))
                  _count++;
                else
                  showSnackBar(
                      'The container is full, you can add slots and add items');
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

  Widget build(BuildContext context) {
    final items = [_addButton];
    return Scaffold(
      key: _key,
      appBar: AppBar(title: Text('Demo 4')),
      body: ListView(children: [
        Card(
          child: Container(
            child: DraggableContainer(
              key: _containerKey,
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
              // item list
              items: items,
              onChanged: (items) {
                final res = items.where((item) => item is MyItem).toList();
                showSnackBar(
                    'Items changed\nraw: $items\njson: ${json.encode(res)}');
              },
            ),
          ),
        ),
      ]),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        RaisedButton(
          child: Text('Add Slot'),
          onPressed: () async {
            await _containerKey.currentState.addSlot();
            print('addslot success');
          },
        ),
        RaisedButton(
          child: Text('Remove the last slot'),
          onPressed: () {
            if (_containerKey.currentState.relationship.keys.length == 1)
              return this.showSnackBar('Can not delete the add button');
            _containerKey.currentState.popSlot();
          },
        ),
      ]),
    );
  }
}
