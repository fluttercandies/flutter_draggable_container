import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class DraggableContainer extends BoxScrollView {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing, runSpacing;
  final ScrollController? controller;

  /// Look at [GridView.builder]
  final SliverGridDelegate gridDelegate;

  /// Look at [GridView.builder]
  final SliverDraggableChildBuilderDelegate childrenDelegate;
  final bool shrinkWrap;

  DraggableContainer({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.controller,
    bool addAutomaticKeepAlives = true,
    this.shrinkWrap = false,
  })  : childrenDelegate = SliverDraggableChildBuilderDelegate(itemBuilder,
            childCount: itemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives),
        super(
          key: key,
          semanticChildCount: itemCount,
        );

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverGrid(
      delegate: childrenDelegate,
      gridDelegate: gridDelegate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = buildSlivers(context);
    final AxisDirection axisDirection = getDirection(context);
    final ScrollController? scrollController =
        primary ? PrimaryScrollController.of(context) : controller;

    final Scrollable scrollable = Scrollable(
      dragStartBehavior: dragStartBehavior,
      axisDirection: axisDirection,
      controller: scrollController,
      physics: physics,
      semanticChildCount: semanticChildCount,
      restorationId: restorationId,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return buildViewport(context, offset, axisDirection, slivers);
      },
    );
    return scrollable;
  }

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    if (shrinkWrap) {
      return ShrinkWrappingViewport(
        axisDirection: axisDirection,
        offset: offset,
        slivers: slivers,
        clipBehavior: clipBehavior,
      );
    }
    return Viewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
      clipBehavior: clipBehavior,
    );
  }
}

class SliverDraggableChildBuilderDelegate extends SliverChildDelegate {
  final NullableIndexedWidgetBuilder builder;
  final bool addAutomaticKeepAlives;
  final int childCount;
  double x = 0, y = 0;

  SliverDraggableChildBuilderDelegate(
    this.builder, {
    required this.addAutomaticKeepAlives,
    required this.childCount,
  });

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || (index >= childCount)) return null;
    Widget? child = builder(context, index);
    if (child == null) {
      return null;
    }
    final Key? key = child.key != null ? ValueKey(child.key) : null;
    return KeyedSubtree(
      key: key,
      child: AutomaticKeepAlive(
        child: ItemWidget(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverChildDelegate oldDelegate) => true;
}

class ItemWidget extends StatefulWidget {
  final Widget child;

  const ItemWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ItemWidget();
}

class _ItemWidget extends State<ItemWidget> {
  double x = 0, y = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (_) {
        x += _.delta.dx;
        y += _.delta.dy;
        setState(() {});
      },
      child: Transform(
        transform: Matrix4.identity()..translate(x, y),
        child: widget.child,
      ),
    );
  }
}
