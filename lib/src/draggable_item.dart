abstract class DraggableItem {
  bool get fixed;

  bool get deletable;

  @override
  String toString() {
    return '<DraggableItem> ${this.hashCode}';
  }
}
