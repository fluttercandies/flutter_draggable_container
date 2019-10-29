// GENERATED CODE - DO NOT MODIFY BY HAND
// **************************************************************************
// auto generated by https://github.com/fluttercandies/ff_annotation_route
// **************************************************************************

import 'package:flutter/widgets.dart';
import 'pages/add_demo.dart';
import 'pages/delete_demo.dart';
import 'pages/listview_demo.dart';
import 'pages/main_page.dart';

RouteResult getRouteResult({String name, Map<String, dynamic> arguments}) {
  switch (name) {
    case "draggable_container://add":
      return RouteResult(
        widget: AddDemo(),
        routeName: "add",
        description: "show how to add item with draggable_container",
      );
    case "draggable_container://delete":
      return RouteResult(
        widget: DeleteDemo(),
        routeName: "delete",
        description: "show how to delete item with draggable_container",
      );
    case "draggable_container://listview":
      return RouteResult(
        widget: ListViewDemo(),
        routeName: "listView",
        description: "show how to use DraggableContainer in ListView",
      );
    case "draggable_container://mainpage":
      return RouteResult(
        widget: MainPage(),
        routeName: "MainPage",
      );
    default:
      return RouteResult();
  }
}

class RouteResult {
  /// The Widget return base on route
  final Widget widget;

  /// Whether show this route with status bar.
  final bool showStatusBar;

  /// The route name to track page
  final String routeName;

  /// The type of page route
  final PageRouteType pageRouteType;

  /// The description of route
  final String description;

  const RouteResult(
      {this.widget,
      this.showStatusBar = true,
      this.routeName = '',
      this.pageRouteType,
      this.description = ''});
}

enum PageRouteType { material, cupertino, transparent }

List<String> routeNames = [
  "draggable_container://add",
  "draggable_container://delete",
  "draggable_container://listview",
  "draggable_container://mainpage"
];