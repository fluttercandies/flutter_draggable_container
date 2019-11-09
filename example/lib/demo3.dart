import 'package:draggable_container/draggable_container.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class DemoWidget3 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DemoWidget3();
}

class _DemoWidget3 extends State<DemoWidget3> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final GlobalKey<DraggableContainerState> _containerKey = GlobalKey();
  DraggableItem _addButton;
  int _count = 8;

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
                    .addItem(MyItem(key: _count.toString(), index: _count)))
                  _count++;
                else
                  showSnackBar('It\'s full');
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
      ...List.generate(8, (i) => MyItem(index: i)),
      _addButton,
    ];
    return Scaffold(
      key: _key,
      appBar: AppBar(title: Text('Demo 3')),
      body: Card(
        child: Container(
          child: DraggableContainer(
            key: _containerKey,
//              draggableMode: true,
            autoReorder: true,
            allWayUseLongPress: true,
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
            onBeforeDelete: (int index, item) => _showDialog(index, item),
          ),
        ),
      ),
    );
  }
}
