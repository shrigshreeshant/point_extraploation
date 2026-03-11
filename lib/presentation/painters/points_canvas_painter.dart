import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/canvas_math.dart';

class PointsCanvasPainter extends CustomPainter {
  const PointsCanvasPainter({
    required this.normalizedPoints,
    required this.activePointIndex,
    required this.fitTailCount,
    required this.movingCircleRadius,
    required this.movingStartIndex,
  });

  final List<Offset> normalizedPoints;
  final int? activePointIndex;
  final int fitTailCount;
  final double movingCircleRadius;
  final int movingStartIndex;

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
    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
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

  void _drawCircleChainOnPath({
    required Canvas canvas,
    required Path path,
    required double radius,
    required double startOffset,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return;
    }
    final pathMetric = metrics.first;
    final length = pathMetric.length;
    if (length < 1e-6) {
      return;
    }
    final spacing = math.max(2.0, radius * 2 + 2);

    final fillPaint = Paint()
      ..color = const Color(0x5581D4FA)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF0288D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    final secondLastHighlightPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final endTangent = pathMetric.getTangentForOffset(length);
    if (endTangent == null) {
      return;
    }
    final endPoint = endTangent.position;

    Offset? previousCenter;
    final firstCenterOffset = (startOffset + radius).clamp(0.0, length);
    for (var offset = firstCenterOffset; offset <= length; offset += spacing) {
      final tangent = pathMetric.getTangentForOffset(offset);
      if (tangent == null) {
        continue;
      }
      canvas.drawCircle(tangent.position, radius, fillPaint);
      canvas.drawCircle(tangent.position, radius, strokePaint);
      previousCenter = tangent.position;
    }

    // If the last center on curve cannot naturally satisfy end coverage,
    // add one more circle whose center is on the line to the end point.
    if (previousCenter != null) {
      final toEnd = endPoint - previousCenter;
      final distanceToEnd = toEnd.distance;
      if (distanceToEnd > radius + 0.5) {
        canvas.drawCircle(previousCenter, radius + 2, secondLastHighlightPaint);

        final direction = Offset(
          toEnd.dx / distanceToEnd,
          toEnd.dy / distanceToEnd,
        );
        var fallbackCenter = Offset(
          endPoint.dx - direction.dx * radius,
          endPoint.dy - direction.dy * radius,
        );
        final minNonOverlapCenter = Offset(
          previousCenter.dx + direction.dx * spacing,
          previousCenter.dy + direction.dy * spacing,
        );
        final centerGap = (fallbackCenter - previousCenter).distance;
        if (centerGap < spacing) {
          fallbackCenter = minNonOverlapCenter;
        }

        canvas.drawCircle(fallbackCenter, radius, fillPaint);
        canvas.drawCircle(fallbackCenter, radius, strokePaint);
      }
    }
  }

  ({double offset, Offset position})? _nearestPointOnPath({
    required Path path,
    required Offset target,
    int samples = 240,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return null;
    }

    final metric = metrics.first;
    final length = metric.length;
    if (length < 1e-6) {
      return null;
    }

    var nearestOffset = 0.0;
    var nearestPosition =
        metric.getTangentForOffset(0)?.position ?? Offset.zero;
    var minDistanceSq = double.infinity;

    for (var i = 0; i <= samples; i++) {
      final sampleOffset = length * (i / samples);
      final tangent = metric.getTangentForOffset(sampleOffset);
      if (tangent == null) {
        continue;
      }
      final delta = tangent.position - target;
      final distanceSq = delta.dx * delta.dx + delta.dy * delta.dy;
      if (distanceSq < minDistanceSq) {
        minDistanceSq = distanceSq;
        nearestOffset = sampleOffset;
        nearestPosition = tangent.position;
      }
    }

    return (offset: nearestOffset, position: nearestPosition);
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

    final streamEndpointPaint = Paint()
      ..color = const Color(0xFF00695C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

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
      Path? selectedPath;
      if (fit.nonClusterPathPoints.length >= 2) {
        selectedPath = _buildSmoothPath(fit.nonClusterPathPoints);
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
      if (fit.selectedProjectedPoint != null && selectedPath != null) {
        final safeStart = movingStartIndex.clamp(
          0,
          normalizedPoints.length - 1,
        );
        final start = CanvasMath.normalizedToCanvas(
          normalizedPoints[safeStart],
          size,
        );
        final snappedStart = _nearestPointOnPath(
          path: selectedPath,
          target: start,
        );
        if (snappedStart != null) {
          _drawCircleChainOnPath(
            canvas: canvas,
            path: selectedPath,
            radius: movingCircleRadius,
            startOffset: snappedStart.offset,
          );
          canvas.drawCircle(
            snappedStart.position,
            movingCircleRadius + 3,
            streamEndpointPaint,
          );
        }
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
        oldDelegate.fitTailCount != fitTailCount ||
        oldDelegate.movingCircleRadius != movingCircleRadius ||
        oldDelegate.movingStartIndex != movingStartIndex;
  }
}
