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
  final bool _deletable;
  bool _fixed = false;

  MyItem(this.index)
      :
        // _fixed = index % 2 == 0,
        _fixed = index == 7,
        // _deletable = index % 2 == 1,
        _deletable = true,
        color = randomColor();

  @override
  bool deletable() => _deletable;

  @override
  bool fixed() => _fixed;

  @override
  String toString() {
    return '<MyItem> ${this.hashCode}';
  }
}

class AddItem extends DraggableItem {
  @override
  bool deletable() => false;

  @override
  bool fixed() => true;

  @override
  String toString() {
    return '<AddItem> ${this.hashCode}';
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
            // gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            //   maxCrossAxisExtent: 150,
            //   crossAxisSpacing: 10,
            //   mainAxisSpacing: 10,
            // ),
            padding: EdgeInsets.all(10),
            dragEnd: (newIndex, oldIndex) {},
            itemBuilder: (_, DraggableItem item, int index) {
              print('itemBuilder $index $item');
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
                    if (key.currentState.slots.length < 9) {
                      key.currentState.insertSlot(
                          0,
                          MyItem(
                            key.currentState.slots.length,
                          ));
                    } else {
                      key.currentState.replaceSlot(8, MyItem(99));
                    }
                  },
                );
              } else if (item is MyItem) {
                return Material(
                  elevation: 0,
                  borderOnForeground: false,
                  child: Container(
                    color: randomColor(),
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
                        if (item.fixed()) Icon(Icons.lock_outline),
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
