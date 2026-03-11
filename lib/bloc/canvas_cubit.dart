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

  void removePoint() {
    if (state.normalizedPoints.length <= 2) {
      return;
    }
    final updated = [...state.normalizedPoints]..removeLast();
    emit(state.copyWith(normalizedPoints: updated));
  }

  void setFitTailCount(int value) {
    final sanitized = value < 2 ? 2 : value;
    emit(state.copyWith(fitTailCount: sanitized));
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
