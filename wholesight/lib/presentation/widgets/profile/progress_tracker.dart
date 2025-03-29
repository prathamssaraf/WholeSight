// lib/presentation/widgets/profile/progress_tracker.dart
import 'package:flutter/material.dart';

class ProgressTracker extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const ProgressTracker({
    Key? key,
    required this.progress,
    required this.color,
    this.height = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
