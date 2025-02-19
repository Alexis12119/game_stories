// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScoreController extends GetxController {
  var scores = <Score>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchScores();
  }

  Future<void> fetchScores() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client.from('scores').select('score, quiz (quiz_title)').eq('user', user.id);

        // Handle response data
        if (response != null) {
          final List<dynamic> data = response as List<dynamic>;
          scores.value = data.map((e) => Score.fromJson(e)).toList();
        } else {
          print('No data returned');
        }
      } catch (e) {
        // Handle any error that occurred during the query
        print('Error fetching scores: $e');
      }
    } else {
      print('User is not logged in.');
    }
  }
}

class Score {
  final String quizTitle;
  final int score;

  Score({required this.quizTitle, required this.score});

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      quizTitle: json['quiz'] != null ? json['quiz']['quiz_title'] ?? 'Unknown' : 'Unknown', // Handle nested 'quiz' map
      score: json['score'] ?? 0, // Handle the score field
    );
  }
}
