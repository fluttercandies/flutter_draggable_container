import 'package:flutter/widgets.dart';

class DeleteItemButton extends StatelessWidget {
  final Widget child;

  const DeleteItemButton({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      child: AbsorbPointer(child: child),
    );
  }
}
