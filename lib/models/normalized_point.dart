import 'dart:ui';

class NormalizedPoint {
  const NormalizedPoint({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  Offset toOffset() => Offset(x, y);

  static NormalizedPoint fromOffset(Offset offset) {
    return NormalizedPoint(x: offset.dx, y: offset.dy);
  }
}
