import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_draggable_container/draggable_container.dart';
import 'package:oktoast/oktoast.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: "draggable_container://delete",
    routeName: "delete",
    description: "show how to delete item with draggable_container")
class DeleteDemo extends StatefulWidget {
  @override
  _DeleteDemoState createState() => _DeleteDemoState();
}

class _DeleteDemoState extends State<DeleteDemo> {
  final GlobalKey<DraggableContainerState> _containerKey = GlobalKey();
  DraggableItem _addButton;
  int _count = 8;
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
                if (_containerKey.currentState
                    .addItem(MyItem(key: _count.toString(), index: _count)))
                  _count++;
                else
                  showToast('It\'s full');
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
    items = [
      ...List.generate(8, (i) => MyItem(index: i)),
      _addButton,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('delete demo')),
      body: Card(
        child: Container(
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
            onBeforeDelete: (int index, item) => _showDialog(index, item),
          ),
        ),
      ),
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
}
