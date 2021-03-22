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
      : _fixed = index % 2 == 0,
        _deletable = index % 2 == 1,
        color = randomColor();

  @override
  bool deletable() => _deletable;

  @override
  bool fixed() => _fixed;
}

class MyHomePage extends StatelessWidget {
  final data = <MyItem>[
    MyItem(1),
    MyItem(2),
    MyItem(3),
    MyItem(4),
    null,
    MyItem(6),
    MyItem(7),
    MyItem(8),
    MyItem(9),
  ];

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
          DraggableContainer<MyItem>(
            items: data,
            itemCount: 9,
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
            itemBuilder: (_, MyItem item) {
              if (item == null) return null;
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
            },
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
