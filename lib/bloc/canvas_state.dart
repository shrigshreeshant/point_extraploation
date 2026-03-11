import 'dart:ui';

class CanvasState {
  const CanvasState({
    required this.normalizedPoints,
    required this.fitTailCount,
    required this.projectedTailPoints,
    this.farthestProjectedIndex,
    this.fittedLineStart,
    this.fittedLineEnd,
    this.activePointIndex,
  });

  final List<Offset> normalizedPoints;
  final int fitTailCount;
  final List<Offset> projectedTailPoints;
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
    );
  }

  CanvasState copyWith({
    List<Offset>? normalizedPoints,
    int? fitTailCount,
    List<Offset>? projectedTailPoints,
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
