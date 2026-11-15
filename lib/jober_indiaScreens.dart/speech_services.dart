import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/screens/worker/screen_categry.dart';
import 'package:jober_india/worker_data.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechServices {
  final SpeechToText speech = SpeechToText();
  String detectJob(String text) {
    text = text.toLowerCase();
    if (text.contains("pipe") ||
        text.contains("tap") ||
        text.contains("bathroom") ||
        text.contains("plumber")) {
      return "Plumber";
    }
    if (text.contains("wire") ||
        text.contains("switch") ||
        text.contains("light") ||
        text.contains("fan")) {
      return "Electrician";
    }
    if (text.contains("paint") || text.contains("draw")) {
      return "Painter";
    }
    if (text.contains("clean")) {
      return "Cleaner";
    }
    return "";
  }

  void findWorker(BuildContext context, String job) {
    final workerBox = Hive.box<WorkerData>('workerBox');
    final workers = workerBox.values
        .where((worker) => worker.job.contains(job))
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenCategry(jobs: job, workers: workers),
      ),
    );
  }
}
