import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/canvas_math.dart';
import 'canvas_state.dart';

class CanvasCubit extends Cubit<CanvasState> {
  CanvasCubit() : super(CanvasState.initial());

  void addPoint() {
    final next = CanvasMath.nextPoint(state.normalizedPoints.length);
    final updated = [...state.normalizedPoints, next];
    emit(state.copyWith(normalizedPoints: updated));
  }

  bool removePoint() {
    if (state.normalizedPoints.length <= 5) {
      return false;
    }
    final updated = [...state.normalizedPoints]..removeLast();
    final maxIndex = updated.length - 1;
    final nextStart = state.movingStartIndex.clamp(0, maxIndex);
    var nextEnd = state.movingEndIndex.clamp(0, maxIndex);
    if (nextEnd == nextStart) {
      nextEnd = nextStart == 0 ? 1 : nextStart - 1;
    }
    emit(
      state.copyWith(
        normalizedPoints: updated,
        movingStartIndex: nextStart,
        movingEndIndex: nextEnd,
      ),
    );
    return true;
  }

  void setFitTailCount(int value) {
    final sanitized = value < 3 ? 3 : value;
    emit(state.copyWith(fitTailCount: sanitized));
  }

  void setMovingCircleRadius(double value) {
    emit(state.copyWith(movingCircleRadius: value.clamp(4, 48)));
  }

  void togglePlotAnimation() {
    emit(
      state.copyWith(
        isPlotAnimationPlaying: !state.isPlotAnimationPlaying,
      ),
    );
  }

  void selectMovingEndPoint({
    required Offset localPosition,
    required Size canvasSize,
  }) {
    final selectedIndex = CanvasMath.findPointIndexAtPosition(
      normalizedPoints: state.normalizedPoints,
      localPosition: localPosition,
      canvasSize: canvasSize,
    );
    if (selectedIndex == null || selectedIndex == state.movingStartIndex) {
      return;
    }
    emit(state.copyWith(movingEndIndex: selectedIndex));
  }

  void startDrag({required Offset localPosition, required Size canvasSize}) {
    final selectedIndex = CanvasMath.findPointIndexAtPosition(
      normalizedPoints: state.normalizedPoints,
      localPosition: localPosition,
      canvasSize: canvasSize,
    );

    emit(state.copyWith(activePointIndex: selectedIndex));
  }

  void updateDrag({required Offset localPosition, required Size canvasSize}) {
    final index = state.activePointIndex;
    if (index == null || index < 0 || index >= state.normalizedPoints.length) {
      return;
    }

    final normalized = CanvasMath.canvasToNormalized(localPosition, canvasSize);

    final updated = [...state.normalizedPoints];
    updated[index] = normalized;
    emit(state.copyWith(normalizedPoints: updated, activePointIndex: index));
  }

  void endDrag() {
    emit(state.copyWith(clearActivePoint: true));
  }
}
