part of 'models.dart';

/// Represents the side of an object.
enum ObjectSide {
  /// The top side of the object.
  top,

  /// The bottom side of the object.
  bottom,

  /// The left side of the object.
  left,

  /// The right side of the object.
  right,

  /// No side.
  none;

  /// Returns the opposite side of the current side.
  ObjectSide get getOppositeSide {
    switch (this) {
      case ObjectSide.top:
        return ObjectSide.bottom;
      case ObjectSide.bottom:
        return ObjectSide.top;
      case ObjectSide.left:
        return ObjectSide.right;
      case ObjectSide.right:
        return ObjectSide.left;
      default:
        return ObjectSide.none;
    }
  }

  /// Returns the side of the neighbor object relative to the target object.
  static ObjectSide getNeighborSide(Rect targetRect, Rect neighborRect) {
    if (neighborRect.top < targetRect.top) {
      return ObjectSide.top;
    } else if (neighborRect.bottom > targetRect.bottom) {
      return ObjectSide.bottom;
    } else if (neighborRect.left < targetRect.left) {
      return ObjectSide.left;
    } else if (neighborRect.right > targetRect.right) {
      return ObjectSide.right;
    } else {
      return ObjectSide.none;
    }
  }
}
