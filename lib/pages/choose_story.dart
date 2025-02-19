// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:game_stories/const/colors.dart';
// import 'package:game_stories/controllers/choose_story_controller.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'package:game_stories/pages/quiz_and_chapter.dart';
import 'package:get/get.dart';

class ChooseStoryPage extends StatelessWidget {
  const ChooseStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ChooseStoryController chooseStoryController = Get.put(ChooseStoryController());
    SupaBaseController supaBaseController = Get.put(SupaBaseController());

    // final List<String> stories = chooseStoryController.stories;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Obx(
            () {
              // Make sure the data is available and not empty
              if (supaBaseController.storiesMap.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Build the list of stories from the map
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                itemCount: supaBaseController.storiesMap.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  var storyId = supaBaseController.storiesMap.keys.elementAt(index);
                  var cover = supaBaseController.storiesMap[storyId]?['cover'];

                  // var storyData = supaBaseController.storiesMap[storyId];

                  return Container(
                    margin: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () {
                        print('Clicked on story with id: $storyId');
                        Get.to(() => QuizAndChapter(storyID: storyId));
                      },
                      child: Image.asset(
                        cover,
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
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
    );
  }
}
