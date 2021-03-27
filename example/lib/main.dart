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
      title: 'Example',
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
    return '<MyItem> $index';
  }
}

class AddItem extends DraggableItem {
  @override
  bool get deletable => false;

  @override
  bool get fixed => true;

  @override
  String toString() {
    return '<AddItem>';
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

  bool editting = false;

  void editModeChange(bool val) {
    editting = val;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example'),
      ),
      body: ListView(
        children: [
          Container(
            height: 30,
            color: Colors.red,
            alignment: Alignment.centerLeft,
            child: Text('hi'),
          ),
          DraggableContainer<DraggableItem>(
            key: key,
            items: data,
            onEditModeChange: editModeChange,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            draggingDecoration: BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 5),
              ),
            ]),
            // gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            //   maxCrossAxisExtent: 150,
            //   crossAxisSpacing: 10,
            //   mainAxisSpacing: 10,
            // ),
            padding: EdgeInsets.all(10),
            onChange: (List<DraggableItem> items) {
              print('onChange $items');
            },
            itemBuilder: (_, DraggableItem item, int index) {
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
          if (editting)
            Container(
              child: Center(
                child: ElevatedButton(
                  child: Text('退出编辑模式'),
                  onPressed: () {
                    key.currentState?.editMode = false;
                  },
                ),
              ),
            ),
          Container(
            height: 30,
            color: Colors.red,
            alignment: Alignment.centerLeft,
            child: Text('hi'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.print),
        onPressed: () {
          print(key.currentState.items);
        },
      ),
    );
  }
}
