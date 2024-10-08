import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:r_tree/r_tree.dart';

import 'models/models.dart';

/// Represents the controller for the space canvas.
class SpaceCanvasController<T> {
  /// The set of unassigned objects.
  final Set<SpaceObjectModel<T>> _unassignedObjects = <SpaceObjectModel<T>>{};

  /// The set of visible objects' identifiers.
  final Set<int> visibleObjectsIds = <int>{};

  /// The set of visible objects.
  final RxSet<SpaceObjectModel<T>> visibleObjects = <SpaceObjectModel<T>>{}.obs;

  /// The offset of the canvas.
  final Rx<Offset> offset = Offset.zero.obs;

  /// The size of the canvas.
  final double canvasSize;

  /// The screen size.
  final Rx<Size> screenSize = Size.zero.obs;

  /// The visible space.
  final Rx<Rect> visibleSpace = Rect.zero.obs;

  /// The scale factor.
  final Rx<double> scaleFactor = Rx<double>(1);

  /// The function that returns the objects.
  final Future<List<SpaceObjectModel<T>>> Function() getObjects;

  /// The RTree.
  late RTree<SpaceObjectModel<T>> rTree;

  /// The maximum scale.
  final double maxScale;

  /// The minimum scale.
  final double minScale;

  /// The callback that is called when the scale is changed.
  final void Function(double scale)? onScaleChanged;

  /// Creates a new instance of [SpaceCanvasController].
  SpaceCanvasController({
    this.canvasSize = 10000000,
    this.maxScale = 3,
    this.minScale = 0.1,
    this.onScaleChanged,
    required this.getObjects,
  }) {
    // Initialize RTree with an empty dataset
    rTree = RTree<SpaceObjectModel<T>>();
  }

  Future<void> _initialData() async {
    final List<SpaceObjectModel<T>> objects = await getObjects();
    if (_unassignedObjects.isEmpty && objects.isNotEmpty) {
      objects.first.position.value = Offset(canvasSize / 2 - objects.first.childSize.width / 2,
          canvasSize / 2 - objects.first.childSize.height / 2);
      rTree.add(
        <RTreeDatum<SpaceObjectModel<T>>>[
          RTreeDatum<SpaceObjectModel<T>>(
            Rectangle(
              objects.first.position.value.dx,
              objects.first.position.value.dy,
              objects.first.childSize.width,
              objects.first.childSize.height,
            ),
            objects.first,
          )
        ],
      );
      visibleObjects.add(objects.first);
      visibleObjectsIds.add(objects.first.id);
      objects.removeAt(0);
    }
    _unassignedObjects.addAll(objects);
    final Offset topLeftCorner = Offset(
      (offset.value.dx * scaleFactor.value).abs(),
      (offset.value.dy * scaleFactor.value).abs(),
    );
    final Offset bottomRightCorner = Offset(
      topLeftCorner.dx + screenSize.value.width,
      topLeftCorner.dy + screenSize.value.height,
    );
    visibleSpace.value = Rect.fromPoints(topLeftCorner, bottomRightCorner);
    unawaited(_findVisibleObjects());
  }

  /// Initializes the controller.
  void init({
    required Size windowSize,
  }) {
    screenSize.value = windowSize;
    onScaleChanged?.call(scaleFactor.value);
    offset.value = Offset(
      windowSize.width / 2 - canvasSize / 2,
      windowSize.height / 2 - canvasSize / 2,
    );
    // Get initial objects
    _initialData();
  }

  Offset _initialOffset = Offset.zero;
  double _initialScale = 1.0;
  Offset _initialFocalPointCanvasSpace = Offset.zero;

  /// Handles the start of scaling.
  void onScaleStart(ScaleStartDetails details) {
    _initialScale = scaleFactor.value;
    _initialOffset = offset.value;
    _initialFocalPointCanvasSpace = (details.focalPoint / scaleFactor.value) - offset.value;
  }

  /// Handles the update of scaling.
  void onScaleUpdate(ScaleUpdateDetails details) {
    scaleFactor.value = (_initialScale * details.scale).clamp(minScale, maxScale);
    final Offset focalPointCanvasSpace = (details.focalPoint / scaleFactor.value) - _initialOffset;
    offset.value = _initialOffset + (focalPointCanvasSpace - _initialFocalPointCanvasSpace);

    final Offset topLeftCorner = -offset.value;
    final Size visibleSize = screenSize.value / scaleFactor.value;
    visibleSpace.value = Rect.fromLTWH(
      topLeftCorner.dx,
      topLeftCorner.dy,
      visibleSize.width,
      visibleSize.height,
    );
    onScaleChanged?.call(scaleFactor.value);
    _findVisibleObjects();
  }

  /// Handles the end of scaling.
  void onScaleEnd(ScaleEndDetails details) {}

