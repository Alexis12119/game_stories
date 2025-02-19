// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:game_stories/controllers/quiz_controller.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'package:game_stories/pages/edit_quiz.dart';
import 'package:game_stories/pages/student_list_page.dart';
import 'package:game_stories/pages/quiz_viewer.dart';
import 'package:get/get.dart';

class ChooseQuiz extends StatelessWidget {
  const ChooseQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    SupaBaseController supaBaseController = Get.put(SupaBaseController());
    QuizController quizController = Get.put(QuizController());
    LoginController loginController = Get.put(LoginController());

    supaBaseController.fetchQuiz();

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // Deep navy blue
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () {
                    if (loginController.isUserTeacher.value) {
                      loginController.signOut();
                      Get.offAllNamed('/AdminLogin');
                    } else {
                      Get.offAllNamed('/');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Student Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  Get.to(() => const StudentListPage());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50), // Dark green
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Student Profile',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Create Quiz Button (Only for Teachers)
            if (loginController.isUserTeacher.value)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    Get.to(const EditQuiz());
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BC34A), // Light green
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Create Quiz',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // List of Available Quizzes (Changed to ListView)
            Expanded(
              child: Obx(
                () => supaBaseController.quizzes.isEmpty
                    ? const Center(
                        child: Text(
                          "No quizzes available",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                          itemCount: supaBaseController.quizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = supaBaseController.quizzes[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              color: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: Text(
                                  quiz.quizTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: loginController.isUserTeacher.value
                                    ? IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () async {
                                          // Show confirmation dialog before deleting
                                          bool? confirmDelete =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Confirm Deletion'),
                                                content: const Text(
                                                    'Are you sure you want to delete this quiz?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(false);
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(true);
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirmDelete == true) {
                                            // Delete quiz
                                              await supaBaseController
                                                  .deleteQuiz(quiz.id);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Quiz deleted successfully')),
                                              );
                                            Get.offAllNamed('/');
                                          }
                                        },
                                      )
                                    : null,
                                onTap: () async {
                                  if (!loginController.isUserTeacher.value) {
                                    // Student selects a quiz to view
                                    await supaBaseController
                                        .populateQuizSet(quiz.id);

                                    Get.to(
                                      QuizViewer(
                                        quizID: quiz.id,
                                        resetCurrentItemNumber: () =>
                                            quizController
                                                .resetCurrentItemNumber(),
                                        questions: supaBaseController.quizSet,
                                        currentQuestionNumber: quizController
                                            .currentQuestionNumber,
                                        resetScore: () =>
                                            quizController.resetScore(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
