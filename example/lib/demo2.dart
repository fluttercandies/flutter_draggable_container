import 'package:flutter/material.dart';

import 'package:draggable_container/draggable_container.dart';
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
                final buttonIndex =
                    _containerKey.currentState.items.indexOf(_addButton);
                if (buttonIndex > -1) {
                  _containerKey.currentState.insteadOfIndex(buttonIndex,
                      MyItem(key: _count.toString(), index: _count));
                  _count++;
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
              final nullIndex = items.indexOf(null);
              final buttonIndex = items.indexOf(_addButton);
              print('null $nullIndex, button $buttonIndex');
              if (nullIndex > -1 && buttonIndex == -1) {
                _containerKey.currentState
                    .insteadOfIndex(nullIndex, _addButton, triggerEvent: false);
              } else if (nullIndex > -1 && buttonIndex > -1) {
                _containerKey.currentState
                    .moveTo(buttonIndex, nullIndex, triggerEvent: false);
              }
            },
          ),
        ),
      ),
    );
  }
}
