// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_stories/const/colors.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:game_stories/controllers/quiz_controller.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'package:game_stories/model/quiz_set.dart';
import 'package:game_stories/pages/score_view.dart';
import 'package:get/get.dart';

class QuizViewer extends StatelessWidget {
  final RxList<QuizSet> questions;
  final RxInt currentQuestionNumber;
  final Function resetCurrentItemNumber;
  final Function resetScore;
  final int? storyId;
  final int? quizID;

  const QuizViewer({
    super.key,
    required this.questions,
    required this.currentQuestionNumber,
    required this.resetCurrentItemNumber,
    required this.resetScore,
    this.quizID,
    this.storyId,
  });

  @override
  Widget build(BuildContext context) {
    resetScore.call();

    LoginController loginController = Get.put(LoginController());
    SupaBaseController supaBaseController = Get.put(SupaBaseController());

    loginController.checkUserLoggedIn();

    void updateQuizSetLocal() {
      supaBaseController.updateQuizSet(questions);
      print('Updated quiz set ${supaBaseController.quizSet.toString()}');
    }

    void updateSelectedAnswer(int currentIndex, int selctedAnswer) {
      questions[currentIndex].selectedAnswer = selctedAnswer;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Obx(() {
            return Quiz(
              quizID: quizID,
              storyId: storyId,
              question: questions[currentQuestionNumber.value],
              items: questions.length,
              updateQuizSet: updateQuizSetLocal,
              updateSelectedAnswer: updateSelectedAnswer,
            );
          }),
          IconButton(
            onPressed: () {
              Get.back();
              resetCurrentItemNumber.call();
            },
            icon: const Icon(Icons.keyboard_double_arrow_left_sharp),
          ),
        ],
      ),
    );
  }
}

class Quiz extends StatefulWidget {
  final Function updateQuizSet;
  final Function(int, int) updateSelectedAnswer;
  final QuizSet question;
  final int items;
  final int? quizID;
  final int? storyId;

  const Quiz({
    super.key,
    required this.question,
    required this.items,
    required this.updateQuizSet,
    required this.updateSelectedAnswer,
    this.quizID,
    this.storyId,
  });

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  Timer? _timer;
  double _timeLeft = 5;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timeLeft = 5; // Reset time to 5 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _timeLeft -= 0.1;
      });

      if (_timeLeft <= 0) {
        _timer?.cancel();
        _moveToNextQuestion();
      }
    });
  }

  void _moveToNextQuestion() {
    QuizController quizController = Get.find();
    SupaBaseController supaBaseController = Get.find();
    widget.question.selectedAnswer = null; // Set answer to null if time runs out

    if (quizController.currentQuestionNumber.value + 1 == widget.items) {
      Get.offAll(ScoreView(
        score: quizController.score.value,
        resetCurrentItemNumber: () {
          quizController.resetCurrentItemNumber();
        },
        quizSet: supaBaseController.quizSet,
      ));
    } else {
      quizController.currentQuestionNumber++;
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          flex: 1,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 10,
                color: Colors.grey[300], // Background for the progress bar
              ),
              FractionallySizedBox(
                widthFactor: _timeLeft / 5,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 10,
                  color: Colors.blue, // Progress bar color
                ),
              ),
            ],
          ),
        ),
        Flexible(
          flex: 4,
          child: Container(
            color: componentColor,
            child: Center(
              child: Text(
                widget.question.questionText,
                style: const TextStyle(
                  color: blackText,
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Flexible(
          flex: 5,
          child: Container(
            color: componentColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tileSize = constraints.maxHeight / 2;
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      childAspectRatio: constraints.maxWidth / (tileSize * 2),
                    ),
                    itemCount: widget.question.choices.length,
                    itemBuilder: (context, index) => AnswerTile(
                      quizID: widget.quizID,
                      storyId: widget.storyId,
                      question: widget.question,
                      index: index,
                      items: widget.items,
                      onAnswerSelected: _startTimer,
                      updateQuizSet: widget.updateQuizSet,
                      updateSelectedAnswer: widget.updateSelectedAnswer,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnswerTile extends StatelessWidget {
  final QuizSet question;
  final int index;
  final int items;
  final VoidCallback onAnswerSelected;
  final Function updateQuizSet;
  final Function(int, int) updateSelectedAnswer;
  final int? quizID;
  final int? storyId;

  const AnswerTile({
    super.key,
    required this.question,
    required this.index,
    required this.items,
    required this.onAnswerSelected,
    required this.updateQuizSet,
    required this.updateSelectedAnswer,
    this.quizID,
    this.storyId,
  });

  @override
  Widget build(BuildContext context) {
    QuizController quizController = Get.find();
    SupaBaseController supaBaseController = Get.find();

    return InkWell(
      onTap: () {
        question.selectedAnswer = index;

        updateSelectedAnswer.call(quizController.currentQuestionNumber.value, question.selectedAnswer);

        if (question.selectedAnswer == question.correctAnswerIndex) {
          quizController.score++;

          const snackBar = SnackBar(
            backgroundColor: Colors.green,
            content: Text('Correct'),
            duration: Duration(milliseconds: 500),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Wrong! The correct answer is ${question.choices[question.correctAnswerIndex]}',
            ),
            duration: const Duration(milliseconds: 500),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }

        if (quizController.currentQuestionNumber.value + 1 == items) {
          updateQuizSet.call();

          Get.offAll(
            ScoreView(
              quizId: quizID,
              storyId: storyId,
              score: quizController.score.value,
              resetCurrentItemNumber: () {
                quizController.resetCurrentItemNumber();
              },
              quizSet: supaBaseController.quizSet,
            ),
          );
        } else {
          quizController.currentQuestionNumber++;
        }

        onAnswerSelected();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5CD762),
          borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
        ),
        margin: const EdgeInsets.all(5),
        height: 50,
        child: Center(
          child: Text(question.choices[index],
              style: const TextStyle(
                color: blackText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
        ),
      ),
    );
  }
}
