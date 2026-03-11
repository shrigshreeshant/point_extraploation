import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_cubit.dart';
import '../../bloc/canvas_state.dart';
import '../painters/points_canvas_painter.dart';

class InteractiveCanvas extends StatelessWidget {
  const InteractiveCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return BlocBuilder<CanvasCubit, CanvasState>(
          builder: (context, state) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onPanStart: (details) {
                FocusManager.instance.primaryFocus?.unfocus();
                context.read<CanvasCubit>().startDrag(
                      localPosition: details.localPosition,
                      canvasSize: canvasSize,
                    );
              },
              onPanUpdate: (details) {
                context.read<CanvasCubit>().updateDrag(
                      localPosition: details.localPosition,
                      canvasSize: canvasSize,
                    );
              },
              onPanEnd: (_) {
                context.read<CanvasCubit>().endDrag();
              },
              onPanCancel: () {
                context.read<CanvasCubit>().endDrag();
              },
              child: CustomPaint(
                painter: PointsCanvasPainter(
                  normalizedPoints: state.normalizedPoints,
                  activePointIndex: state.activePointIndex,
                  fitTailCount: state.fitTailCount,
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        );
      },
    );
  }
}
