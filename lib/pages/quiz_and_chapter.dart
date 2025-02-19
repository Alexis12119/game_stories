// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:game_stories/controllers/page_viewer_controller.dart';
import 'package:game_stories/controllers/quiz_controller.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'package:game_stories/pages/quiz_viewer.dart';
import 'package:game_stories/pages/video_player.dart';
import 'package:get/get.dart';

class QuizAndChapter extends StatelessWidget {
  final int storyID;
  const QuizAndChapter({
    super.key,
    required this.storyID,
  });

  @override
  Widget build(BuildContext context) {
    SupaBaseController supaBaseController = Get.put(SupaBaseController());
    PageViewerController pageViewerController = Get.put(PageViewerController());
    QuizController quizController = Get.put(QuizController());

    // Trigger fetching the data
    supaBaseController.fetchChaptersAndQuizzesLocal(storyId: storyID);

    return Obx(() {
      // Check if data is loading
      if (supaBaseController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      // Check if data is empty
      if (supaBaseController.chaptersAndQuizzes.isEmpty) {
        return const Center(
          child: Text('No chapters or quizzes available.'),
        );
      }

      // Display the list when data is available
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          GetBuilder<SupaBaseController>(
            id: supaBaseController.chaptersAndQuizzesId,
            builder: (controller) {
              return ListView.builder(
                itemCount: controller.chaptersAndQuizzes.length,
                itemBuilder: (context, index) {
                  final chapterData = controller.chaptersAndQuizzes[index];
                  final chapter = chapterData['chapter'];
                  final quizzes = chapterData['quizzes'];
                  final isLocked = chapterData['isLocked'];

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(30.0, 8, 30, 8),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Story title (chapter)
                            Expanded(
                              flex: 7,
                              child: InkWell(
                                onTap: () {
                                  // print(quizController.currentQuestion.toString());
                                  if (!isLocked) {
                                    print('Is locked for chapter ID: $isLocked ');
                                    pageViewerController.getValuesByChapter(chapter['id'].toString());
                                    Get.to(VideoPlayerComponent(video: chapter['video']));
                                  }

                                  // Get.to(() => StoryViewer(
                                  //       story: pageViewerController.chosenStory,
                                  //       pageSelected: pageViewerController.pageSelected,
                                  //       nextPage: () => pageViewerController.nextPage(),
                                  //       previousPage: () => pageViewerController.previousPage(),
                                  //     ));
                                  // print('Chapter ID: ${chapter['id']}');
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      chapter['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Visibility(visible: isLocked, child: const Icon(Icons.lock_rounded)),
                                  ],
                                ),
                              ),
                            ),
                            // Quiz title or a placeholder if no quiz
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () async {
                                  // controller.updateProgress(storyID, chapter['id']);
                                  if (!isLocked) {
                                    print('Is locked for quiz ID: $isLocked ');
                                    if (quizzes.isNotEmpty) {
                                      print('Quiz ID: ${quizzes[0]['id']}');

                                      // await controller.populateQuizSet(quizzes[0]['id']);
                                      await controller.populateQuizLocal(quizzes[0]['id']);

                                      print(controller.quizSet.toString());
                                      Get.to(() => QuizViewer(
                                            resetCurrentItemNumber: () => quizController.resetCurrentItemNumber(),
                                            questions: controller.quizSet,
                                            currentQuestionNumber: quizController.currentQuestionNumber,
                                            resetScore: () => quizController.resetScore(),
                                            quizID: quizzes[0]['id'],
                                            storyId: storyID,
                                          ));
                                    } else {
                                      print('No Quiz Available for Chapter ID: ${chapter['id']}');
                                    }
                                  }
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      quizzes.isNotEmpty ? quizzes[0]['quiz_title'] : 'No Quiz Available',
                                    ),
                                    Visibility(visible: isLocked, child: const Icon(Icons.lock_rounded))
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            top: 10.0,
            left: 10.0,
            child: IconButton(
              onPressed: () {
                Get.back();
                // print(supaBaseController.quizSet.toString());
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          )
        ],
      );
    });
  }
}
