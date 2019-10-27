import 'package:flutter/material.dart';

import './demo1.dart';
import './demo2.dart';
import './demo3.dart';

void main() {
//  debugPrintGestureArenaDiagnostics = true;
  runApp(MaterialApp(title: 'Draggable Container Demo', home: App()));
}

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Draggable Container Demo')),
      body: ListView(children: <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                      'This demo is about the DraggableContainer widget in the Listview widget.\n'
                      'You can drag the children widget and do not scroll the ListView.\n'
                      'btw: Need long press to enter the draggable mode at first.'),
                ),
                RaisedButton(
                  child: Text('Demo 1'),
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DemoWidget()));
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 5),
                  child: Text('Dynamic to display the functional button.'),
                ),
                RaisedButton(
                  child: Text('Demo 2'),
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DemoWidget2()));
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 5),
                  child: Text('Show a confirm dialog before delete item.'),
                ),
                RaisedButton(
                  child: Text('Demo 3'),
                  color: Colors.orange,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DemoWidget3()));
                  },
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
