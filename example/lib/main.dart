import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:oktoast/oktoast.dart";

import 'example_route.dart';
import 'pages/no_route.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
        child: MaterialApp(
      title: 'draggable_container demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: "draggable_container://mainpage",
      onGenerateRoute: (RouteSettings settings) {
        var routeResult =
            getRouteResult(name: settings.name, arguments: settings.arguments);
        var page = routeResult.widget ?? NoRoute();
        return Platform.isIOS
            ? CupertinoPageRoute(settings: settings, builder: (c) => page)
            : MaterialPageRoute(settings: settings, builder: (c) => page);
      },
    ));
  }
}
