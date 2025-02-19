// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'package:game_stories/model/quiz_set.dart';
import 'package:get/get.dart';

class ScoreView extends StatelessWidget {
  final int score;
  final Function resetCurrentItemNumber;
  final RxList<QuizSet> quizSet;
  final int? quizId;
  final int? storyId;

  const ScoreView({
    super.key,
    required this.score,
    required this.resetCurrentItemNumber,
    required this.quizSet,
    this.quizId,
    this.storyId,
  });

  @override
  Widget build(BuildContext context) {
    SupaBaseController supabase = Get.put(SupaBaseController());
    LoginController login = Get.find();

    return Scaffold(
      body: InkWell(
        onTap: () async {
          resetCurrentItemNumber.call();
          print('Quiz ID: $quizId');
          print('Story ID: $storyId');

          // Check if the user is null
          if (quizId == null || storyId == null) {
            Get.offAllNamed('/');
            return; // Exit the function if user is null
          } else if (storyId != null && quizId != null) {
            Get.offAllNamed('/');
            supabase.updateProgress(storyId!, quizId!);
            return; // Exit the function if storyId is null
          }

          try {
            await supabase.addScore(score, login.user!.id, quizId!);
          } catch (e) {
            _showErrorDialog(context, e.toString());
          }
        },
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Center(
            child: Column(
              children: [
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: quizSet.length,
                    itemBuilder: (context, index) {
                      return QuizItem(
                        quizSet: quizSet[index],
                        selectedAnswer: quizSet[index].selectedAnswer,
                        correctAnswerIndex: quizSet[index].correctAnswerIndex,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Get.offAllNamed('/');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class QuizItem extends StatelessWidget {
  final QuizSet quizSet;
  final int selectedAnswer;
  final int correctAnswerIndex;

  const QuizItem({
    super.key,
    required this.quizSet,
    required this.selectedAnswer,
    required this.correctAnswerIndex,
  });

  @override
  Widget build(BuildContext context) {
    String selectedAnswerValue = quizSet.choices[quizSet.selectedAnswer];
    String correctAnswerValue = quizSet.choices[quizSet.correctAnswerIndex];
    bool isCorrect = quizSet.selectedAnswer == quizSet.correctAnswerIndex;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Question: ${quizSet.questionText}',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Selected Answer: $selectedAnswerValue',
            style: const TextStyle(fontSize: 16),
          ),
          if (!isCorrect)
            Text(
              'Correct Answer: $correctAnswerValue',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
