import 'package:flutter/material.dart';

import 'package:draggable_container/draggable_container.dart';
import 'utils.dart';

class Demo2 extends StatefulWidget {
  @override
  _DemoWidget2 createState() => _DemoWidget2();

  void loadAssets() async {
    Future.delayed(Duration(microseconds: 500));
  }
}

class _DemoWidget2 extends State<Demo2> {
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
              onPressed: () async {
                final items = _containerKey.currentState.items;
                final buttonIndex = items.indexOf(_addButton),
                    nullIndex = items.indexOf(null);

                /// use new item to instead of the button position
                if (buttonIndex > -1) {
                  await _containerKey.currentState.insteadOfIndex(
                      buttonIndex, MyItem(index: _count),
                      force: true, triggerEvent: false);
                  _count++;

                  /// use the button instead of the first null position
                  if (nullIndex > -1) {
                    await _containerKey.currentState.insteadOfIndex(
                        nullIndex, _addButton,
                        force: true, triggerEvent: false);
                  }
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
                // onDragEnd: () {
                //   _containerKey.currentState.draggableMode = false;
                // },
                onChanged: (items) async {
                  final nullIndex = items.indexOf(null);
                  final buttonIndex = items.indexOf(_addButton);
                  if (nullIndex > -1) {
                    if (buttonIndex == -1) {
                      await _containerKey.currentState.insteadOfIndex(
                          nullIndex, _addButton,
                          triggerEvent: false);
                    } else if (nullIndex < buttonIndex) {
                      _containerKey.currentState
                          .moveTo(buttonIndex, nullIndex, triggerEvent: false);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
