import 'dart:ui';

class CanvasState {
  const CanvasState({
    required this.normalizedPoints,
    required this.fitTailCount,
    required this.projectedTailPoints,
    required this.movingCircleRadius,
    required this.movingStartIndex,
    required this.movingEndIndex,
    required this.isPlotAnimationPlaying,
    this.farthestProjectedIndex,
    this.fittedLineStart,
    this.fittedLineEnd,
    this.activePointIndex,
  });

  final List<Offset> normalizedPoints;
  final int fitTailCount;
  final List<Offset> projectedTailPoints;
  final double movingCircleRadius;
  final int movingStartIndex;
  final int movingEndIndex;
  final bool isPlotAnimationPlaying;
  final int? farthestProjectedIndex;
  final Offset? fittedLineStart;
  final Offset? fittedLineEnd;
  final int? activePointIndex;

  factory CanvasState.initial() {
    return const CanvasState(
      normalizedPoints: [
        Offset(0.15, 0.25),
        Offset(0.32, 0.65),
        Offset(0.5, 0.45),
        Offset(0.72, 0.7),
        Offset(0.88, 0.3),
      ],
      fitTailCount: 3,
      projectedTailPoints: [],
      movingCircleRadius: 14,
      movingStartIndex: 0,
      movingEndIndex: 1,
      isPlotAnimationPlaying: false,
    );
  }

  CanvasState copyWith({
    List<Offset>? normalizedPoints,
    int? fitTailCount,
    List<Offset>? projectedTailPoints,
    double? movingCircleRadius,
    int? movingStartIndex,
    int? movingEndIndex,
    bool? isPlotAnimationPlaying,
    int? farthestProjectedIndex,
    Offset? fittedLineStart,
    Offset? fittedLineEnd,
    int? activePointIndex,
    bool clearActivePoint = false,
    bool clearFarthestProjected = false,
    bool clearFittedLine = false,
  }) {
    return CanvasState(
      normalizedPoints: normalizedPoints ?? this.normalizedPoints,
      fitTailCount: fitTailCount ?? this.fitTailCount,
      projectedTailPoints: projectedTailPoints ?? this.projectedTailPoints,
      movingCircleRadius: movingCircleRadius ?? this.movingCircleRadius,
      movingStartIndex: movingStartIndex ?? this.movingStartIndex,
      movingEndIndex: movingEndIndex ?? this.movingEndIndex,
      isPlotAnimationPlaying:
          isPlotAnimationPlaying ?? this.isPlotAnimationPlaying,
      farthestProjectedIndex: clearFarthestProjected
          ? null
          : farthestProjectedIndex ?? this.farthestProjectedIndex,
      fittedLineStart: clearFittedLine
          ? null
          : fittedLineStart ?? this.fittedLineStart,
      fittedLineEnd: clearFittedLine
          ? null
          : fittedLineEnd ?? this.fittedLineEnd,
      activePointIndex: clearActivePoint
          ? null
          : activePointIndex ?? this.activePointIndex,
    );
  }
}
