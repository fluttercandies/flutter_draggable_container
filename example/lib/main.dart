import 'package:draggable_container/draggable_container.dart';
import 'package:flutter/material.dart';

import 'data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DraggableContainer In ListView',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyItem extends DraggableItem {
  final Color color;
  final int index;
  bool deletable;
  bool fixed;

  MyItem({
    @required this.index,
    this.deletable = true,
    this.fixed = false,
    Color color,
  }) : color = color ?? randomColor();

  @override
  String toString() {
    return '<MyItem> {index:$index, fixed:$fixed, deletable:$deletable}';
  }
}

class AddItem extends DraggableItem {
  @override
  bool get deletable => false;

  @override
  bool get fixed => true;

  @override
  String toString() {
    return '<AddItem> {fixed:$fixed, deletable:$deletable}';
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePage createState() => _MyHomePage();
}

class _MyHomePage extends State<MyHomePage> {
  final data = <DraggableItem>[
    AddItem(),
  ];

  final key = GlobalKey<DraggableContainerState<DraggableItem>>();

  String items = '';
  String delegate = '';
  String settings = '';

  updateText() {
    if (key.currentState != null) {
      Map<String, dynamic> text = {};
      var widget = key.currentWidget as DraggableContainer;
      var _delegate = widget.gridDelegate;
      if (_delegate is SliverGridDelegateWithFixedCrossAxisCount) {
        text['SliverGridDelegateWithFixedCrossAxisCount'] = '';
        text['crossAxisCount'] = _delegate.crossAxisCount;
        text['crossAxisSpacing'] = _delegate.crossAxisSpacing;
        text['mainAxisSpacing'] = _delegate.mainAxisSpacing;
      } else if (_delegate is SliverGridDelegateWithMaxCrossAxisExtent) {
        text['SliverGridDelegateWithMaxCrossAxisExtent'] = '';
        text['maxCrossAxisExtent'] = _delegate.maxCrossAxisExtent;
        text['crossAxisSpacing'] = _delegate.crossAxisSpacing;
        text['mainAxisSpacing'] = _delegate.mainAxisSpacing;
      }
      delegate = mapToString(text);

      text.clear();
      text['tapOutSideExitEditMode'] = key.currentState.tapOutSideExitEditMode;
      text['onChange event'] = widget.onChanged == null ? 'unset' : 'set';
      text['beforeRemove event'] =
          widget.beforeRemove == null ? 'unset' : 'set';
      settings = mapToString(text);

      items = key.currentState?.items?.join('\n');
    }
  }

  Future<bool> beforeRemove(item, int slotIndex) async {
    item = item as MyItem;
    final res = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Remove item ${item.index}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('No')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Yes')),
              ],
            ));
    if (res == true) {
      key.currentState.removeSlot(slotIndex);
    }
    return false;
  }

  String mapToString(Map map) {
    return map.keys.map((key) => '$key: ${map[key]}').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    updateText();
    return Scaffold(
      appBar: AppBar(
        title: Text('DraggableContainer In ListView'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('DraggableContainer settings'),
            subtitle: Text(settings),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Current SliverGridDelegate'),
            subtitle: Text(delegate),
          ),
          Divider(height: 1),
          DraggableContainer<DraggableItem>(
            key: key,
            items: data,
            beforeRemove: beforeRemove,
            draggingDecoration: BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 5),
              ),
            ]),
            // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //   crossAxisCount: 3,
            //   crossAxisSpacing: 10,
            //   mainAxisSpacing: 10,
            // ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            padding: EdgeInsets.all(10),
            onChanged: (List<DraggableItem> items) {
              setState(() {});
            },
            itemBuilder: (_, DraggableItem item) {
              if (item is AddItem) {
                return ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  onPressed: () {
                    final notNullLength =
                        key.currentState.items.where((e) => e != null).length;
                    if (key.currentState.slots.length < 9) {
                      key.currentState.insertSlot(
                          0,
                          MyItem(
                            index: key.currentState.slots.length,
                          ));
                    } else if (notNullLength >= 9) {
                      key.currentState.replaceItem(8, MyItem(index: 99));
                    }
                  },
                );
              } else if (item is MyItem) {
                return Material(
                  elevation: 0,
                  borderOnForeground: false,
                  child: Container(
                    color: item.color,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.index.toString(),
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            shadows: [
                              BoxShadow(color: Colors.black, blurRadius: 5),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                        ElevatedButton.icon(
                          icon: Icon(item.fixed
                              ? Icons.lock_outline
                              : Icons.lock_open),
                          label: Text(item.fixed ? 'Unlock' : 'Lock'),
                          onPressed: () {
                            item.fixed = !item.fixed;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Current Items'),
            subtitle: Text(items),
          ),
        ],
      ),
    );
  }
}
