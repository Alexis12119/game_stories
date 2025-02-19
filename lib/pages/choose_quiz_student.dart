// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:game_stories/const/colors.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:game_stories/controllers/quiz_controller.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'package:game_stories/pages/edit_quiz.dart';
import 'package:game_stories/pages/quiz_viewer.dart';
import 'package:get/get.dart';

class ChooseQuiz extends StatelessWidget {
  const ChooseQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    SupaBaseController supaBaseController = Get.put(SupaBaseController());
    QuizController quizController = Get.put(QuizController());
    LoginController loginController = Get.put(LoginController());
    // supaBaseController.populateQuizSet(1);
    supaBaseController.fetchQuiz();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Obx(
            () {
              if (supaBaseController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (supaBaseController.quizzes.isEmpty) {
                return const Center(child: Text('No data found.'));
              }
              // return ListView.builder(
              //   itemCount: supaBaseController.quizzes.length,
              //   itemBuilder: (context, index) {
              //     final item = supaBaseController.quizzes[index];

              //     final int id = item.id;
              //     final String createdAt = item.createdAt.toIso8601String();
              //     final int storyTitle = item.storyTitle;

              //     return ListTile(
              //       title: Text('Story Title: $storyTitle'),
              //       subtitle: Text('Created At: $createdAt'),
              //       trailing: Text('ID: $id'),
              //     );
              //   },
              // );

              return Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 50, 8.0, 8.0),
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    // Add the extra item with the LPUS icon
                    Visibility(
                      visible: loginController.isUserTeacher.value,
                      child: InkWell(
                        onTap: () {
                          Get.to(const EditQuiz());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add Quiz',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Add the generated quiz items
                    ...List.generate(
                      supaBaseController.quizzes.length,
                      (index) {
                        return InkWell(
                          onTap: () async {
                            if (loginController.isUserTeacher.value) {
                              // Show confirmation dialog before deleting the quiz
                              bool? confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: const Text('Are you sure you want to delete this quiz?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false); // User cancels
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true); // User confirms
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmDelete == true) {
                                // Proceed with quiz deletion if confirmed
                                await supaBaseController.deleteQuiz(supaBaseController.quizzes[index].id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Quiz deleted successfully')),
                                );
                                Get.offAllNamed('/');
                              } else {
                                // Handle if the user cancels the deletion (optional)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Quiz deletion cancelled')),
                                );
                              }
                            } else {
                              // For non-teacher users, navigate to QuizViewer
                              await supaBaseController.populateQuizSet(supaBaseController.quizzes[index].id);

                              Get.to(
                                QuizViewer(
                                  quizID: supaBaseController.quizzes[index].id,
                                  resetCurrentItemNumber: () => quizController.resetCurrentItemNumber(),
                                  questions: supaBaseController.quizSet,
                                  currentQuestionNumber: quizController.currentQuestionNumber,
                                  resetScore: () => quizController.resetScore(),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              supaBaseController.quizzes[index].quizTitle,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 10.0,
            left: 10.0,
            child: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          )
        ],
      ),
    );
  }
}