  Future<void> _findVisibleObjects() async {
    final List<RTreeDatum<SpaceObjectModel<T>>> nearbyDatums = rTree.search(
      Rectangle(
        visibleSpace.value.left,
        visibleSpace.value.top,
        visibleSpace.value.width,
        visibleSpace.value.height,
      ),
    );

    // Extract the SpaceObjectModel<T> from the RTreeDatum
    final List<SpaceObjectModel<T>> nearbyObjects =
        nearbyDatums.map((RTreeDatum<SpaceObjectModel<T>> datum) => datum.value).toList();
    final List<SpaceObjectModel<T>> objectsToRemove = <SpaceObjectModel<T>>[];
    final List<SpaceObjectModel<T>> objectsToShow = <SpaceObjectModel<T>>[];

    // Сначала добавляем объекты, которые находятся в nearbyObjects, в objectsToShow.
    await Future.forEach(
      nearbyObjects,
      (SpaceObjectModel<T> object) async {
        objectsToShow.add(object);

        if (object.freeSides.isNotEmpty) {
          await _fillFreeSides(parent: object);
        }
      },
    );

    nearbyObjects.clear();
    nearbyObjects.addAll(rTree
        .search(
          Rectangle(
            visibleSpace.value.left,
            visibleSpace.value.top,
            visibleSpace.value.width,
            visibleSpace.value.height,
          ),
        )
        .map((RTreeDatum<SpaceObjectModel<T>> datum) => datum.value));

    // Теперь находим объекты, которые не находятся в nearbyObjects, и добавляем их в objectsToRemove.
    for (final SpaceObjectModel<T> object in visibleObjects) {
      if (!nearbyObjects.contains(object)) {
        objectsToRemove.add(object);
      }
    }

    // Удаляем объекты из visibleObjects и visibleObjectsIds.
    visibleObjects.removeAll(objectsToRemove);
    visibleObjectsIds.removeAll(objectsToRemove.map((SpaceObjectModel<T> object) => object.id));

    // Добавляем объекты в visibleObjects и visibleObjectsIds.
    visibleObjects.addAll(objectsToShow);
    objectsToShow.forEach((SpaceObjectModel<T> object) {
      visibleObjectsIds.add(object.id);
    });
  }

  bool _isOverlapping(Offset newPosition, Size size) {
    final Rectangle newRectangle =
        Rectangle(newPosition.dx, newPosition.dy, size.width, size.height);
    final List<RTreeDatum<SpaceObjectModel<T>>> overlappingObjects = rTree.search(newRectangle);
    return overlappingObjects.isNotEmpty;
  }

  bool _isVisible(Rect objectRect) {
    return visibleSpace.value.overlaps(objectRect);
  }

  Future<void> _fillFreeSides({required SpaceObjectModel<T> parent}) async {
    final Set<ObjectSide> freeSides = <ObjectSide>{...parent.freeSides};
    final List<SpaceObjectModel<T>> newChildren = <SpaceObjectModel<T>>[];
    await Future.forEach(
      freeSides,
      (ObjectSide side) async {
        final SpaceObjectModel<T> object = await _getNeighbors();
        final Offset newPosition = _calculateNewPosition(
          parent.position.value,
          side,
          object.childSize,
        );

        if (!_isOverlapping(newPosition, object.childSize)) {
          object.position.value = newPosition;
          object.freeSides.remove(side.getOppositeSide);
          parent.freeSides.remove(side);

          rTree.add(
            <RTreeDatum<SpaceObjectModel<T>>>[
              RTreeDatum<SpaceObjectModel<T>>(
                Rectangle(
                  newPosition.dx,
                  newPosition.dy,
                  object.childSize.width,
                  object.childSize.height,
                ),
                object,
              ),
            ],
          );
          newChildren.add(object);
          return;
        } else {
          parent.freeSides.remove(side);
          object.freeSides.remove(side.getOppositeSide);
        }
      },
    );

    await Future.forEach(newChildren, (SpaceObjectModel<T> object) async {
      visibleObjects.add(object);
      visibleObjectsIds.add(object.id);
      if (_isVisible(object.rect) && object.freeSides.isNotEmpty) {
        await _fillFreeSides(parent: object);
      }
    });
  }

  Future<SpaceObjectModel<T>> _getNeighbors() async {
    if (_unassignedObjects.isNotEmpty) {
      final SpaceObjectModel<T> obj = _unassignedObjects.first;
      _unassignedObjects.remove(obj);
      return obj;
    } else {
      _unassignedObjects.addAll(await getObjects());
      return _getNeighbors();
    }
  }

  Offset _calculateNewPosition(Offset parentPos, ObjectSide side, Size size) {
    switch (side) {
      case ObjectSide.top:
        return Offset(parentPos.dx, parentPos.dy - size.height);
      case ObjectSide.bottom:
        return Offset(parentPos.dx, parentPos.dy + size.height);
      case ObjectSide.left:
        return Offset(parentPos.dx - size.width, parentPos.dy);
      case ObjectSide.right:
        return Offset(parentPos.dx + size.width, parentPos.dy);
      default:
        return parentPos;
    }
  }
}
