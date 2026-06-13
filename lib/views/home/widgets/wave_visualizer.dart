import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme.dart';

class WaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;

  const WaveVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 15,
  });

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heightMultipliers = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Generar factores de altura aleatorios para cada barra
    for (int i = 0; i < widget.barCount; i++) {
      _heightMultipliers.add(_random.nextDouble() * 0.7 + 0.3);
    }

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            double value = 0.1;
            
            if (widget.isPlaying) {
              // Simular una onda senoidal animada con ruido aleatorio
              final angle = (_controller.value * 2 * pi) + (index * 0.5);
              value = (sin(angle).abs() * 0.6 + 0.2) * _heightMultipliers[index];
            }

            return Container(
              width: 4.0,
              height: max(4.0, value * 40.0), // Altura máxima de 40px
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(2.0),
              ),
            );
          }),
        );
      },
    );
  }
}
