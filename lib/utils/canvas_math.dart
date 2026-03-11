import 'dart:math' as math;
import 'dart:ui';

class CanvasMath {
  static Offset normalizedToCanvas(Offset normalized, Size canvasSize) {
    return Offset(
      normalized.dx * canvasSize.width,
      normalized.dy * canvasSize.height,
    );
  }

  static Offset canvasToNormalized(Offset point, Size canvasSize) {
    if (canvasSize.width == 0 || canvasSize.height == 0) {
      return Offset.zero;
    }

    return clampNormalized(
      Offset(point.dx / canvasSize.width, point.dy / canvasSize.height),
    );
  }

  static Offset clampNormalized(Offset normalized) {
    return Offset(normalized.dx.clamp(0.0, 1.0), normalized.dy.clamp(0.0, 1.0));
  }

  static int? findPointIndexAtPosition({
    required List<Offset> normalizedPoints,
    required Offset localPosition,
    required Size canvasSize,
    double touchRadius = 20,
  }) {
    for (var i = normalizedPoints.length - 1; i >= 0; i--) {
      final pixelPoint = normalizedToCanvas(normalizedPoints[i], canvasSize);
      final distance = (pixelPoint - localPosition).distance;
      if (distance <= touchRadius) {
        return i;
      }
    }
    return null;
  }

  static Offset nextPoint(int index) {
    // Generate predictable, bounded points distributed across the canvas.
    final seed = index + 1;
    final x = ((seed * 37) % 90 + 5) / 100;
    final y = ((seed * 53) % 90 + 5) / 100;
    return Offset(
      math.min(1, math.max(0, x.toDouble())),
      math.min(1, math.max(0, y.toDouble())),
    );
  }

  static ({
    List<Offset> projectedTailPoints,
    int? farthestProjectedIndex,
    Offset? fittedLineStart,
    Offset? fittedLineEnd,
  })
  fittedProjectionForLastThree(List<Offset> normalizedPoints) {
    if (normalizedPoints.length < 3) {
      return (
        projectedTailPoints: const [],
        farthestProjectedIndex: null,
        fittedLineStart: null,
        fittedLineEnd: null,
      );
    }

    final tail = normalizedPoints.skip(normalizedPoints.length - 3).toList();

    final centroid = Offset(
      (tail[0].dx + tail[1].dx + tail[2].dx) / 3,
      (tail[0].dy + tail[1].dy + tail[2].dy) / 3,
    );

    var sxx = 0.0;
    var syy = 0.0;
    var sxy = 0.0;
    for (final point in tail) {
      final dx = point.dx - centroid.dx;
      final dy = point.dy - centroid.dy;
      sxx += dx * dx;
      syy += dy * dy;
      sxy += dx * dy;
    }

    final theta = 0.5 * math.atan2(2 * sxy, sxx - syy);
    final direction = Offset(math.cos(theta), math.sin(theta));
    final projected = tail.map((point) {
      final delta = point - centroid;
      final t = delta.dx * direction.dx + delta.dy * direction.dy;
      return Offset(
        centroid.dx + t * direction.dx,
        centroid.dy + t * direction.dy,
      );
    }).toList();

    var farthestIndex = 0;
    var maxDistanceSq = -1.0;
    for (var i = 0; i < tail.length; i++) {
      final diff = tail[i] - projected[i];
      final distanceSq = diff.dx * diff.dx + diff.dy * diff.dy;
      if (distanceSq > maxDistanceSq) {
        maxDistanceSq = distanceSq;
        farthestIndex = i;
      }
    }

    final line = _lineSegmentInUnitSquare(
      pointOnLine: centroid,
      direction: direction,
    );

    return (
      projectedTailPoints: projected,
      farthestProjectedIndex: farthestIndex,
      fittedLineStart: line?.$1,
      fittedLineEnd: line?.$2,
    );
  }

  static (Offset, Offset)? _lineSegmentInUnitSquare({
    required Offset pointOnLine,
    required Offset direction,
  }) {
    const epsilon = 1e-9;
    final intersections = <Offset>[];

    void addIntersection(double t) {
      final candidate = Offset(
        pointOnLine.dx + t * direction.dx,
        pointOnLine.dy + t * direction.dy,
      );
      if (candidate.dx >= -epsilon &&
          candidate.dx <= 1 + epsilon &&
          candidate.dy >= -epsilon &&
          candidate.dy <= 1 + epsilon) {
        final bounded = Offset(
          candidate.dx.clamp(0.0, 1.0),
          candidate.dy.clamp(0.0, 1.0),
        );
        final exists = intersections.any((p) => (p - bounded).distance < 1e-4);
        if (!exists) {
          intersections.add(bounded);
        }
      }
    }

    if (direction.dx.abs() > epsilon) {
      addIntersection((0 - pointOnLine.dx) / direction.dx);
      addIntersection((1 - pointOnLine.dx) / direction.dx);
    }
    if (direction.dy.abs() > epsilon) {
      addIntersection((0 - pointOnLine.dy) / direction.dy);
      addIntersection((1 - pointOnLine.dy) / direction.dy);
    }

    if (intersections.length < 2) {
      return null;
    }

    var first = intersections[0];
    var second = intersections[1];
    var maxDistanceSq = (first - second).distanceSquared;

    for (var i = 0; i < intersections.length; i++) {
      for (var j = i + 1; j < intersections.length; j++) {
        final a = intersections[i];
        final b = intersections[j];
        final distanceSq = (a - b).distanceSquared;
        if (distanceSq > maxDistanceSq) {
          maxDistanceSq = distanceSq;
          first = a;
          second = b;
        }
      }
    }

    return (first, second);
  }
}
