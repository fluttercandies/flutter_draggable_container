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
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: Text('Demo 1'),
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => DemoWidget()));
              },
            ),
            RaisedButton(
              child: Text('Demo 2'),
              color: Colors.orange,
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => DemoWidget2()));
              },
            ),
            RaisedButton(
              child: Text('Demo 3'),
              color: Colors.green,
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => DemoWidget3()));
              },
            ),
          ]),
    );
  }
}
