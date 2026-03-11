import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/canvas_cubit.dart';
import 'bloc/canvas_state.dart';
import 'presentation/widgets/interactive_canvas.dart';

void main() {
  runApp(const CanvasApp());
}

class CanvasApp extends StatelessWidget {
  const CanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CanvasCubit(),
      child: MaterialApp(
        title: 'Interactive Canvas',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const CanvasPage(),
      ),
    );
  }
}

class CanvasPage extends StatefulWidget {
  const CanvasPage({super.key});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  late final TextEditingController _fitCountController;

  @override
  void initState() {
    super.initState();
    final initial = context.read<CanvasCubit>().state.fitTailCount;
    _fitCountController = TextEditingController(text: initial.toString());
  }

  @override
  void dispose() {
    _fitCountController.dispose();
    super.dispose();
  }

  void _applyFitCount() {
    final parsed = int.tryParse(_fitCountController.text.trim());
    if (parsed == null) {
      return;
    }
    context.read<CanvasCubit>().setFitTailCount(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draggable Points Canvas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Drag points. Long-press any point to set circle start. Circles are drawn sequentially on the curve.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _fitCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fit last N',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _applyFitCount(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyFitCount,
                    child: const Text('Update'),
                  ),
                  IconButton.filled(
                    onPressed: () {
                      context.read<CanvasCubit>().addPoint();
                    },
                    icon: const Icon(Icons.add),
                    tooltip: 'Add point',
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      context.read<CanvasCubit>().removePoint();
                    },
                    icon: const Icon(Icons.remove),
                    tooltip: 'Remove point',
                  ),
                  const SizedBox(width: 12),
                  BlocBuilder<CanvasCubit, CanvasState>(
                    builder: (context, state) {
                      return Text('Current N: ${state.fitTailCount}');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<CanvasCubit, CanvasState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          'Circle radius: ${state.movingCircleRadius.toStringAsFixed(0)}',
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          min: 4,
                          max: 48,
                          divisions: 44,
                          value: state.movingCircleRadius,
                          label: state.movingCircleRadius.toStringAsFixed(0),
                          onChanged: (value) {
                            context.read<CanvasCubit>().setMovingCircleRadius(
                              value,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        spreadRadius: 1,
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const InteractiveCanvas(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<CanvasCubit, CanvasState>(
                builder: (context, state) {
                  return Text('Total points: ${state.normalizedPoints.length}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
