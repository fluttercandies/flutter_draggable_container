import 'package:flutter/material.dart';

import '../lib/draggable_container.dart';
import 'utils.dart';

// ignore: must_be_immutable
class DemoWidget2 extends StatelessWidget {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final GlobalKey<DraggableContainerState> _containerKey = GlobalKey();
  DraggableItem _addButton;
  int _count = 0;

  DemoWidget2() {
    _addButton = DraggableItem(
      fixed: true,
      deletable: false,
      child: Container(
          child: RaisedButton.icon(
              color: Colors.orange,
              onPressed: () {
                if (_containerKey.currentState.deleteItem(_addButton,
                    triggerEvent: false)) print('删除 成功');
                if (_containerKey.currentState
                    .addItem(MyItem(key: _count.toString(), index: _count))) {
                  _count++;
                  print('add success');
                }
              },
              textColor: Colors.white,
              icon: Icon(Icons.add_box, size: 20),
              label: Text('Add', style: TextStyle(fontSize: 12)))),
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
      MyItem(index: 111),
      _addButton,
      ...List.generate(7, (i) => null),
    ];
    return Scaffold(
      key: _key,
      appBar: AppBar(title: Text('Demo 2')),
      body: Card(
        child: Container(
          width: 500,
          height: 330,
          child: DraggableContainer(
            key: _containerKey,
            draggableMode: true,
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
//              final finalItems = items.where((item) => item is MyItem).toList();
//              showSnackBar(
//                  'Items changed\nraw: $items\njson: ${json.encode(finalItems)}');
              final index = items.indexOf(null);
              _containerKey.currentState.deleteItem(_addButton);
              final hasButton = _containerKey.currentState.hasItem(_addButton);
              if (index > -1 && !hasButton) {
                _containerKey.currentState
                    .insteadOfIndex(index, _addButton, triggerEvent: false);
              }
            },
          ),
        ),
      ),
    );
  }
}
