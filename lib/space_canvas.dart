import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'models/models.dart';
import 'space_canvas_controller.dart';
import 'space_object.dart';

///  [SpaceCanvas] is a widget that displays a canvas with objects that can be moved and scaled.
class SpaceCanvas<T> extends StatelessWidget {
  /// The controller that manages the state of the canvas.
  final SpaceCanvasController<T> controller;

  /// A callback that is called when an object is tapped.
  final Function(SpaceObjectModel<T> object) onObjectTap;

  /// Creates a new instance of [SpaceCanvas].
  const SpaceCanvas({
    required this.onObjectTap,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        // Create a combined transformation matrix
        final Matrix4 transformationMatrix = Matrix4.identity()
          ..scale(controller.scaleFactor.value, controller.scaleFactor.value)
          ..translate(controller.offset.value.dx, controller.offset.value.dy);

        return GestureDetector(
          onScaleStart: controller.onScaleStart,
          onScaleEnd: controller.onScaleEnd,
          onScaleUpdate: controller.onScaleUpdate,
          behavior: HitTestBehavior.opaque,
          child: DeferredPointerHandler(
            child: Transform(
              transform: transformationMatrix,
              child: SizedBox(
                width: controller.canvasSize,
                height: controller.canvasSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    ...controller.visibleObjects.map((SpaceObjectModel<T> obj) {
                      return SpaceObject<T>(
                        model: obj,
                        onTap: onObjectTap,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
