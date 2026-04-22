import 'package:flutter/material.dart';
import 'package:fitness_tracker/widgets/coach_character.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // 引入 WorkoutProvider

class CoachAnalysisPage extends StatelessWidget {
  const CoachAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final records = Provider.of<WorkoutProvider>(context).records;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI陪练分析'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CoachCharacter(records: records),
        ),
      ),
    );
  }
}