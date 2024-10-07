import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';

import 'models/models.dart';

/// A widget that represents an object on the canvas.
class SpaceObject<T> extends StatelessWidget {
  /// The model of the object.
  final SpaceObjectModel<T> model;

  /// A callback that is called when the object is tapped.
  final Function(SpaceObjectModel<T> object) onTap;

  /// Creates a new instance of [SpaceObject].
  const SpaceObject({
    required this.model,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: model.position.value.dx,
      top: model.position.value.dy,
      width: model.childSize.width,
      height: model.childSize.height,
      child: DeferPointer(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            onTap(model);
          },
          child: model.child,
        ),
      ),
    );
  }
}
