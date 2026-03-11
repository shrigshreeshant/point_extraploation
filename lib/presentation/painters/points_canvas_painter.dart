import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/canvas_math.dart';

class PointsCanvasPainter extends CustomPainter {
  const PointsCanvasPainter({
    required this.normalizedPoints,
    required this.activePointIndex,
    required this.fitTailCount,
  });

  final List<Offset> normalizedPoints;
  final int? activePointIndex;
  final int fitTailCount;

  ({
    List<Offset> projectedTailPoints,
    int? farthestProjectedIndex,
    Offset? fittedLineStart,
    Offset? fittedLineEnd,
    Offset? selectedProjectedPoint,
    List<Offset> nonClusterPathPoints,
  })
  _fittedProjectionInCanvasSpace(List<Offset> canvasPoints, Size size) {
    if (canvasPoints.length < 2) {
      return (
        projectedTailPoints: const [],
        farthestProjectedIndex: null,
        fittedLineStart: null,
        fittedLineEnd: null,
        selectedProjectedPoint: null,
        nonClusterPathPoints: const [],
      );
    }

    final p2 = canvasPoints[1];
    final windowCount = fitTailCount.clamp(2, canvasPoints.length);
    final prefix = canvasPoints
        .take(canvasPoints.length - windowCount)
        .toList();
    final tail = canvasPoints.skip(canvasPoints.length - windowCount).toList();
    final eligible = tail;
    if (eligible.length < 2) {
      return (
        projectedTailPoints: const [],
        farthestProjectedIndex: null,
        fittedLineStart: null,
        fittedLineEnd: null,
        selectedProjectedPoint: null,
        nonClusterPathPoints: prefix,
      );
    }

    final centroid = Offset(
      eligible.map((p) => p.dx).reduce((a, b) => a + b) / eligible.length,
      eligible.map((p) => p.dy).reduce((a, b) => a + b) / eligible.length,
    );

    var sxx = 0.0;
    var syy = 0.0;
    var sxy = 0.0;
    for (final point in eligible) {
      final dx = point.dx - centroid.dx;
      final dy = point.dy - centroid.dy;
      sxx += dx * dx;
      syy += dy * dy;
      sxy += dx * dy;
    }

    // Orthogonal least-squares fit (total least squares):
    // direction = principal eigenvector of covariance matrix.
    final trace = sxx + syy;
    final determinant = sxx * syy - sxy * sxy;
    final discriminant = math.max(0.0, trace * trace - 4 * determinant);
    final lambdaMax = (trace + math.sqrt(discriminant)) / 2;

    var vx = sxy;
    var vy = lambdaMax - sxx;
    final norm = math.sqrt(vx * vx + vy * vy);

    Offset direction;
    if (norm > 1e-9) {
      direction = Offset(vx / norm, vy / norm);
    } else {
      // Degenerate case (all points almost identical): use eligible span.
      final span = eligible.last - eligible.first;
      if (span.distance > 1e-9) {
        direction = span / span.distance;
      } else {
        direction = const Offset(1, 0);
      }
    }
    // Fit is computed only from eligible points, but projection is shown
    // for every point in the selected tail window.
    final projected = tail.map((point) {
      final delta = point - centroid;
      final t = delta.dx * direction.dx + delta.dy * direction.dy;
      return Offset(
        centroid.dx + t * direction.dx,
        centroid.dy + t * direction.dy,
      );
    }).toList();

    // Select projected point farthest from point 2 (index 1).
    final referencePoint = p2;
    var farthestIndex = 0;
    var maxDistanceSq = -1.0;
    for (var i = 0; i < projected.length; i++) {
      final diff = projected[i] - referencePoint;
      final distanceSq = diff.dx * diff.dx + diff.dy * diff.dy;
      if (distanceSq > maxDistanceSq) {
        maxDistanceSq = distanceSq;
        farthestIndex = i;
      }
    }

    final line = _lineSegmentInCanvasRect(
      pointOnLine: centroid,
      direction: direction,
      size: size,
    );

    return (
      projectedTailPoints: projected,
      farthestProjectedIndex: farthestIndex,
      fittedLineStart: line?.$1,
      fittedLineEnd: line?.$2,
      selectedProjectedPoint: projected[farthestIndex],
      nonClusterPathPoints: [...prefix, projected[farthestIndex]],
    );
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) {
      return path;
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  (Offset, Offset)? _lineSegmentInCanvasRect({
    required Offset pointOnLine,
    required Offset direction,
    required Size size,
  }) {
    const epsilon = 1e-9;
    final intersections = <Offset>[];

    void addIntersection(double t) {
      final candidate = Offset(
        pointOnLine.dx + t * direction.dx,
        pointOnLine.dy + t * direction.dy,
      );
      if (candidate.dx >= -epsilon &&
          candidate.dx <= size.width + epsilon &&
          candidate.dy >= -epsilon &&
          candidate.dy <= size.height + epsilon) {
        final bounded = Offset(
          candidate.dx.clamp(0.0, size.width),
          candidate.dy.clamp(0.0, size.height),
        );
        final exists = intersections.any((p) => (p - bounded).distance < 1e-4);
        if (!exists) {
          intersections.add(bounded);
        }
      }
    }

    if (direction.dx.abs() > epsilon) {
      addIntersection((0 - pointOnLine.dx) / direction.dx);
      addIntersection((size.width - pointOnLine.dx) / direction.dx);
    }
    if (direction.dy.abs() > epsilon) {
      addIntersection((0 - pointOnLine.dy) / direction.dy);
      addIntersection((size.height - pointOnLine.dy) / direction.dy);
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

  void _drawDottedLine({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
    double dashLength = 8,
    double gapLength = 6,
  }) {
    final delta = end - start;
    final totalLength = delta.distance;
    if (totalLength == 0) {
      return;
    }

    final direction = Offset(delta.dx / totalLength, delta.dy / totalLength);
    var current = 0.0;

    while (current < totalLength) {
      final dashStart = Offset(
        start.dx + direction.dx * current,
        start.dy + direction.dy * current,
      );
      final dashEndDistance = (current + dashLength).clamp(0.0, totalLength);
      final dashEnd = Offset(
        start.dx + direction.dx * dashEndDistance,
        start.dy + direction.dy * dashEndDistance,
      );
      canvas.drawLine(dashStart, dashEnd, paint);
      current += dashLength + gapLength;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pointPaint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.fill;

    final clusterPointPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    final activePointPaint = Paint()
      ..color = const Color(0xFFEF5350)
      ..style = PaintingStyle.fill;

    final fitLinePaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bridgeCurvePaint = Paint()
      ..color = const Color(0xFF7E57C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final projectedFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final projectedBorderPaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final selectedProjectedBorderPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(Offset.zero & size, borderPaint);

    if (normalizedPoints.length > 1) {
      final canvasPoints = normalizedPoints
          .map((point) => CanvasMath.normalizedToCanvas(point, size))
          .toList();
      final fit = _fittedProjectionInCanvasSpace(canvasPoints, size);
      if (fit.fittedLineStart != null && fit.fittedLineEnd != null) {
        _drawDottedLine(
          canvas: canvas,
          start: fit.fittedLineStart!,
          end: fit.fittedLineEnd!,
          paint: fitLinePaint,
        );
      }
      if (fit.nonClusterPathPoints.length >= 2) {
        final selectedPath = _buildSmoothPath(fit.nonClusterPathPoints);
        canvas.drawPath(selectedPath, bridgeCurvePaint);
      }
      for (var i = 0; i < fit.projectedTailPoints.length; i++) {
        final projected = fit.projectedTailPoints[i];
        final isFarthest = i == fit.farthestProjectedIndex;
        canvas.drawCircle(projected, 7, projectedFillPaint);
        canvas.drawCircle(
          projected,
          7,
          isFarthest ? selectedProjectedBorderPaint : projectedBorderPaint,
        );
      }
    }

    final clusterStartIndex = normalizedPoints.isEmpty
        ? 0
        : normalizedPoints.length -
              fitTailCount.clamp(1, normalizedPoints.length);
    for (var i = 0; i < normalizedPoints.length; i++) {
      final pixelPoint = CanvasMath.normalizedToCanvas(
        normalizedPoints[i],
        size,
      );
      final isActive = i == activePointIndex;
      final isClusterPoint = i >= clusterStartIndex;
      canvas.drawCircle(
        pixelPoint,
        isActive ? 10 : 8,
        isActive
            ? activePointPaint
            : (isClusterPoint ? clusterPointPaint : pointPaint),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PointsCanvasPainter oldDelegate) {
    return oldDelegate.normalizedPoints != normalizedPoints ||
        oldDelegate.activePointIndex != activePointIndex ||
        oldDelegate.fitTailCount != fitTailCount;
  }
}
