// ignore_for_file: use_key_in_widget_constructors, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherScoreView extends StatelessWidget {
  TeacherScoreView({super.key});

  // Controller to manage fetching scores
  final TeacherScoreController controller = Get.put(TeacherScoreController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scores Overview')),
      body: Obx(() {
        if (controller.scores.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return ScoreTable(scores: controller.scores);
        }
      }),
    );
  }
}

class ScoreTable extends StatelessWidget {
  final List<Score> scores;
  const ScoreTable({required this.scores});

  @override
  Widget build(BuildContext context) {
    // Group the scores by quizTitle
    Map<String, List<Score>> groupedScores = {};

    for (var score in scores) {
      if (groupedScores.containsKey(score.quizTitle)) {
        groupedScores[score.quizTitle]!.add(score);
      } else {
        groupedScores[score.quizTitle] = [score];
      }
    }

    // Prepare data for DataTable rows
    List<DataRow> rows = [];
    groupedScores.forEach((quizTitle, scoreList) {
      rows.add(const DataRow(cells: [
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
      ]));
      // Add a header row for each quiz
      rows.add(DataRow(cells: [
        DataCell(Text(quizTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(Text('')),
        const DataCell(Text('')),
      ]));

      // Add score rows for each user in the quiz group
      for (var score in scoreList) {
        rows.add(DataRow(cells: [
          DataCell(Text(score.userName)),
          const DataCell(Text('')),
          DataCell(Text(score.score.toString())),
        ]));
      }
    });

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        sortColumnIndex: 2,
        sortAscending: true,
        columns: const [
          DataColumn(label: Text('')),
          DataColumn(label: Text('')),
          DataColumn(label: Text('Score')),
        ],
        rows: rows,
      ),
    );
  }
}

class TeacherScoreController extends GetxController {
  var scores = <Score>[].obs;

  @override
  void onInit() async {
    super.onInit();
    fetchScores();
  }

  Future<void> fetchScores() async {
    try {
      final response = await Supabase.instance.client.from('scores').select('score, user(first_name, last_name), quiz(quiz_title)');

      print(response);

      final List<dynamic> data = response as List<dynamic>;

      scores.value = data.map((e) => Score.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching scores: $e');
    }
  }
}

class Score {
  final String userName;
  final String quizTitle;
  final int score;

  Score({
    required this.userName,
    required this.quizTitle,
    required this.score,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    final firstName = json['user']['first_name'] ?? 'No First Name';
    final lastName = json['user']['last_name'] ?? 'No Last Name';

    return Score(
      userName: '$firstName $lastName', // Concatenate first and last name
      quizTitle: json['quiz']['quiz_title'] ?? 'Unknown Quiz', // Accessing quiz title
      score: json['score'] ?? 0, // Accessing score
    );
  }
}
