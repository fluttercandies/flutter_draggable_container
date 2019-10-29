import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_draggable_container/draggable_container.dart';
//import 'package:oktoast/oktoast.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: "draggable_container://add",
    routeName: "add",
    description: "show how to add item with draggable_container")
class AddDemo extends StatefulWidget {
  @override
  _AddDemoState createState() => _AddDemoState();
}

class _AddDemoState extends State<AddDemo> {
  final GlobalKey<DraggableContainerState> _containerKey = GlobalKey();
  DraggableItem _addButton;
  int _count = 0;
  List<DraggableItem> items;

  @override
  void initState() {
    super.initState();
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

    items = [
      MyItem(index: 111),
      _addButton,
      ...List.generate(7, (i) => null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
//             showToast(
//                 'Items changed\nraw: $items\njson: ${json.encode(finalItems)}');
              final nullIndex = items.indexOf(null);
              final buttonIndex = items.indexOf(_addButton);
              print('$nullIndex $buttonIndex');
              if (buttonIndex == -1 &&
                  (nullIndex != -1 && nullIndex != buttonIndex)) {
                _containerKey.currentState
                    .deleteItem(_addButton, triggerEvent: false);
                _containerKey.currentState
                    .insteadOfIndex(nullIndex, _addButton, triggerEvent: false);
              }
            },
          ),
        ),
      ),
    );
  }
}
