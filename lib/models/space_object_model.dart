part of 'models.dart';

/// Represents the side of an object.
class SpaceObjectModel<T> {
  /// The user data.
  final T? userData;

  /// The unique identifier of the object.
  final int id;

  /// The child widget.
  final Widget child;

  /// The size of the child widget.
  final Size childSize;

  /// The position of the object.
  final Rx<Offset> position = Offset.zero.obs;

  /// The rect of the object.
  Rect rect = Rect.zero;

  /// Creates a new instance of [SpaceObjectModel].
  SpaceObjectModel({
    required this.child,
    required this.childSize,
    this.userData,
  }) : id = UniqueKey().hashCode {
    position.listen((Offset data) {
      rect = Rect.fromLTWH(
        data.dx,
        data.dy,
        childSize.width,
        childSize.height,
      );
    });
  }

  /// The free sides of the object.
  final Set<ObjectSide> freeSides = <ObjectSide>{
    ObjectSide.top,
    ObjectSide.bottom,
    ObjectSide.left,
    ObjectSide.right,
  };
}
