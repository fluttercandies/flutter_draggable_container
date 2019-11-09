import 'package:flutter/material.dart';

import 'package:draggable_container/draggable_container.dart';
import 'utils.dart';

class DemoWidget2 extends StatefulWidget {
  @override
  _DemoWidget2 createState() => _DemoWidget2();

  void loadAssets() async {
    Future.delayed(Duration(microseconds: 500));
  }
}

class _DemoWidget2 extends State<DemoWidget2> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final GlobalKey<DraggableContainerState> _containerKey = GlobalKey();
  final items = <DraggableItem>[];
  DraggableItem _addButton;
  int _count = 0;

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
                final nullIndex =
                    _containerKey.currentState.items.indexOf(null);
                print('add $nullIndex $buttonIndex');
                if (nullIndex > -1 && buttonIndex > -1) {
                  _containerKey.currentState
                      .moveTo(buttonIndex, nullIndex, triggerEvent: false);
                }
                if (buttonIndex > -1) {
                  _containerKey.currentState.insteadOfIndex(buttonIndex,
                      MyItem(key: _count.toString(), index: _count),
                      force: true, triggerEvent: false);
                  _count++;
                }
              },
              textColor: Colors.white,
              icon: Icon(Icons.add_box, size: 20),
              label: Text('Add', style: TextStyle(fontSize: 12)))),
    );

    items.addAll([
      MyItem(index: 111),
      _addButton,
      ...List.generate(7, (i) => null),
    ]);
  }

  void showSnackBar(String text) {
    _key.currentState.hideCurrentSnackBar();
    _key.currentState.showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(title: Text('Demo 2')),
      body: ListView(
        children: [
          Card(
            child: Container(
              child: DraggableContainer(
                key: _containerKey,
                draggableMode: false,
                autoReorder: true,
                // allWayUseLongPress: true,
                // slot decoration
                slotDecoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.blue)),
                // the decoration when dragging item
                dragDecoration: BoxDecoration(boxShadow: [
                  BoxShadow(color: Colors.black, blurRadius: 10)
                ]),
                // slot margin
                slotMargin: EdgeInsets.all(5),
                // the slot size
                slotSize: Size(100, 100),
                // item list
                items: items,
                onDragEnd: () {
                  _containerKey.currentState.draggableMode = false;
                },
                onChanged: (items) {
                  final nullIndex = items.indexOf(null);
                  final buttonIndex = items.indexOf(_addButton);
                  // print('null $nullIndex, button $buttonIndex');
                  if (nullIndex > -1 && buttonIndex == -1) {
                    _containerKey.currentState.insteadOfIndex(
                        nullIndex, _addButton,
                        triggerEvent: false);
                  } else if (nullIndex > -1 &&
                      buttonIndex > -1 &&
                      nullIndex < buttonIndex) {
                    _containerKey.currentState
                        .moveTo(buttonIndex, nullIndex, triggerEvent: false);
                  }
                },
              ),
            ),
          ),
          Card(
            child: FlatButton(
              onPressed: () {
                items.add(DraggableItem(child: Text('hi')));
                print('length ${items.length}');
                setState(() {});
              },
              child: Text('增加Item'),
            ),
          ),
        ],
      ),
    );
  }
}
